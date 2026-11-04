/// Activity readings from the phone's step counter. Pure Dart (R9).
///
/// The sensor reports a cumulative count since boot; the ledger below
/// derives today's steps plus the movement metrics the UI shows.
library;

/// Daily step goal. A product default, not personalised medical advice.
const int kDailyStepGoal = 8000;

/// Average adult walking stride used for the distance estimate. The
/// activity screen states this assumption instead of pretending the
/// phone measured distance.
const double kAverageStrideMeters = 0.762;

/// Rough energy cost of one step, used only to show an *estimate* on the
/// activity screen. Real burn depends on body mass, gradient and pace, so
/// this is deliberately crude and must never be presented as a
/// measurement or fed into the calorie budget (CLAUDE.md Section 7.3).
const double kKcalPerStepEstimate = 0.04;

enum StepStatus { live, permissionDenied, unsupported, unavailable }

/// One cumulative reading from the platform step counter.
///
/// The hardware counter counts since boot, so a reading is only useful
/// as a pair: the difference between two readings is the movement
/// between their timestamps. [elapsedMillis] is the device's
/// `SystemClock.elapsedRealtime()` at capture time, used to detect a
/// reboot (which resets the counter).
class StepReading {
  const StepReading({
    required this.at,
    required this.sensorSteps,
    this.elapsedMillis,
  });

  final DateTime at;
  final int sensorSteps;
  final int? elapsedMillis;
}

/// One day in the seven-day activity strip.
///
/// [steps], [activeSeconds] and [hourlySteps] are all measured: the sensor
/// counted the steps, the ledger clocked the active intervals and filed
/// each step into the hour it happened in. Nothing here is seeded or
/// back-filled for a day the app never recorded.
class DaySteps {
  const DaySteps({
    required this.date,
    required this.steps,
    this.activeSeconds = 0,
    this.hourlySteps = const <int>[],
    this.reconciledSteps = 0,
  });

  final DateTime date;
  final int steps;

  /// Measured moving time for that day. Zero when the day was tracked
  /// before this field existed, which the UI must not dress up as data.
  final int activeSeconds;

  /// Steps in each clock hour of that day (24 buckets, local time). A day
  /// recorded before hourly detail was stored reads all zeroes; the UI
  /// says so instead of drawing a flat, invented chart.
  final List<int> hourlySteps;

  /// Steps recovered from a sensor backlog (the app was not running).
  /// Their daily total is real; the hour they are filed under is a
  /// time-proportional estimate, so the UI can say so.
  final int reconciledSteps;
}

/// The clock hour with the most steps, or null when the day holds no
/// hourly detail or no movement at all.
int? peakHourOfDay(List<int> hourlySteps) {
  if (hourlySteps.length != 24) return null;
  var bestSteps = 0;
  var bestHour = -1;
  for (var hour = 0; hour < 24; hour++) {
    if (hourlySteps[hour] > bestSteps) {
      bestSteps = hourlySteps[hour];
      bestHour = hour;
    }
  }
  return bestHour < 0 ? null : bestHour;
}

/// Immutable view of today's activity for the dashboard and detail
/// screen. All distance/cadence values are derived, never seeded.
class StepSnapshot {
  const StepSnapshot({
    required this.status,
    this.steps = 0,
    this.distanceMeters = 0,
    this.activeSeconds = 0,
    this.cadenceSpm = 0,
    this.averageCadenceSpm = 0,
    this.hourlySteps = const <int>[],
    this.history = const <DaySteps>[],
    this.reconciledSteps = 0,
    this.updatedAt,
  });

  final StepStatus status;
  final int steps;
  final double distanceMeters;
  final int activeSeconds;

  /// Most recent walking cadence, steps per minute.
  final double cadenceSpm;

  /// Walking cadence averaged over counted active time.
  final int averageCadenceSpm;

  /// Steps in each clock hour (24 buckets).
  final List<int> hourlySteps;

  /// Today plus the six preceding days, oldest first.
  final List<DaySteps> history;

  /// Steps among [steps] that came from a backlog sensor reading rather
  /// than a live stream event. The total is measured; their hour split is
  /// an estimate.
  final int reconciledSteps;

  final DateTime? updatedAt;

  bool get isLive => status == StepStatus.live;

  double get distanceKm => distanceMeters / 1000;

  /// Progress against [kDailyStepGoal], clamped for the ring.
  double get goalProgress => (steps / kDailyStepGoal).clamp(0.0, 1.0);

  /// Average pace in minutes per kilometre. Requires enough movement to
  /// avoid a meaningless number after a few indoor steps.
  double? get paceMinPerKm {
    if (distanceMeters < 50 || activeSeconds < 30) return null;
    return (activeSeconds / 60) / distanceKm;
  }

  /// Current cadence when available, otherwise today's average.
  int get displayCadence =>
      cadenceSpm > 0 ? cadenceSpm.round() : averageCadenceSpm;
}
