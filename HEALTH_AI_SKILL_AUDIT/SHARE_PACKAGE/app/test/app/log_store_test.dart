import 'dart:convert';

import 'package:app/app/log_store.dart';
import 'package:app/domain/entities/log_entry.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/domain/entities/nutrition_targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('a new diary starts empty and the ring has no fake totals', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final log = container.read(dayLogProvider.notifier);

    expect(log.entriesFor(0), isEmpty);
    expect(log.totalsFor(0).consumed, 0);
    final loseTarget = targetsForGoal(GoalKind.lose).kcal;
    expect(log.totalsFor(0).consumed < loseTarget, isTrue);
  });

  test('add appends to today and undo removes the newest entry', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final log = container.read(dayLogProvider.notifier);

    expect(log.totalsFor(0).consumed, 0);
    log.add(
      LogEntry.estimated(
        mealKind: MealKind.lunch,
        dish: 'Chole bhature',
        kcal: 420,
      ),
    );
    expect(log.totalsFor(0).consumed, 420);

    expect(log.removeNewest(0), isTrue);
    expect(log.totalsFor(0).consumed, 0);

    // Undo on an out-of-window day slot is a no-op.
    expect(log.removeNewest(DayLog.maxDays + 5), isFalse);
  });

  test('entries persist and reload from local storage', () async {
    SharedPreferences.setMockInitialValues({});
    final first = await loadSavedDayLog();
    first.add(
      const LogEntry(
        mealKind: MealKind.breakfast,
        dish: 'Poha',
        kcal: 320,
        proteinGrams: 8,
        carbsGrams: 52,
        fatGrams: 8,
        timeLabel: '8:15 AM',
      ),
    );
    first.add(
      const LogEntry(
        mealKind: MealKind.lunch,
        dish: 'Kulfi',
        kcal: 180,
        proteinGrams: 4,
        carbsGrams: 22,
        fatGrams: 8,
      ),
      dayOffset: 2,
    );
    await first.flush();

    final second = await loadSavedDayLog();
    expect(second.totalsFor(0).consumed, 320);
    expect(second.totalsFor(2).consumed, 180);
    expect(second.entriesFor(0).single.dish, 'Poha');
  });

  test('saved day offsets shift forward after an absent day', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final base = DateTime(yesterday.year, yesterday.month, yesterday.day);
    SharedPreferences.setMockInitialValues({
      DayLog.storageKey: jsonEncode({
        'baseDate': base.toIso8601String(),
        'days': {
          '0': [
            {
              'mealKind': 'dinner',
              'dish': 'Dal + roti',
              'kcal': 350,
              'proteinGrams': 18,
              'carbsGrams': 32,
              'fatGrams': 7,
            },
          ],
        },
      }),
    });

    final log = await loadSavedDayLog();
    expect(log.totalsFor(0).consumed, 0);
    expect(log.totalsFor(1).consumed, 350);
    expect(log.entriesFor(1).single.dish, 'Dal + roti');
  });
}
