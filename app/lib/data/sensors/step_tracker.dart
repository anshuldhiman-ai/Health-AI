import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:app/core/format/count_format.dart';
import 'package:app/data/local_storage.dart';
import 'package:app/domain/entities/activity_snapshot.dart';
import 'package:app/domain/services/activity_ledger.dart';
import 'package:app/domain/services/local_date.dart';

/// Sensor step tracking: the phone's built-in step counter
/// (TYPE_STEP_COUNTER on Android, CMPedometer on iOS). Read-only —
/// no network, no account.
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

final stepTrackerProvider = StreamProvider<StepSnapshot>((ref) async* {
  final store = ref.watch(activityStoreProvider);
  final ledger = await store.load(DateTime.now());
  yield ledger.snapshot(StepStatus.live, DateTime.now());

  if (!Platform.isAndroid && !Platform.isIOS) {
    yield ledger.snapshot(StepStatus.unsupported, DateTime.now());
    return;
  }

  if (Platform.isAndroid) {
    try {
      final status = await Permission.activityRecognition.status;
      if (!status.isGranted) {
        final requestStatus = await Permission.activityRecognition.request();
        if (!requestStatus.isGranted) {
          yield ledger.snapshot(StepStatus.permissionDenied, DateTime.now());
          return;
        }
      }
    } catch (_) {
      yield ledger.snapshot(StepStatus.unavailable, DateTime.now());
      return;
    }
  }

  var saving = false;
  var saveAgain = false;
  Future<void> save() async {
    if (saving) {
      saveAgain = true;
      return;
    }
    saving = true;
    do {
      saveAgain = false;
      await store.save(ledger);
    } while (saveAgain);
    saving = false;
  }

  var lastSave = DateTime.now().subtract(const Duration(minutes: 1));
  try {
    await for (final event in Pedometer.stepCountStream) {
      final at = event.timeStamp;
      ledger.record(sensorSteps: event.steps, at: at);
      final now = DateTime.now();
      yield ledger.snapshot(StepStatus.live, now);
      if (now.difference(lastSave) >= const Duration(seconds: 15)) {
        lastSave = now;
        unawaited(save());
      }
    }
  } on MissingPluginException {
    yield ledger.snapshot(
      ledger.steps > 0 ? StepStatus.live : StepStatus.unavailable,
      DateTime.now(),
    );
  } on PlatformException {
    yield ledger.snapshot(
      ledger.steps > 0 ? StepStatus.live : StepStatus.unavailable,
      DateTime.now(),
    );
  } catch (_) {
    yield ledger.snapshot(
      ledger.steps > 0 ? StepStatus.live : StepStatus.unavailable,
      DateTime.now(),
    );
  }
});

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
  final ledger = await store.load(DateTime.now());
  ledger.addManualSteps(delta);
  await store.save(ledger);
  ref.invalidate(stepTrackerProvider);
}

Future<void> setTodaySteps(WidgetRef ref, int steps) async {
  final store = ref.read(activityStoreProvider);
  final ledger = await store.load(DateTime.now());
  ledger.setStepsForToday(steps);
  await store.save(ledger);
  ref.invalidate(stepTrackerProvider);
}

Future<void> clearTodaySteps(WidgetRef ref) async {
  final store = ref.read(activityStoreProvider);
  final ledger = await store.load(DateTime.now());
  ledger.clearTodaySteps();
  await store.save(ledger);
  ref.invalidate(stepTrackerProvider);
}
