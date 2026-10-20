// Portion maths shared by scan results and manual dish search. Pure-Dart
// (R9), so both flows use exactly the same calorie range.
library;

import 'dart:math' as math;

import 'package:app/domain/entities/dish_info.dart';

/// One serving preset with the macros and honest calorie range for that
/// portion. The range reflects portion uncertainty (±12%).
class FoodPortion {
  const FoodPortion({
    required this.label,
    required this.grams,
    required this.lowKcal,
    required this.highKcal,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  final String label;
  final int grams;
  final int lowKcal;
  final int highKcal;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;

  int get midKcal => ((lowKcal + highKcal) / 2).round();
}

const _kcalLowFactor = 0.88;
const _kcalHighFactor = 1.12;

List<FoodPortion> portionOptionsFor(DishInfo dish) {
  return [
    for (final preset in dish.servings)
      () {
        final macros = dish.per100g.forGrams(preset.grams);
        final kcal = macros.kcal;
        return FoodPortion(
          label: preset.label,
          grams: preset.grams,
          lowKcal: math.max(1, (kcal * _kcalLowFactor).round()),
          highKcal: math.max(2, (kcal * _kcalHighFactor).round()),
          proteinGrams: macros.protein.round(),
          carbsGrams: macros.carbs.round(),
          fatGrams: macros.fat.round(),
        );
      }(),
  ];
}
