import 'package:app/core/time/clock.dart';
import 'package:app/domain/services/safety_rules.dart';
import 'package:test/test.dart';

/// Tests for the day-boundary logic (ADR 0005).
///
/// The key property: a timestamp's local day must be stable under
/// the offset it was recorded with, even across UTC midnight and
/// timezone changes.
void main() {
  group('DayBoundary.localDateOf', () {
    test('noon UTC on a fixed date maps to the same local date for UTC+0',
        () {
      // 2026-10-11 12:00 UTC
      final epoch = DateTime.utc(2026, 10, 11, 12).millisecondsSinceEpoch;
      final d = DayBoundary.localDateOf(epoch, 0);
      expect(d, const LocalDate(2026, 10, 11));
    });

    test('late-evening UTC is the next local day in IST (UTC+5:30)', () {
      // 2026-10-11 21:00 UTC = 2026-10-12 02:30 IST
      final epoch = DateTime.utc(2026, 10, 11, 21).millisecondsSinceEpoch;
      final d = DayBoundary.localDateOf(epoch, 330);
      expect(d, const LocalDate(2026, 10, 12));
    });

    test('early-morning UTC is the previous local day in US Pacific (UTC-7)',
        () {
      // 2026-10-12 05:00 UTC = 2026-10-11 22:00 PDT
      final epoch = DateTime.utc(2026, 10, 12, 5).millisecondsSinceEpoch;
      final d = DayBoundary.localDateOf(epoch, -420);
      expect(d, const LocalDate(2026, 10, 11));
    });

    test('negative offsets cross the international date line correctly', () {
      // 2026-10-12 00:30 UTC = 2026-10-11 10:00 UTC-14:30? (no -14:30 in
      // practice, but the arithmetic must hold for any offset)
      final epoch = DateTime.utc(2026, 10, 12, 0, 30).millisecondsSinceEpoch;
      final d = DayBoundary.localDateOf(epoch, -870);
      expect(d, const LocalDate(2026, 10, 11));
    });
  });

  group('DayBoundary.startOfDayUtc / endOfDayUtc', () {
    test('start of local day in IST is 18:30 UTC of the previous day', () {
      final epoch = DateTime.utc(2026, 10, 12, 10).millisecondsSinceEpoch;
      final start = DayBoundary.startOfDayUtc(epoch, 330);
      // Local midnight 2026-10-12 00:00 IST = 2026-10-11 18:30 UTC
      expect(DateTime.fromMillisecondsSinceEpoch(start, isUtc: true),
          DateTime.utc(2026, 10, 11, 18, 30));
    });

    test('end of local day is start + 24h and is exclusive', () {
      final epoch = DateTime.utc(2026, 10, 12, 10).millisecondsSinceEpoch;
      final start = DayBoundary.startOfDayUtc(epoch, 330);
      final end = DayBoundary.endOfDayUtc(epoch, 330);
      expect(end - start, const Duration(hours: 24).inMilliseconds);
      // The boundary moment itself belongs to the NEXT local day.
      expect(DayBoundary.localDateOf(end, 330), const LocalDate(2026, 10, 13));
      expect(DayBoundary.localDateOf(end - 1, 330), const LocalDate(2026, 10, 12));
    });
  });

  group('DayBoundary.today', () {
    test('uses the injected clock, not real time', () {
      final clock = FakeClock(DateTime.utc(2026, 10, 11, 23, 30));
      // 23:30 UTC = 05:00 IST next day
      expect(DayBoundary.today(330, clock), const LocalDate(2026, 10, 12));
      clock.advance(const Duration(hours: 2));
      expect(DayBoundary.today(330, clock), const LocalDate(2026, 10, 12));
      // UTC midnight crossed; local day already advanced.
      clock.advance(const Duration(hours: 2));
      expect(DayBoundary.today(0, clock), const LocalDate(2026, 10, 12));
    });
  });

  group('LocalDate', () {
    test('parse/format round-trip', () {
      const d = LocalDate(2026, 10, 12);
      expect(d.toIso(), '2026-10-12');
      expect(LocalDate.parse('2026-10-12'), d);
    });

    test('orders chronologically', () {
      expect(const LocalDate(2026, 10, 11)
          .compareTo(const LocalDate(2026, 10, 12)),
          lessThan(0));
      expect(const LocalDate(2026, 11, 1)
          .compareTo(const LocalDate(2026, 10, 31)),
          greaterThan(0));
      expect(const LocalDate(2025, 12, 31)
          .compareTo(const LocalDate(2026, 1, 1)),
          lessThan(0));
    });

    test('rejects malformed input', () {
      expect(() => LocalDate.parse('12-10-2026'), throwsFormatException);
      expect(() => LocalDate.parse('2026-10'), throwsFormatException);
    });
  });
}
