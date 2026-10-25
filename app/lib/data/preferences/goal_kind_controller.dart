import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/data/local_storage.dart';
import 'package:app/domain/entities/nutrition_targets.dart';

/// Storage key for the selected daily plan.
const goalKindPrefsKey = 'goal_kind';

Future<GoalKind> loadSavedGoalKind() async {
  try {
    return goalKindFromName(await AppLocalStorage.readString(goalKindPrefsKey));
  } catch (_) {
    return GoalKind.lose;
  }
}

/// Resolved before `runApp`; overridden in `main`.
final initialGoalKindProvider = Provider<GoalKind>((ref) => GoalKind.lose);

/// One selected plan drives the calorie ring, macro meters and diary.
final goalKindProvider = NotifierProvider<GoalKindController, GoalKind>(
  GoalKindController.new,
);

final nutritionTargetsProvider = Provider<NutritionTargets>(
  (ref) => targetsForGoal(ref.watch(goalKindProvider)),
);

class GoalKindController extends Notifier<GoalKind> {
  @override
  GoalKind build() => ref.watch(initialGoalKindProvider);

  Future<void> select(GoalKind kind) async {
    if (kind == state) return;
    state = kind;
    try {
      await AppLocalStorage.writeString(goalKindPrefsKey, kind.name);
    } catch (_) {
      // Persistence is best-effort; the current session still updates.
    }
  }
}
