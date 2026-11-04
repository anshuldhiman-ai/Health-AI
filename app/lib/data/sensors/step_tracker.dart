import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:app/core/format/count_format.dart';
import 'package:app/data/local_storage.dart';
import 'package:app/data/sensors/step_background.dart';
import 'package:app/domain/entities/activity_snapshot.dart';
import 'package:app/domain/services/activity_ledger.dart';
import 'package:app/domain/services/local_date.dart';

/// Sensor step tracking: the phone's built-in step counter
/// (TYPE_STEP_COUNTER on Android, CMPedometer on iOS). Read-only —
/// no network, no account.
///
/// Two sources feed one ledger:
/// - the live stream while the app is alive (per-step, exact timestamps);
/// - timestamped background samples captured by the Kotlin WorkManager
///   job while the app was closed (about every 15 minutes).
///
/// The ledger keeps today's steps separately from the cumulative sensor
/// reading, so a reboot or an OEM counter reset does not erase movement.
/// Active time/cadence are derived from event timestamps; they are
/// estimates, not a fitness-lab measurement.
const _kActivityKey = 'steps.activity.v2';
const _kLegacyDateKey = 'steps.baseline.date';
const _kLegacyBaseKey = 'steps.baseline.value';

class ActivityStore {
  const ActivityStore();

