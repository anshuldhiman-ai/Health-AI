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

enum StepStatus { live, permissionDenied, unsupported, unavailable }

/// One day in the seven-day activity strip.
class DaySteps {
  const DaySteps({required this.date, required this.steps});

  final DateTime date;
  final int steps;
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
