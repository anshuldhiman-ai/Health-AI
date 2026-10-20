import 'package:app/app/log_store.dart';
import 'package:app/domain/entities/log_entry.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/domain/entities/nutrition_targets.dart';
import 'package:app/data/preferences/goal_kind_controller.dart';
import 'package:app/features/today/application/today_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('adding a meal refreshes the dashboard totals immediately', () {
    final sampleLog = DayLog(
      initial: {
        0: [
          LogEntry.estimated(
            mealKind: MealKind.breakfast,
            dish: 'Poha + chai',
            kcal: 420,
            timeLabel: '8:15 AM',
          ),
          LogEntry.estimated(
            mealKind: MealKind.lunch,
            dish: 'Rajma chawal',
            kcal: 468,
            timeLabel: '1:10 PM',
          ),
          LogEntry.estimated(
            mealKind: MealKind.dinner,
            dish: 'Dal + roti',
            kcal: 350,
          ),
          LogEntry.estimated(
            mealKind: MealKind.snacks,
            dish: 'Roasted chana',
            kcal: 80,
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

    expect(container.read(todayStateProvider).caloriesConsumed, 1318);

    container
        .read(dayLogProvider.notifier)
        .add(
          LogEntry.estimated(
            mealKind: MealKind.lunch,
            dish: 'Chole bhature',
            kcal: 420,
          ),
        );

    expect(container.read(todayStateProvider).caloriesConsumed, 1738);
    expect(container.read(todayStateProvider).caloriesRemaining, 62);
  });

  test('changing the goal updates the ring and macro targets', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [initialGoalKindProvider.overrideWithValue(GoalKind.lose)],
    );
    addTearDown(container.dispose);

    expect(container.read(todayStateProvider).caloriesTarget, 1800);

    await container.read(goalKindProvider.notifier).select(GoalKind.gain);

    final state = container.read(todayStateProvider);
    expect(state.caloriesTarget, 2600);
    expect(state.macros.first.target, 140);
  });
}
