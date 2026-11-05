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
  _DayTotals({
    this.steps = 0,
    this.activeSeconds = 0,
    this.reconciledSteps = 0,
    List<int>? hourly,
    this.dayStartSensor,
    this.lastSensor,
  }) : hourly = hourly ?? List<int>.filled(24, 0);

  int steps;
  int activeSeconds;
  int reconciledSteps;
  List<int> hourly;
  int? dayStartSensor;
  int? lastSensor;

  Map<String, dynamic> toJson() => {
    'steps': steps,
    'active': activeSeconds,
    'reconciled': reconciledSteps,
    'hourly': hourly,
    if (dayStartSensor != null) 'dayStartSensor': dayStartSensor,
    if (lastSensor != null) 'lastSensor': lastSensor,
  };
}

/// One measured interval share: the steps in a clock hour of a local day.
class _HourSlice {
  const _HourSlice(this.dateKey, this.hour, this.milliseconds);

  final String dateKey;
  final int hour;
  final int milliseconds;
}

class ActivityLedger {
  ActivityLedger({
    required this.date,
    this.steps = 0,
    this.dayStartSensor,
    this.activeSeconds = 0,
    this.activeSteps = 0,
    this.cadenceSpm = 0,
    this.reconciledSteps = 0,
    List<int>? hourlySteps,
    Map<String, _DayTotals>? history,
    this.lastEventAt,
    this.lastSensor,
    this.lastElapsedMillis,
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
            reconciledSteps: (value['reconciled'] as num?)?.toInt() ?? 0,
            hourly: rawHourly is List && rawHourly.length == 24
                ? [
                    for (final hour in rawHourly)
                      if (hour is num) math.max(0, hour.toInt()) else 0,
                  ]
                : null,
            dayStartSensor: (value['dayStartSensor'] as num?)?.toInt(),
            lastSensor: (value['lastSensor'] as num?)?.toInt(),
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
      dayStartSensor: (json['dayStartSensor'] as num?)?.toInt(),
      activeSeconds: (json['activeSeconds'] as num?)?.toInt() ?? 0,
      activeSteps: (json['activeSteps'] as num?)?.toInt() ?? 0,
      cadenceSpm: (json['cadenceSpm'] as num?)?.toDouble() ?? 0,
      reconciledSteps: (json['reconciledSteps'] as num?)?.toInt() ?? 0,
      hourlySteps: hourly,
      history: history,
      lastEventAt: rawLast is num
          ? DateTime.fromMillisecondsSinceEpoch(rawLast.toInt())
          : null,
      lastSensor: (json['lastSensor'] as num?)?.toInt(),
      lastElapsedMillis: (json['lastElapsed'] as num?)?.toInt(),
    );
  }

  String date;
  int steps;
  int? dayStartSensor;
  int activeSeconds;
  int activeSteps;
  double cadenceSpm;
  int reconciledSteps;
  List<int> _hourlySteps;
  final Map<String, _DayTotals> _history;
  DateTime? lastEventAt;
  int? lastSensor;

