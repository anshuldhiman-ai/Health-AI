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

/// What the ledger remembers about one past local day. Steps, active time
/// and the hourly buckets are all measured while the day was being
/// tracked; a day the app never saw stays absent rather than estimated.
class _DayTotals {
  _DayTotals({this.steps = 0, this.activeSeconds = 0, List<int>? hourly})
    : hourly = hourly ?? List<int>.filled(24, 0);

  int steps;
  int activeSeconds;

  /// Steps per clock hour. While the day is live this is the same list the
  /// ledger is writing into, so the history entry tracks the buckets as
  /// they fill; the reference is swapped at midnight, which freezes the
  /// finished day without a copy.
  List<int> hourly;

  Map<String, dynamic> toJson() => {
    'steps': steps,
    'active': activeSeconds,
    'hourly': hourly,
  };
}

class ActivityLedger {
  ActivityLedger({
    required this.date,
    this.steps = 0,
    this.activeSeconds = 0,
    this.activeSteps = 0,
    this.cadenceSpm = 0,
    List<int>? hourlySteps,
    Map<String, _DayTotals>? history,
    this.lastEventAt,
    this.lastSensor,
  }) : _hourlySteps = _normaliseHourly(hourlySteps),
       _history = {...?history} {
    _syncHistoryEntry();
    // Prune against the ledger's own last active day so the class stays
    // pure Dart (R9). An unparseable date keeps every entry; the next
    // syncTo() from the data layer prunes against a real day.
    final anchor = DateTime.tryParse(date);
    if (anchor != null) _pruneHistory(localDay(anchor));
  }

  factory ActivityLedger.empty(DateTime now) =>
      ActivityLedger(date: localDateKey(now));

