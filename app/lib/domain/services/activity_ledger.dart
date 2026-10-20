/// Pure step-sensor ledger: turn cumulative sensor readings into today's
/// steps, distance, active time and walking cadence.
///
/// Kept in domain so the math is unit-testable without Android or
/// secure storage. The data layer owns persistence and the sensor
/// stream; the UI never recomputes these numbers.
library;

import 'dart:math' as math;

import 'package:app/domain/entities/activity_snapshot.dart';
import 'package:app/domain/services/local_date.dart';

class ActivityLedger {
  ActivityLedger({
    required this.date,
    this.steps = 0,
    this.activeSeconds = 0,
    this.activeSteps = 0,
    this.cadenceSpm = 0,
    List<int>? hourlySteps,
    Map<String, int>? history,
    this.lastEventAt,
    this.lastSensor,
  }) : _hourlySteps = _normaliseHourly(hourlySteps),
       _history = {...?history} {
    _history[date] = steps;
    _pruneHistory(localDay(lastEventAt ?? DateTime.now()));
  }

  factory ActivityLedger.empty(DateTime now) =>
      ActivityLedger(date: localDateKey(now));

  factory ActivityLedger.fromJson(Map<String, dynamic> json) {
    final history = <String, int>{};
    final rawHistory = json['history'];
    if (rawHistory is Map) {
      for (final entry in rawHistory.entries) {
        final value = entry.value;
        if (entry.key is String && value is num) {
          history[entry.key as String] = value.toInt();
        }
      }
    }
    final rawHourly = json['hourly'];
    final hourly = rawHourly is List
        ? [
            for (final value in rawHourly)
              if (value is num) value.toInt() else 0,
          ]
        : null;
    final rawLast = json['lastEventAt'];
    final rawDate = json['date'];
    return ActivityLedger(
      date: rawDate is String && rawDate.isNotEmpty
          ? rawDate
          : localDateKey(DateTime.now()),
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      activeSeconds: (json['activeSeconds'] as num?)?.toInt() ?? 0,
      activeSteps: (json['activeSteps'] as num?)?.toInt() ?? 0,
      cadenceSpm: (json['cadenceSpm'] as num?)?.toDouble() ?? 0,
      hourlySteps: hourly,
      history: history,
      lastEventAt: rawLast is num
          ? DateTime.fromMillisecondsSinceEpoch(rawLast.toInt())
          : null,
      lastSensor: (json['lastSensor'] as num?)?.toInt(),
    );
  }

  String date;
  int steps;
  int activeSeconds;
  int activeSteps;
  double cadenceSpm;
  List<int> _hourlySteps;
  final Map<String, int> _history;
  DateTime? lastEventAt;
  int? lastSensor;
  int? _legacyAnchor;

  List<int> get hourlySteps => List.unmodifiable(_hourlySteps);
  Map<String, int> get history => Map.unmodifiable(_history);

  /// The pre-ledger secure-storage baseline can be adopted once, so an
  /// app update does not throw away today's already-counted steps.
  set legacyAnchor(int sensorValue) => _legacyAnchor = sensorValue;

  /// Reset for a new local day while keeping the previous day's total.
  /// Called on load and on the first step after midnight.
  // ignore: use_setters_to_change_properties
  void syncTo(DateTime now) => _ensureDate(now);

