/// Day-boundary logic (Section 6.5).
///
/// The single authority that decides which local day a timestamp
/// belongs to (ADR 0005). Every timestamp is stored as UTC epoch
/// millis plus `tz_offset_min`; this service turns that pair into a
/// stable local date.
///
/// Pure Dart (R9). No `DateTime.now()` — callers inject the current
/// epoch millis (from a `Clock`, in the application layer) so tests
/// can control time.
library;

/// A local calendar date (year, month, day), with no time-of-day.
///
/// Comparable in chronological order.
final class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day)
    : assert(month >= 1 && month <= 12),
      assert(day >= 1 && day <= 31);

  /// Builds a [LocalDate] from a UTC [DateTime] with the given
  /// offset applied.
  factory LocalDate.fromUtc(DateTime utc, int tzOffsetMin) {
    final local = utc.add(Duration(minutes: tzOffsetMin));
    return LocalDate(local.year, local.month, local.day);
  }

  /// Parses `yyyy-MM-dd` (the storage/serialisation form).
  factory LocalDate.parse(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) {
      throw FormatException('Expected yyyy-MM-dd, got "$iso"');
    }
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    // Validate explicitly: asserts alone are debug-only and would make
    // behaviour differ between debug and release builds.
    if (y == null ||
        m == null ||
        d == null ||
        m < 1 ||
        m > 12 ||
        d < 1 ||
        d > 31) {
      throw FormatException('Expected yyyy-MM-dd, got "$iso"');
    }
    return LocalDate(y, m, d);
  }

  final int year;
  final int month;
  final int day;

  /// `yyyy-MM-dd` — used as the `local_date` key in `user.db`.
  String toIso() =>
      '$year-${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}

/// Determines the local day for a timestamp under a given offset.
abstract final class DayBoundary {
  /// The local date of [epochMillisUtc] in the timezone at
  /// [tzOffsetMin] from UTC.
  static LocalDate localDateOf(int epochMillisUtc, int tzOffsetMin) {
    final utc = DateTime.fromMillisecondsSinceEpoch(
      epochMillisUtc,
      isUtc: true,
    );
    return LocalDate.fromUtc(utc, tzOffsetMin);
  }

  /// Start of the local day (as UTC epoch millis) containing
  /// [epochMillisUtc].
  static int startOfDayUtc(int epochMillisUtc, int tzOffsetMin) {
    final local = DateTime.fromMillisecondsSinceEpoch(
      epochMillisUtc,
      isUtc: true,
    ).add(Duration(minutes: tzOffsetMin));
    // Must be built as UTC: the host's own timezone must never
    // influence the result (ADR 0005 — reproducible on every machine).
    final localMidnight = DateTime.utc(local.year, local.month, local.day);
    return localMidnight
        .subtract(Duration(minutes: tzOffsetMin))
        .millisecondsSinceEpoch;
  }

  /// End of the local day (exclusive, as UTC epoch millis).
  static int endOfDayUtc(int epochMillisUtc, int tzOffsetMin) =>
      startOfDayUtc(epochMillisUtc, tzOffsetMin) +
      const Duration(hours: 24).inMilliseconds;

  /// True when [epochMillisUtc] falls on the same local day as
  /// [otherMillisUtc], under the same offset.
  static bool sameLocalDay(
    int epochMillisUtc,
    int otherMillisUtc,
    int tzOffsetMin,
  ) =>
      localDateOf(epochMillisUtc, tzOffsetMin) ==
      localDateOf(otherMillisUtc, tzOffsetMin);

  /// The local date "today" under [tzOffsetMin], given the current
  /// time as UTC epoch millis. The caller injects the time from a
  /// `Clock` (Section 11.1) so tests can control it.
  static LocalDate today(int nowEpochMillisUtc, int tzOffsetMin) =>
      localDateOf(nowEpochMillisUtc, tzOffsetMin);
}
