// Domain entities for nutrition, ranges, and detected dish items (AGENTS.md §5.2, §5.3).

class Range {
  const Range({required this.p10, required this.p50, required this.p90});

  final double p10;
  final double p50;
  final double p90;

  @override
  String toString() => 'Range(p10: $p10, p50: $p50, p90: $p90)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Range &&
          runtimeType == other.runtimeType &&
          (p10 - other.p10).abs() < 1e-4 &&
          (p50 - other.p50).abs() < 1e-4 &&
          (p90 - other.p90).abs() < 1e-4;

  @override
  int get hashCode => Object.hash(p10, p50, p90);
}

class Macros {
  const Macros({
    required this.proteinG,
    required this.carbG,
    required this.fatG,
  });

  final Range proteinG;
  final Range carbG;
  final Range fatG;

  @override
  String toString() =>
      'Macros(P: ${proteinG.p50}g, C: ${carbG.p50}g, F: ${fatG.p50}g)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Macros &&
          runtimeType == other.runtimeType &&
          proteinG == other.proteinG &&
          carbG == other.carbG &&
          fatG == other.fatG;

  @override
  int get hashCode => Object.hash(proteinG, carbG, fatG);
}

enum Role {
  background,
  plateTray,
  bowl,
  moundedCarb,
  flatBread,
  gravyCurry,
  drySabzi,
  saladRaw,
  condiment,
  proteinPiece,
  otherFood,
}

enum ConfidenceFlag {
  lowSegConf,
  occluded,
  geometryConflict,
  unknownDish,
  userEdited,
}

/// Baseline cooked nutrition per 100 grams (AGENTS.md §5.2).
class NutritionPer100g {
  const NutritionPer100g({
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    this.fiberG = 0.0,
    this.sugarG = 0.0,
    this.sodiumMg = 0.0,
  });

  final double kcal;
  final double proteinG;
  final double carbG;
  final double fatG;
  final double fiberG;
  final double sugarG;
  final double sodiumMg;

  /// Theoretical Atwater caloric value (4P + 4C + 9F).
  double get atwaterKcal => (4.0 * proteinG) + (4.0 * carbG) + (9.0 * fatG);

  @override
  String toString() =>
      'NutritionPer100g(kcal: $kcal, P: ${proteinG}g, C: ${carbG}g, F: ${fatG}g)';
}

/// Cooking variant modifying fat and energy density (AGENTS.md §5.2).
class DishVariant {
  const DishVariant({required this.id, required this.fatDeltaGPer100g});

  final String id;
  final double fatDeltaGPer100g;

  @override
  String toString() => 'DishVariant($id, fatDelta: $fatDeltaGPer100g)';
}

/// Calculated nutrition ranges for a single food item or total meal.
class DishNutritionResult {
  const DishNutritionResult({required this.kcal, required this.macros});

  final Range kcal;
  final Macros macros;

  @override
  String toString() =>
      'DishNutritionResult(kcal: ${kcal.p50}, P: ${macros.proteinG.p50}g, C: ${macros.carbG.p50}g, F: ${macros.fatG.p50}g)';
}
