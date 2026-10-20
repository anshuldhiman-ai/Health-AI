/// Daily nutrition targets for the three supported goal plans.
///
/// The values are the product defaults from the spec (Section 6.1),
/// not medical advice. A later onboarding flow can personalise them;
/// the UI reads them through `nutritionTargetsProvider`.
library;

enum GoalKind { lose, maintain, gain }

class NutritionTargets {
  const NutritionTargets({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
}

/// Default plans. Macro grams are chosen so the macros roughly fill
/// each calorie target (fibre and rounding account for the remainder).
NutritionTargets targetsForGoal(GoalKind kind) => switch (kind) {
  GoalKind.lose => const NutritionTargets(
    kcal: 1800,
    protein: 100,
    carbs: 180,
    fat: 60,
  ),
  GoalKind.maintain => const NutritionTargets(
    kcal: 2200,
    protein: 120,
    carbs: 250,
    fat: 70,
  ),
  GoalKind.gain => const NutritionTargets(
    kcal: 2600,
    protein: 140,
    carbs: 300,
    fat: 85,
  ),
};

GoalKind goalKindFromName(String? name) => switch (name) {
  'maintain' => GoalKind.maintain,
  'gain' => GoalKind.gain,
  _ => GoalKind.lose,
};