  factory ActivityLedger.fromJson(Map<String, dynamic> json) {
    final history = <String, _DayTotals>{};
    final rawHistory = json['history'];
    if (rawHistory is Map) {
      for (final entry in rawHistory.entries) {
        final key = entry.key;
        if (key is! String) continue;
        final value = entry.value;
        if (value is num) {
          // Payload written before active time was recorded: steps only.
          history[key] = _DayTotals(steps: value.toInt());
        } else if (value is Map) {
          final rawHourly = value['hourly'];
          history[key] = _DayTotals(
            steps: (value['steps'] as num?)?.toInt() ?? 0,
            activeSeconds: (value['active'] as num?)?.toInt() ?? 0,
            hourly: rawHourly is List && rawHourly.length == 24
                ? [
                    for (final hour in rawHourly)
                      if (hour is num) math.max(0, hour.toInt()) else 0,
                  ]
                : null,
          );
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
      // A payload without a usable date has no day to attribute to; the
      // first syncTo() after load adopts the caller's real day.
      date: rawDate is String && rawDate.isNotEmpty ? rawDate : '',
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
  final Map<String, _DayTotals> _history;
  DateTime? lastEventAt;
  int? lastSensor;
  int? _legacyAnchor;

  List<int> get hourlySteps => List.unmodifiable(_hourlySteps);

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
      _syncHistoryEntry();
      return;
    }

    // Sensor reset (reboot, OEM counter reset): re-anchor without losing
    // the steps accumulated earlier today.
    if (sensorSteps < previousSensor) {
      lastSensor = sensorSteps;
      lastEventAt = at;
      _syncHistoryEntry();
      return;
    }

    final delta = sensorSteps - previousSensor;
    if (delta <= 0) {
      lastSensor = sensorSteps;
      _syncHistoryEntry();
      return;
    }

    steps += delta;
    _hourlySteps[at.hour] += delta;
    _accumulateMovement(delta: delta, at: at);
    lastSensor = sensorSteps;
    lastEventAt = at;
    _syncHistoryEntry();
    if (activeSeconds > 86400) activeSeconds = 86400;
  }

  /// Manually add steps to today (e.g. treadmill, walking without phone, or manual log).
  void addManualSteps(int count, {required DateTime at}) {
    final now = at;
    _ensureDate(now);
    if (count <= 0) return;
    steps += count;
    _hourlySteps[now.hour] += count;
    final additionalSeconds = (count / 100 * 60).round();
    activeSeconds = math.min(86400, activeSeconds + additionalSeconds);
    activeSteps += count;
    _syncHistoryEntry();
    lastEventAt = now;
  }

  /// Set the exact step count for today.
  void setStepsForToday(int newSteps, {required DateTime at}) {
    final now = at;
    _ensureDate(now);
    if (newSteps < 0) return;
    final diff = newSteps - steps;
    steps = newSteps;
    if (diff > 0) {
      _hourlySteps[now.hour] += diff;
      final additionalSeconds = (diff / 100 * 60).round();
      activeSeconds = math.min(86400, activeSeconds + additionalSeconds);
      activeSteps += diff;
    } else if (diff < 0) {
      _hourlySteps[now.hour] = math.max(0, _hourlySteps[now.hour] + diff);
    }
    _syncHistoryEntry();
    lastEventAt = now;
  }

  /// Reset/clear today's step count.
  void clearTodaySteps({required DateTime at}) {
    final now = at;
    _ensureDate(now);
    steps = 0;
    activeSeconds = 0;
    activeSteps = 0;
    _hourlySteps = List<int>.filled(24, 0);
    _syncHistoryEntry();
    lastEventAt = now;
  }

  StepSnapshot snapshot(StepStatus status, DateTime now) {
    _ensureDate(now);
    final today = localDay(now);
    final days = [
      for (var i = 6; i >= 0; i--)
        () {
          final day = today.subtract(Duration(days: i));
          // Today comes from the live counters; earlier days come from
          // what was actually recorded on them. A day the app never ran
          // has no entry and reads as zero, which is honest.
          final recorded = _history[localDateKey(day)];
          return DaySteps(
            date: day,
            steps: i == 0 ? steps : (recorded?.steps ?? 0),
            activeSeconds: i == 0
                ? activeSeconds
                : (recorded?.activeSeconds ?? 0),
            // Today's buckets are still filling; an earlier day replays the
            // hours it was actually tracked in, so the chart is real on any
            // day the user taps.
            hourlySteps: List<int>.unmodifiable(
              i == 0 ? _hourlySteps : (recorded?.hourly ?? const <int>[]),
            ),
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
    'history': {
      for (final entry in _history.entries) entry.key: entry.value.toJson(),
    },
    'lastEventAt': lastEventAt?.millisecondsSinceEpoch,
    'lastSensor': lastSensor,
  };

  /// Mirror today's running totals into the seven-day history map. Every
  /// mutation goes through here so steps and active time can never drift
  /// apart in the strip.
  void _syncHistoryEntry() {
    _history[date] = _DayTotals(
      steps: steps,
      activeSeconds: activeSeconds,
      hourly: _hourlySteps,
    );
  }

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
    // Bank the day we are leaving, hourly buckets included. The new day
    // gets a fresh list, so the finished day keeps exactly the hours it
    // was observed in.
    if (steps > 0 || activeSeconds > 0) {
      _history[date] = _DayTotals(
        steps: steps,
        activeSeconds: activeSeconds,
        hourly: _hourlySteps,
      );
    }
    date = key;
    steps = 0;
    activeSeconds = 0;
    activeSteps = 0;
    cadenceSpm = 0;
    _hourlySteps = List<int>.filled(24, 0);
    lastEventAt = null;
    // Dropping the sensor anchor makes the first reading of the new day
    // an anchor rather than a delta. Steps taken while the app was closed
    // cannot be attributed to a day we did not observe, and crediting the
    // whole backlog to today would inflate it.
    lastSensor = null;
    _legacyAnchor = null;
    _history[key] = _DayTotals();
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