  /// `SystemClock.elapsedRealtime()` of the last reading. It moves
  /// backwards only when the device rebooted, which resets the hardware
  /// counter; that is how a reset is told apart from a stale reading.
  int? lastElapsedMillis;
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
  ///
  /// Readings may arrive from the live stream or, after the app was
  /// closed, from timestamped background samples. The delta between two
  /// readings is apportioned across the clock hours and local days it
  /// spans, so movement taken while the app was dead is neither lost nor
  /// dumped into the hour the app reopened.
  void record({
    required int sensorSteps,
    required DateTime at,
    int? elapsedMillis,
  }) {
    // The ledger's `date` is *today*, and it only ever moves forward. A
    // background sample captured days ago is folded into that day's
    // history instead of dragging "today" back with it. ISO date keys
    // compare correctly as strings.
    if (date.isEmpty || localDateKey(at).compareTo(date) >= 0) _ensureDate(at);
    if (sensorSteps < 0) return;

    final previousSensor = lastSensor;
    final previousAt = lastEventAt;
    final previousElapsed = lastElapsedMillis;

    if (previousSensor == null) {
      final anchor = _legacyAnchor;
      if (anchor != null && sensorSteps >= anchor && anchor > 0) {
        _addSteps(dateKey: date, hour: at.hour, steps: sensorSteps - anchor);
        dayStartSensor = anchor;
      } else {
        dayStartSensor = sensorSteps;
      }
      lastSensor = sensorSteps;
      lastElapsedMillis = elapsedMillis;
      lastEventAt = at;
      _syncHistoryEntry();
      return;
    }

    // A reading older than the cursor is a duplicate or a late delivery
    // (for example a background sample already covered by richer live
    // events). Ignoring it prevents double counting.
    if (previousAt != null && at.isBefore(previousAt)) return;

    // Sensor reset: reboot (elapsedRealtime went backwards), OEM counter
    // reset, or a decreasing value. Re-anchor; steps between the last
    // reading and the reset are not recoverable.
    final rebooted =
        (elapsedMillis != null &&
            previousElapsed != null &&
            elapsedMillis < previousElapsed) ||
        sensorSteps < previousSensor;
    if (rebooted) {
      dayStartSensor = sensorSteps;
      lastSensor = sensorSteps;
      lastElapsedMillis = elapsedMillis;
      lastEventAt = at;
      _syncHistoryEntry();
      return;
    }

    final delta = sensorSteps - previousSensor;
    if (delta <= 0) {
      lastSensor = sensorSteps;
      lastElapsedMillis = elapsedMillis;
      lastEventAt = at;
      _syncHistoryEntry();
      return;
    }

    if (previousAt == null || !at.isAfter(previousAt)) {
      _addSteps(dateKey: localDateKey(at), hour: at.hour, steps: delta);
    } else {
      _attributeDelta(delta, from: previousAt, to: at);
      _accumulateMovement(delta: delta, from: previousAt, to: at);
    }

    lastSensor = sensorSteps;
    lastElapsedMillis = elapsedMillis;
    lastEventAt = at;
    _syncHistoryEntry();
    if (activeSeconds > 86400) activeSeconds = 86400;
  }

  /// Manually add steps to today (e.g. treadmill, walking without phone, or manual log).
  void addManualSteps(int count, {required DateTime at}) {
    final now = at;
    _ensureDate(now);
    if (count <= 0) return;
    _addSteps(dateKey: date, hour: now.hour, steps: count);
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
      reconciledSteps = math.min(reconciledSteps, newSteps);
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
    reconciledSteps = 0;
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
            reconciledSteps: i == 0
                ? reconciledSteps
                : (recorded?.reconciledSteps ?? 0),
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
      reconciledSteps: reconciledSteps,
      updatedAt: lastEventAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'steps': steps,
    if (dayStartSensor != null) 'dayStartSensor': dayStartSensor,
    'activeSeconds': activeSeconds,
    'activeSteps': activeSteps,
    'cadenceSpm': cadenceSpm,
    'reconciledSteps': reconciledSteps,
    'hourly': _hourlySteps,
    'history': {
      for (final entry in _history.entries) entry.key: entry.value.toJson(),
    },
    'lastEventAt': lastEventAt?.millisecondsSinceEpoch,
    'lastSensor': lastSensor,
    'lastElapsed': lastElapsedMillis,
  };

  /// Mirror today's running totals into the seven-day history map. Every
  /// mutation goes through here so steps and active time can never drift
  /// apart in the strip.
  void _syncHistoryEntry() {
    _history[date] = _DayTotals(
      steps: steps,
      activeSeconds: activeSeconds,
      reconciledSteps: reconciledSteps,
      hourly: _hourlySteps,
      dayStartSensor: dayStartSensor,
      lastSensor: lastSensor,
    );
  }

