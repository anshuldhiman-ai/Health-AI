import 'dart:convert';

import 'package:app/app/log_store.dart';
import 'package:app/domain/entities/log_entry.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "The food I logged is gone when I reopen the app" is the failure
/// these tests exist to prevent. They drive the real
/// [DayLog] -> SharedPreferences -> [loadSavedDayLog] path, because a
/// fake store would agree with whatever the fake was told.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  LogEntry entry({MealKind meal = MealKind.dinner, int kcal = 180}) =>
      LogEntry.estimated(mealKind: meal, dish: 'Samosa', kcal: kcal);

  /// A fresh load of what is currently on disk, as bootstrap does it.
  Future<DayLog> reopen() async {
    final loaded = await loadSavedDayLog();
    // Nothing should still be in flight when the next "launch" reads.
    await loaded.flush();
    return loaded;
  }

  test('an entry survives a reopen', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = DayLog(prefs: prefs);
    store.add(entry(kcal: 180), dayOffset: 0);
    await store.flush();

    expect((await reopen()).entriesFor(0), hasLength(1));
  });

  test('every field round-trips, not just the dish name', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = DayLog(prefs: prefs);
    final original = LogEntry.estimated(
      mealKind: MealKind.breakfast,
      dish: 'Poha',
      kcal: 250,
      timeLabel: '8:15 AM',
    );
    store.add(original, dayOffset: 0);
    await store.flush();

    final restored = (await reopen()).entriesFor(0).single;
    expect(restored.mealKind, original.mealKind);
    expect(restored.dish, original.dish);
    expect(restored.kcal, original.kcal);
    expect(restored.proteinGrams, original.proteinGrams);
    expect(restored.carbsGrams, original.carbsGrams);
    expect(restored.fatGrams, original.fatGrams);
    expect(restored.timeLabel, original.timeLabel);
  });

  test('days and their order survive a reopen', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = DayLog(prefs: prefs);
    store
      ..add(entry(kcal: 100), dayOffset: 0)
      ..add(entry(kcal: 200), dayOffset: 0)
      ..add(entry(kcal: 300), dayOffset: 3);
    await store.flush();

    final restored = await reopen();
    expect(restored.entriesFor(0).map((e) => e.kcal), [
      100,
      200,
    ], reason: 'order is the diary order, not just the set of entries');
    expect(restored.entriesFor(3).single.kcal, 300);
  });

  test('an Undo that follows an add is not lost to a write race', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = DayLog(prefs: prefs);
    store.add(entry());
    // Deliberately not awaited: the add's write is still queued.
    store.removeNewest(0);
    await store.flush();

    expect(
      (await reopen()).entriesFor(0),
      isEmpty,
      reason: 'writes are serialised, so the undo cannot land first',
    );
  });

  test(
    'entries logged yesterday are still under yesterday after a reopen',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final store = DayLog(prefs: prefs);
      store.add(entry(kcal: 400), dayOffset: 1);
      await store.flush();

      expect((await reopen()).entriesFor(1).single.kcal, 400);
    },
  );

  test(
    'a payload written on an earlier day moves forward, not off the end',
    () async {
      // The store indexes days by offset from today, so a log written two
      // days ago must arrive as day 2, not silently stay day 0.
      final prefs = await SharedPreferences.getInstance();
      final base = DateTime.now().subtract(const Duration(days: 2));
      await prefs.setString(
        DayLog.storageKey,
        jsonEncode({
          'baseDate': DateTime(
            base.year,
            base.month,
            base.day,
          ).toIso8601String(),
          'days': {
            '0': [
              LogEntry.estimated(
                mealKind: MealKind.lunch,
                dish: 'Dal',
                kcal: 320,
              ).toJson(),
            ],
            '1': [
              LogEntry.estimated(
                mealKind: MealKind.lunch,
                dish: 'Rice',
                kcal: 210,
              ).toJson(),
            ],
          },
        }),
      );

      final restored = await reopen();
      expect(
        restored.entriesFor(0),
        isEmpty,
        reason: 'today had nothing logged',
      );
      expect(restored.entriesFor(2).single.dish, 'Dal');
      expect(restored.entriesFor(3).single.dish, 'Rice');
    },
  );

  test('a corrupt payload costs the log, not the app', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(DayLog.storageKey, '{not json at all');

    final restored = await reopen();
    expect(restored.entriesFor(0), isEmpty);
  });

  test(
    'a corrupt payload is dropped rather than re-read every launch',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(DayLog.storageKey, '{not json at all');
      await reopen();

      expect(prefs.getString(DayLog.storageKey), isNull);
    },
  );

  test('one malformed row does not take its day down with it', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      DayLog.storageKey,
      jsonEncode({
        'baseDate': DateTime.now().toIso8601String(),
        'days': {
          '0': [
            {'dish': 'no kcal field'},
            LogEntry.estimated(
              mealKind: MealKind.dinner,
              dish: 'Idli',
              kcal: 140,
            ).toJson(),
          ],
        },
      }),
    );

    final restored = await reopen();
    expect(restored.entriesFor(0).single.dish, 'Idli');
  });

  test('a log with no prefs still holds entries for the session', () async {
    // The fallback path when storage is unavailable: the app must keep
    // working in memory rather than dropping what the user logs.
    final store = DayLog()..add(entry(kcal: 150));
    await store.flush();

    expect(store.entriesFor(0).single.kcal, 150);
  });
}
