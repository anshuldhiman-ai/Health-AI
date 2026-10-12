/// Clock abstraction (Section 11.1).
///
/// Domain and data code NEVER calls `DateTime.now()` directly — it
/// goes through [Clock] so tests can control time.
///
/// Pure Dart — no Flutter imports (R9).
library;

abstract interface class Clock {
  /// Current UTC time.
  DateTime nowUtc();

  /// Current epoch milliseconds (UTC).
  int nowEpochMillis() => nowUtc().millisecondsSinceEpoch;
}

/// The real clock. The only place in the app allowed to call
/// `DateTime.now()`.
final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

/// A controllable clock for tests.
final class FakeClock implements Clock {
  FakeClock(this._timeUtc);

  DateTime _timeUtc;

  @override
  DateTime nowUtc() => _timeUtc;

  /// Advance time by [duration].
  void advance(Duration duration) => _timeUtc = _timeUtc.add(duration);

  /// Set the current time.
  void set(DateTime timeUtc) => _timeUtc = timeUtc.toUtc();
}