  /// Record one cumulative sensor reading. [at] is the event timestamp
  /// when the platform supplies one, otherwise the receive time.
  void record({required int sensorSteps, required DateTime at}) {
    _ensureDate(at);
    if (sensorSteps < 0) return;

    final previousSensor = lastSensor;
    if (previousSensor == null) {
      final anchor = _legacyAnchor;
      if (anchor != null && sensorSteps >= anchor) {
        steps = math.max(0, sensorSteps - anchor);
      }
      lastSensor = sensorSteps;
      lastEventAt = at;
      _legacyAnchor = null;
      _history[date] = steps;
      return;
    }

    // Sensor reset (reboot, OEM counter reset): re-anchor without losing
    // the steps accumulated earlier today.
    if (sensorSteps < previousSensor) {
      lastSensor = sensorSteps;
      lastEventAt = at;
      _history[date] = steps;
      return;
    }

    final delta = sensorSteps - previousSensor;
    if (delta <= 0) {
      lastSensor = sensorSteps;
      _history[date] = steps;
      return;
    }

    steps += delta;
    _hourlySteps[at.hour] += delta;
    _accumulateMovement(delta: delta, at: at);
    lastSensor = sensorSteps;
    lastEventAt = at;
    _history[date] = steps;
    if (activeSeconds > 86400) activeSeconds = 86400;
  }

  StepSnapshot snapshot(StepStatus status, DateTime now) {
    _ensureDate(now);
    final today = localDay(now);
    final days = [
      for (var i = 6; i >= 0; i--)
        () {
          final day = today.subtract(Duration(days: i));
          return DaySteps(
            date: day,
            steps: i == 0 ? steps : (_history[localDateKey(day)] ?? 0),
          );
        }(),
    ];
    final average = activeSeconds > 0
        ? (activeSteps * 60 / activeSeconds).round()
        : 0;
    return StepSnapshot(
      status: status,
      steps: steps,
      distanceMeters: steps * kAverageStrideMeters,
      activeSeconds: activeSeconds,
      cadenceSpm: cadenceSpm,
      averageCadenceSpm: average,
      hourlySteps: List.unmodifiable(_hourlySteps),
      history: days,
      updatedAt: lastEventAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'steps': steps,
    'activeSeconds': activeSeconds,
    'activeSteps': activeSteps,
    'cadenceSpm': cadenceSpm,
    'hourly': _hourlySteps,
    'history': _history,
    'lastEventAt': lastEventAt?.millisecondsSinceEpoch,
    'lastSensor': lastSensor,
  };

  void _accumulateMovement({required int delta, required DateTime at}) {
    final previous = lastEventAt;
    if (previous == null) return;
    final elapsedMs = at.difference(previous).inMilliseconds;
    if (elapsedMs <= 0 || elapsedMs > 180000) return;

    final minutes = elapsedMs / 60000;
    final instantCadence = delta / minutes;
    if (instantCadence >= 25 && instantCadence <= 260) {
      cadenceSpm = cadenceSpm == 0
          ? instantCadence
          : (cadenceSpm * 0.65) + (instantCadence * 0.35);
    }

    // Only plausible walking intervals count as active time. This avoids
    // turning a long gap between batched events into "exercise".
    if (elapsedMs >= 500 && instantCadence >= 30 && instantCadence <= 260) {
      final seconds = math.min(120, (elapsedMs / 1000).round());
      activeSeconds += seconds;
      activeSteps += delta;
    }
  }

  void _ensureDate(DateTime now) {
    final key = localDateKey(now);
    if (key == date) return;
    if (steps > 0) _history[date] = steps;
    date = key;
    steps = 0;
    activeSeconds = 0;
    activeSteps = 0;
    cadenceSpm = 0;
    _hourlySteps = List<int>.filled(24, 0);
    lastEventAt = null;
    lastSensor = null;
    _legacyAnchor = null;
    _history[key] = 0;
    _pruneHistory(localDay(now));
  }

  void _pruneHistory(DateTime today) {
    final oldest = today.subtract(const Duration(days: 6));
    _history.removeWhere((key, _) {
      final parsed = DateTime.tryParse(key);
      if (parsed == null) return true;
      return parsed.isBefore(oldest) || parsed.isAfter(today);
    });
  }

  static List<int> _normaliseHourly(List<int>? source) {
    if (source == null || source.length != 24) return List<int>.filled(24, 0);
    return [for (final value in source) math.max(0, value)];
  }
}
