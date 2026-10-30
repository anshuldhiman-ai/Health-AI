import 'dart:convert';

import 'package:app/domain/entities/activity_snapshot.dart';
import 'package:app/domain/services/activity_ledger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A fixed local noon so day-boundary maths never depends on when the
  // suite runs.
  final noon = DateTime(2026, 10, 20, 12);
  final yesterday = DateTime(2026, 10, 19, 20);

  group('ActivityLedger.record', () {
    test('first reading anchors instead of counting the whole sensor', () {
      final ledger = ActivityLedger.empty(noon);

      // A phone that has been counting since boot reports 40,000 steps.
      ledger.record(sensorSteps: 40000, at: noon);

      expect(ledger.steps, 0, reason: 'the backlog belongs to no known day');
      expect(ledger.snapshot(StepStatus.live, noon).steps, 0);
    });

    test('counts the delta between consecutive readings', () {
      final ledger = ActivityLedger.empty(noon);

      ledger.record(sensorSteps: 40000, at: noon);
      ledger.record(
        sensorSteps: 40250,
        at: noon.add(const Duration(minutes: 3)),
      );

      expect(ledger.steps, 250);
    });

    test('sensor reset after reboot re-anchors without losing today', () {
      final ledger = ActivityLedger.empty(noon);
      ledger.record(sensorSteps: 40000, at: noon);
      ledger.record(
        sensorSteps: 41000,
        at: noon.add(const Duration(minutes: 10)),
      );
      expect(ledger.steps, 1000);

      // Reboot: the cumulative counter starts again from near zero.
      ledger.record(sensorSteps: 12, at: noon.add(const Duration(minutes: 40)));
      expect(ledger.steps, 1000, reason: 'already-counted steps must survive');

      ledger.record(
        sensorSteps: 300,
        at: noon.add(const Duration(minutes: 45)),
      );
      expect(ledger.steps, 1288);
    });

    test('a repeated or decreasing reading never subtracts steps', () {
      final ledger = ActivityLedger.empty(noon);
      ledger.record(sensorSteps: 1000, at: noon);
      ledger.record(
        sensorSteps: 1500,
        at: noon.add(const Duration(minutes: 5)),
      );
      ledger.record(
        sensorSteps: 1500,
        at: noon.add(const Duration(minutes: 6)),
      );

      expect(ledger.steps, 500);
    });

    test('legacy baseline is adopted once so an update keeps today', () {
      final ledger = ActivityLedger.empty(noon)..legacyAnchor = 9000;

      ledger.record(sensorSteps: 9500, at: noon);

      expect(ledger.steps, 500);
    });
  });

  group('ActivityLedger day boundary', () {
    test('rolling past midnight banks yesterday and restarts today', () {
      final ledger = ActivityLedger.empty(noon);
      ledger.record(sensorSteps: 1000, at: noon);
      ledger.record(sensorSteps: 3000, at: noon.add(const Duration(hours: 8)));
      expect(ledger.steps, 2000);

      final nextMorning = DateTime(2026, 10, 21, 8);
      ledger.syncTo(nextMorning);

      expect(ledger.steps, 0, reason: 'the new day starts empty');
      expect(ledger.hourlySteps.every((v) => v == 0), isTrue);

      final history = ledger.snapshot(StepStatus.live, nextMorning).history;
      final yesterdayEntry = history.firstWhere(
        (d) => d.date.day == 20 && d.date.month == 10,
      );
      expect(yesterdayEntry.steps, 2000);
    });

    test('steps walked while the app was closed are not credited to today', () {
      final ledger = ActivityLedger.empty(yesterday);
      ledger.record(sensorSteps: 5000, at: yesterday);
      ledger.record(
        sensorSteps: 6000,
        at: yesterday.add(const Duration(minutes: 30)),
      );
      expect(ledger.steps, 1000);

      // App closed overnight; the sensor kept counting to 22000.
      final nextMorning = DateTime(2026, 10, 20, 9);
      ledger.syncTo(nextMorning);
      ledger.record(sensorSteps: 22000, at: nextMorning);

      expect(
        ledger.steps,
        0,
        reason: 'unobserved steps have no honest day to belong to',
      );

      ledger.record(
        sensorSteps: 22120,
        at: nextMorning.add(const Duration(minutes: 4)),
      );
      expect(ledger.steps, 120);
    });

    test('history keeps seven days and drops anything older', () {
      final ledger = ActivityLedger.empty(DateTime(2026, 10, 1, 12));

      for (var day = 1; day <= 12; day++) {
        final at = DateTime(2026, 10, day, 12);
        ledger.syncTo(at);
        ledger.record(sensorSteps: day * 1000, at: at);
        ledger.record(
          sensorSteps: (day * 1000) + 500,
          at: at.add(const Duration(minutes: 5)),
        );
      }

      final history = ledger
          .snapshot(StepStatus.live, DateTime(2026, 10, 12, 13))
          .history;

      expect(history, hasLength(7));
      expect(history.first.date.day, 6);
      expect(history.last.date.day, 12);
      expect(history.last.steps, 500);
    });

    test('an unobserved day reads as zero rather than an estimate', () {
      final ledger = ActivityLedger.empty(DateTime(2026, 10, 10, 12));
      ledger.record(sensorSteps: 100, at: DateTime(2026, 10, 10, 12));
      ledger.record(sensorSteps: 900, at: DateTime(2026, 10, 10, 12, 30));

      // Nothing recorded on the 13th or 14th.
      final at = DateTime(2026, 10, 15, 9);
      ledger.syncTo(at);
      final history = ledger.snapshot(StepStatus.live, at).history;

      final gapDay = history.firstWhere((d) => d.date.day == 13);
      expect(gapDay.steps, 0);
      expect(gapDay.activeSeconds, 0);
    });
  });

  group('ActivityLedger active time', () {
    test('counts moving intervals and ignores long silent gaps', () {
      final ledger = ActivityLedger.empty(noon);

      ledger.record(sensorSteps: 0, at: noon);
      // 60 steps in 30 s ≈ 120 spm — plausible walking.
      ledger.record(sensorSteps: 60, at: noon.add(const Duration(seconds: 30)));
      expect(ledger.activeSeconds, 30);

      // A four-hour gap is not exercise, however many steps arrived.
      ledger.record(sensorSteps: 5000, at: noon.add(const Duration(hours: 4)));
      expect(ledger.activeSeconds, 30);
    });

    test('per-day history carries the measured active time', () {
      final ledger = ActivityLedger.empty(noon);
      ledger.record(sensorSteps: 0, at: noon);
      ledger.record(sensorSteps: 100, at: noon.add(const Duration(minutes: 1)));
      final walkedSeconds = ledger.activeSeconds;
      expect(walkedSeconds, greaterThan(0));

      final nextDay = DateTime(2026, 10, 21, 9);
      ledger.syncTo(nextDay);

      final history = ledger.snapshot(StepStatus.live, nextDay).history;
      final day20 = history.firstWhere((d) => d.date.day == 20);
      expect(
        day20.activeSeconds,
        walkedSeconds,
        reason: 'the strip must show measured time, not a step-derived guess',
      );
    });
  });

  group('ActivityLedger hourly history', () {
    test('keeps a finished day\'s hourly buckets after the rollover', () {
      final ledger = ActivityLedger.empty(noon);
      ledger.record(sensorSteps: 1000, at: noon); // anchor
      ledger.record(sensorSteps: 1200, at: noon.add(const Duration(hours: 1)));
      ledger.record(sensorSteps: 1600, at: noon.add(const Duration(hours: 2)));
      expect(ledger.hourlySteps[13], 200);
      expect(ledger.hourlySteps[14], 400);

      final nextDay = DateTime(2026, 10, 21, 9);
      ledger.syncTo(nextDay);

      final history = ledger.snapshot(StepStatus.live, nextDay).history;
      final day20 = history.firstWhere((d) => d.date.day == 20);

      expect(day20.hourlySteps, hasLength(24));
      expect(day20.hourlySteps[13], 200);
      expect(day20.hourlySteps[14], 400);
      expect(
        day20.hourlySteps[9],
        0,
        reason: 'hours the app was not tracking stay empty',
      );
      expect(peakHourOfDay(day20.hourlySteps), 14);
    });

    test('today carries its own hourly buckets in the snapshot', () {
      final ledger = ActivityLedger.empty(noon);
      ledger.record(sensorSteps: 0, at: noon);
      ledger.record(sensorSteps: 300, at: noon.add(const Duration(hours: 3)));

      final today = ledger.snapshot(StepStatus.live, noon).history.last;

      expect(today.hourlySteps[15], 300);
      expect(peakHourOfDay(today.hourlySteps), 15);
    });

    test('hourly buckets survive a JSON round-trip per day', () {
      final ledger = ActivityLedger.empty(noon);
      ledger.record(sensorSteps: 0, at: noon);
      ledger.record(sensorSteps: 250, at: noon.add(const Duration(hours: 5)));

      final nextDay = DateTime(2026, 10, 21, 9);
      ledger.syncTo(nextDay);

      final restored = ActivityLedger.fromJson(
        jsonDecode(jsonEncode(ledger.toJson())) as Map<String, dynamic>,
      );
      final history = restored.snapshot(StepStatus.live, nextDay).history;
      final day20 = history.firstWhere((d) => d.date.day == 20);

      expect(day20.hourlySteps[17], 250);
    });

    test('a legacy day has no invented hours', () {
      final restored = ActivityLedger.fromJson({
        'date': '2026-10-20',
        'steps': 100,
        'history': {'2026-10-19': 6100},
      });

      final day19 = restored
          .snapshot(StepStatus.live, noon)
          .history
          .firstWhere((d) => d.date.day == 19);

      expect(day19.steps, 6100);
      expect(day19.hourlySteps.every((v) => v == 0), isTrue);
      expect(peakHourOfDay(day19.hourlySteps), isNull);
    });
  });

  group('peakHourOfDay', () {
    test('returns the busiest clock hour', () {
      final hours = List<int>.filled(24, 0);
      hours[7] = 120;
      hours[18] = 900;
      hours[19] = 400;

      expect(peakHourOfDay(hours), 18);
    });

    test('returns null for a day with no movement and for bad input', () {
      expect(peakHourOfDay(List<int>.filled(24, 0)), isNull);
      expect(peakHourOfDay(const <int>[]), isNull);
      expect(peakHourOfDay(const [1, 2, 3]), isNull);
    });
  });

  group('ActivityLedger manual edits', () {
    test('manual steps add to today and to the hour bucket', () {
      final ledger = ActivityLedger.empty(noon);

      ledger.addManualSteps(1500, at: noon);

      expect(ledger.steps, 1500);
      expect(ledger.hourlySteps[noon.hour], 1500);
      expect(ledger.snapshot(StepStatus.live, noon).history.last.steps, 1500);
    });

    test('set exact total replaces rather than adds', () {
      final ledger = ActivityLedger.empty(noon);
      ledger.addManualSteps(1500, at: noon);

      ledger.setStepsForToday(8000, at: noon);

      expect(ledger.steps, 8000);
    });

    test('clear resets today without touching earlier days', () {
      final ledger = ActivityLedger.empty(noon);
      ledger.record(sensorSteps: 0, at: noon);
      ledger.record(sensorSteps: 400, at: noon.add(const Duration(minutes: 2)));

      final nextDay = DateTime(2026, 10, 21, 9);
      ledger.syncTo(nextDay);
      ledger.addManualSteps(700, at: nextDay);

      ledger.clearTodaySteps(at: nextDay);

      final history = ledger.snapshot(StepStatus.live, nextDay).history;
      expect(history.last.steps, 0);
      expect(history.firstWhere((d) => d.date.day == 20).steps, 400);
    });
  });

  group('ActivityLedger persistence', () {
    test('round-trips steps, history and hourly buckets through JSON', () {
      final ledger = ActivityLedger.empty(noon);
      ledger.record(sensorSteps: 0, at: noon);
      ledger.record(sensorSteps: 420, at: noon.add(const Duration(minutes: 2)));

      final restored = ActivityLedger.fromJson(
        jsonDecode(jsonEncode(ledger.toJson())) as Map<String, dynamic>,
      );

      expect(restored.steps, 420);
      expect(restored.activeSeconds, ledger.activeSeconds);
      expect(restored.lastSensor, ledger.lastSensor);
      expect(restored.hourlySteps[noon.hour], 420);

      final snapshot = restored.snapshot(StepStatus.live, noon);
      expect(snapshot.history.last.steps, 420);
      expect(
        snapshot.history.last.activeSeconds,
        ledger.activeSeconds,
        reason: 'active time must survive a restart',
      );
    });

    test('reads the older steps-only history payload without losing days', () {
      final restored = ActivityLedger.fromJson({
        'date': '2026-10-20',
        'steps': 4321,
        'history': {'2026-10-19': 6100, '2026-10-20': 4321},
      });

      final history = restored.snapshot(StepStatus.live, noon).history;
      final yesterdayEntry = history.firstWhere((d) => d.date.day == 19);

      expect(yesterdayEntry.steps, 6100);
      expect(
        yesterdayEntry.activeSeconds,
        0,
        reason: 'unknown for legacy days — zero, never invented',
      );
    });

    test('survives a malformed history payload', () {
      final restored = ActivityLedger.fromJson({
        'date': '2026-10-20',
        'steps': 100,
        'history': {
          '2026-10-19': 'nonsense',
          42: 900,
          '2026-10-18': {'steps': 50, 'active': 20},
        },
      });

      final history = restored.snapshot(StepStatus.live, noon).history;
      expect(history.firstWhere((d) => d.date.day == 18).steps, 50);
      expect(history.firstWhere((d) => d.date.day == 18).activeSeconds, 20);
    });
  });

  test('snapshot history always covers today plus six days, oldest first', () {
    final ledger = ActivityLedger.empty(noon);

    final history = ledger.snapshot(StepStatus.live, noon).history;

    expect(history, hasLength(7));
    expect(history.last.date, DateTime(2026, 10, 20));
    expect(history.first.date, DateTime(2026, 10, 14));
  });
}