  /// Split [delta] across every clock hour and local day between [from]
  /// and [to], in proportion to the time spent in each. The steps are
  /// measured; only their placement inside the gap is an estimate, so the
  /// day is flagged as reconciled when the gap is longer than two hours.
  void _attributeDelta(
    int delta, {
    required DateTime from,
    required DateTime to,
  }) {
    if (delta <= 0) return;
    if (!to.isAfter(from)) {
      _addSteps(dateKey: localDateKey(to), hour: to.hour, steps: delta);
      return;
    }

    final reconciled = to.difference(from) > const Duration(hours: 2);
    final slices = <_HourSlice>[];
    var cursor = from;
    while (cursor.isBefore(to)) {
      final hourStart = DateTime(
        cursor.year,
        cursor.month,
        cursor.day,
        cursor.hour,
      );
      var hourEnd = hourStart.add(const Duration(hours: 1));
      if (hourEnd.isAfter(to)) hourEnd = to;
      final milliseconds = hourEnd.difference(cursor).inMilliseconds;
      if (milliseconds > 0) {
        slices.add(_HourSlice(localDateKey(cursor), cursor.hour, milliseconds));
      }
      cursor = hourEnd;
    }
    if (slices.isEmpty) {
      _addSteps(dateKey: localDateKey(to), hour: to.hour, steps: delta);
      return;
    }

    final totalMs = slices.fold<int>(
      0,
      (sum, slice) => sum + slice.milliseconds,
    );
    // Largest-remainder apportionment keeps the hourly buckets summing to
    // exactly [delta] (no steps invented or lost to rounding).
    final shares = <int>[];
    final remainders = <int>[];
    var assigned = 0;
    for (final slice in slices) {
      final numerator = delta * slice.milliseconds;
      final share = numerator ~/ totalMs;
      shares.add(share);
      remainders.add(numerator % totalMs);
      assigned += share;
    }
    var leftover = delta - assigned;
    final order = List<int>.generate(slices.length, (i) => i)
      ..sort((a, b) => remainders[b].compareTo(remainders[a]));
    for (var i = 0; leftover > 0; i++, leftover--) {
      shares[order[i % order.length]]++;
    }

    for (var i = 0; i < slices.length; i++) {
      if (shares[i] == 0) continue;
      _addSteps(
        dateKey: slices[i].dateKey,
        hour: slices[i].hour,
        steps: shares[i],
        reconciled: reconciled,
      );
    }
  }

  /// Add steps to a day's total and its hour bucket. The live day uses the
  /// scalar fields; any other day is updated inside the history map.
  void _addSteps({
    required String dateKey,
    required int hour,
    required int steps,
    bool reconciled = false,
  }) {
    if (steps <= 0) return;
    final bucket = hour.clamp(0, 23);
    if (dateKey == date) {
      this.steps += steps;
      _hourlySteps[bucket] += steps;
      if (reconciled) reconciledSteps += steps;
      _syncHistoryEntry();
      return;
    }
    final totals = _history.putIfAbsent(dateKey, () => _DayTotals());
    totals.steps += steps;
    totals.hourly[bucket] += steps;
    if (reconciled) totals.reconciledSteps += steps;
  }

  void _accumulateMovement({
    required int delta,
    required DateTime from,
    required DateTime to,
  }) {
    final elapsedMs = to.difference(from).inMilliseconds;
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
    if (steps > 0 || activeSeconds > 0 || reconciledSteps > 0) {
      _history[date] = _DayTotals(
        steps: steps,
        activeSeconds: activeSeconds,
        reconciledSteps: reconciledSteps,
        hourly: _hourlySteps,
        dayStartSensor: dayStartSensor,
        lastSensor: lastSensor,
      );
    }
    date = key;
    steps = 0;
    activeSeconds = 0;
    activeSteps = 0;
    cadenceSpm = 0;
    reconciledSteps = 0;
    _hourlySteps = List<int>.filled(24, 0);
    // The sensor cursor at midnight rollover becomes the new day's baseline anchor
    dayStartSensor = lastSensor;
    _legacyAnchor = null;
    _history[key] = _DayTotals(dayStartSensor: dayStartSensor);
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
