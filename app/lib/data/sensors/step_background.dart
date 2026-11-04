import 'dart:io';

import 'package:flutter/services.dart';

import 'package:app/domain/entities/activity_snapshot.dart';

/// Bridge to the Kotlin step-capture worker.
///
/// The hardware step counter keeps counting while the app is dead, but a
/// Dart sensor listener cannot run then. A WorkManager job samples the
/// cumulative counter roughly every 15 minutes and stores timestamped
/// readings in app-private storage; this class drains them when the app
/// is next alive. Nothing leaves the device.
///
/// Limits that cannot be worked around by any Android app:
/// - a user "Force stop" from Settings halts background work until the
///   next manual launch;
/// - Doze / OEM battery managers can defer a 15-minute job to a
///   maintenance window, so a gap can be hours long. Gaps are split
///   proportionally and flagged as reconciled in the ledger.
class StepBackgroundCollector {
  const StepBackgroundCollector();

  static const MethodChannel _channel = MethodChannel(
    'health_ai/steps_background',
  );

  bool get isSupported => Platform.isAndroid;

  /// Register the periodic capture job. Safe to call on every launch:
  /// the native side keeps a single unique work request.
  Future<void> schedule() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('schedule');
    } catch (_) {
      // Missing handler (tests, desktop) or a plugin failure: the live
      // sensor path still works, so this is not fatal.
    }
  }

  /// All retained background readings, oldest first. Readings are not
  /// cleared on the native side; the ledger's cursor discards duplicates,
  /// which also survives the app being killed mid-drain.
  Future<List<StepReading>> drain() async {
    if (!isSupported) return const [];
    try {
      final raw = await _channel.invokeListMethod<dynamic>('drain');
      return _parse(raw);
    } catch (_) {
      return const [];
    }
  }

  /// Take a reading now and return the full retained set. Used once the
  /// activity permission is granted so a launch does not wait for the
  /// first step event to know the current counter value.
  Future<List<StepReading>> collectNow() async {
    if (!isSupported) return const [];
    try {
      final raw = await _channel
          .invokeListMethod<dynamic>('collectNow')
          .timeout(const Duration(seconds: 6));
      return _parse(raw);
    } catch (_) {
      return const [];
    }
  }

  static List<StepReading> _parse(List<dynamic>? raw) {
    if (raw == null) return const [];
    final readings = <StepReading>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final at = item['t'];
      final steps = item['s'];
      if (at is! num || steps is! num) continue;
      readings.add(
        StepReading(
          at: DateTime.fromMillisecondsSinceEpoch(at.toInt()),
          sensorSteps: steps.toInt(),
          elapsedMillis: (item['e'] as num?)?.toInt(),
        ),
      );
    }
    readings.sort((a, b) => a.at.compareTo(b.at));
    return readings;
  }
}
