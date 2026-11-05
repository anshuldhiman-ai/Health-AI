import 'package:app/domain/entities/nutrition_targets.dart';
import 'package:app/data/preferences/goal_kind_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('goal plans provide the documented calorie and macro targets', () {
    final lose = targetsForGoal(GoalKind.lose);
    expect(lose.kcal, 1800);
    expect(lose.protein, 100);

    final maintain = targetsForGoal(GoalKind.maintain);
    expect(maintain.kcal, 2200);

    final gain = targetsForGoal(GoalKind.gain);
    expect(gain.kcal, 2600);

    expect(goalKindFromName('gain'), GoalKind.gain);
    expect(goalKindFromName(null), GoalKind.lose);
  });

  test('selecting a plan updates targets and persists it', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [initialGoalKindProvider.overrideWithValue(GoalKind.lose)],
    );
    addTearDown(container.dispose);

    expect(container.read(nutritionTargetsProvider).kcal, 1800);

    await container.read(goalKindProvider.notifier).select(GoalKind.gain);

    expect(container.read(goalKindProvider), GoalKind.gain);
    expect(container.read(nutritionTargetsProvider).kcal, 2600);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(goalKindPrefsKey), 'gain');
  });

  test('loadSavedGoalKind reads the stored plan', () async {
    SharedPreferences.setMockInitialValues({goalKindPrefsKey: 'maintain'});
    expect(await loadSavedGoalKind(), GoalKind.maintain);
  });
}