  Future<ActivityLedger> load(DateTime now) async {
    ActivityLedger? ledger;
    try {
      final raw = await AppLocalStorage.readString(_kActivityKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          ledger = ActivityLedger.fromJson(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (_) {
      // Keep the session usable if the store is temporarily locked.
    }

    ledger ??= ActivityLedger.empty(now);
    if (ledger.lastSensor == null) {
      try {
        final oldDate = await AppLocalStorage.readString(_kLegacyDateKey);
        final oldBase = int.tryParse(
          await AppLocalStorage.readString(_kLegacyBaseKey) ?? '',
        );
        if (oldDate == localDateKey(now) && oldBase != null) {
          ledger.legacyAnchor = oldBase;
        }
      } catch (_) {
        // Migration is best-effort.
      }
    }
    ledger.syncTo(now);
    return ledger;
  }

  Future<void> save(ActivityLedger ledger) async {
    try {
      await AppLocalStorage.writeString(
        _kActivityKey,
        jsonEncode(ledger.toJson()),
      );
    } catch (_) {
      // The in-memory ledger continues; the next event retries.
    }
  }
}

final activityStoreProvider = Provider<ActivityStore>(
  (ref) => const ActivityStore(),
);

final stepBackgroundCollectorProvider = Provider<StepBackgroundCollector>(
  (ref) => const StepBackgroundCollector(),
);

final stepTrackerProvider = StreamProvider<StepSnapshot>((ref) {
  final session = _StepTrackerSession();
  ref.onDispose(session.dispose);
  unawaited(session.start());
  return session.stream;
});

/// One live tracking session: owns the ledger while the provider is
/// mounted, merges background readings, and publishes snapshots.
class _StepTrackerSession {
  final _controller = StreamController<StepSnapshot>();
  final _store = const ActivityStore();
  final _collector = const StepBackgroundCollector();

  ActivityLedger? _ledger;
  StreamSubscription<StepCount>? _pedometer;
  Timer? _poll;
  bool _saving = false;
  bool _saveAgain = false;
  bool _disposed = false;
  DateTime _lastSave = DateTime.now().subtract(const Duration(minutes: 1));

  Stream<StepSnapshot> get stream => _controller.stream;

  Future<void> start() async {
    try {
      final now = DateTime.now();
      final ledger = await _store.load(now);
      _ledger = ledger;
      if (_disposed) return;

      // Background samples captured while this process was dead are the
      // first thing folded in: they carry the hours the live stream missed.
      await _mergeBackground(ledger);
      if (_disposed) return;
      _emit(StepStatus.live);

      // Register the periodic capture job on every launch. The worker is a
      // no-op until the activity permission is granted.
      unawaited(_collector.schedule());

      if (!Platform.isAndroid && !Platform.isIOS) {
        _emit(StepStatus.unsupported);
        return;
      }

      if (Platform.isAndroid) {
        try {
          final status = await Permission.activityRecognition.status;
          if (!status.isGranted) {
            final requestStatus = await Permission.activityRecognition
                .request();
            if (!requestStatus.isGranted) {
              _emit(StepStatus.permissionDenied);
              return;
            }
          }
        } catch (_) {
          _emit(StepStatus.unavailable);
          return;
        }
      }

      // Capture an instantaneous reading so a launch does not have to wait
      // for the first step event before the backlog is settled.
      await _mergeBackground(ledger, collectNow: true);
      if (_disposed) return;

      _pedometer = Pedometer.stepCountStream.listen(
        (event) => _onStep(event, ledger),
        onError: (Object _) => _emit(_fallbackStatus(ledger)),
        cancelOnError: false,
      );

      // While the app is alive the worker may still deliver samples (for
      // example after a long background pause). Fold them in periodically.
      _poll = Timer.periodic(
        const Duration(seconds: 30),
        (_) => unawaited(_mergeBackground(ledger)),
      );
    } catch (_) {
      if (!_disposed) _emit(StepStatus.unavailable);
    }
  }

  void _onStep(StepCount event, ActivityLedger ledger) {
    ledger.record(sensorSteps: event.steps, at: event.timeStamp);
    _emit(StepStatus.live);
    final now = DateTime.now();
    if (now.difference(_lastSave) >= const Duration(seconds: 15)) {
      _lastSave = now;
      unawaited(_save(ledger));
    }
  }

  Future<void> _mergeBackground(
    ActivityLedger ledger, {
    bool collectNow = false,
  }) async {
    final readings = collectNow
        ? await _collector.collectNow()
        : await _collector.drain();
    if (_disposed || readings.isEmpty) return;
    for (final reading in readings) {
      ledger.record(
        sensorSteps: reading.sensorSteps,
        at: reading.at,
        elapsedMillis: reading.elapsedMillis,
      );
    }
    await _save(ledger);
    if (!_disposed) _emit(StepStatus.live);
  }

  StepStatus _fallbackStatus(ActivityLedger ledger) =>
      ledger.steps > 0 ? StepStatus.live : StepStatus.unavailable;

  void _emit(StepStatus status) {
    if (_disposed) return;
    final ledger = _ledger;
    if (ledger == null) return;
    _controller.add(ledger.snapshot(status, DateTime.now()));
  }

  Future<void> _save(ActivityLedger ledger) async {
    if (_disposed) return;
    if (_saving) {
      _saveAgain = true;
      return;
    }
    _saving = true;
    do {
      _saveAgain = false;
      await _store.save(ledger);
    } while (_saveAgain && !_disposed);
    _saving = false;
  }

  void dispose() {
    _disposed = true;
    _poll?.cancel();
    unawaited(_pedometer?.cancel());
    unawaited(_controller.close());
  }
}

/// Ask Android for activity-recognition access. Returns true when the
/// sensor can now be started. iOS handles motion permission itself.
Future<bool> requestStepPermission() async {
  if (!Platform.isAndroid) return true;
  try {
    var status = await Permission.activityRecognition.status;
    if (!status.isGranted) {
      status = await Permission.activityRecognition.request();
    }
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    return status.isGranted;
  } catch (_) {
    return false;
  }
}

/// Open this app's system settings, used after a permanent denial.
Future<bool> openStepPermissionSettings() => openAppSettings();

/// "6,320" style grouping.
String formatStepCount(int steps) => formatCount(steps);

const stepGoalPrefsKey = 'steps.goal.v1';

class StepGoalController extends Notifier<int> {
  @override
  int build() {
    _load();
    return 10000;
  }

  Future<void> _load() async {
    final raw = await AppLocalStorage.readString(stepGoalPrefsKey);
    final val = int.tryParse(raw ?? '');
    if (val != null && val > 0) {
      state = val;
    }
  }

  Future<void> setGoal(int goal) async {
    state = goal.clamp(1000, 50000);
    await AppLocalStorage.writeString(stepGoalPrefsKey, state.toString());
  }
}

final stepGoalProvider = NotifierProvider<StepGoalController, int>(
  StepGoalController.new,
);

/// Label for the Today tile: real count, or an em dash when the sensor
/// or permission is unavailable (never a fake number).
String stepTileLabel(AsyncValue<StepSnapshot> value) {
  final snapshot = value.valueOrNull;
  if (snapshot == null) return '0';
  return formatStepCount(snapshot.steps);
}

Future<void> addManualSteps(WidgetRef ref, int delta) async {
  final store = ref.read(activityStoreProvider);
  final now = DateTime.now();
  final ledger = await store.load(now);
  ledger.addManualSteps(delta, at: now);
  await store.save(ledger);
  ref.invalidate(stepTrackerProvider);
}

Future<void> setTodaySteps(WidgetRef ref, int steps) async {
  final store = ref.read(activityStoreProvider);
  final now = DateTime.now();
  final ledger = await store.load(now);
  ledger.setStepsForToday(steps, at: now);
  await store.save(ledger);
  ref.invalidate(stepTrackerProvider);
}

Future<void> clearTodaySteps(WidgetRef ref) async {
  final store = ref.read(activityStoreProvider);
  final now = DateTime.now();
  final ledger = await store.load(now);
  ledger.clearTodaySteps(at: now);
  await store.save(ledger);
  ref.invalidate(stepTrackerProvider);
}
