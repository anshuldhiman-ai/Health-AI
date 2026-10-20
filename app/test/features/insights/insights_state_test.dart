import 'package:app/app/log_store.dart';
import 'package:app/domain/entities/log_entry.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/features/insights/application/insights_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('range chips drive different trend windows over real history', () {
    final sampleLog = DayLog(
      initial: {
        for (var i = 0; i < 90; i++)
          i: [
            LogEntry.estimated(
              mealKind: MealKind.lunch,
              dish: 'Lunch',
              kcal: 1400,
            ),
          ],
      },
    );
    final container = ProviderContainer(
      overrides: [
        dayLogProvider.overrideWith((ref) => sampleLog),
      ],
    );
    addTearDown(container.dispose);

    final week = container.read(insightsStateProvider);
    expect(week.rangeDays, 7);
    expect(week.trend, hasLength(7));
    expect(week.avgKcalPerDay, greaterThan(0));

    container.read(insightsRangeProvider.notifier).state = 30;
    final month = container.read(insightsStateProvider);
    expect(month.rangeDays, 30);
    expect(month.trend, hasLength(30));
    expect(month.avgKcalPerDay, greaterThan(0));

    container.read(insightsRangeProvider.notifier).state = 90;
    final quarter = container.read(insightsStateProvider);
    expect(quarter.rangeDays, 90);
    expect(quarter.trend, hasLength(90));
    expect(quarter.avgKcalPerDay, greaterThan(0));
  });
}
