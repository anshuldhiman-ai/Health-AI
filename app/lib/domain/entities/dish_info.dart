/// Dish knowledge from the bundled catalog: per-100 g macros, key
/// ingredients and honest serving presets. Pure Dart (R9).
library;

/// Nutrition per 100 g of the cooked dish. Values are plausible
/// estimates, not lab measurements; the UI always shows a range.
class DishMacros {
  const DishMacros({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory DishMacros.fromJson(Map<String, dynamic> json) => DishMacros(
    kcal: (json['kcal'] as num).toDouble(),
    protein: (json['protein'] as num).toDouble(),
    carbs: (json['carbs'] as num).toDouble(),
    fat: (json['fat'] as num).toDouble(),
  );

  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  /// Scaled macros for a portion. Kept as doubles so rounding happens
  /// once, at the UI boundary.
  ({double kcal, double protein, double carbs, double fat}) forGrams(
    int grams,
  ) {
    final factor = grams / 100.0;
    return (
      kcal: kcal * factor,
      protein: protein * factor,
      carbs: carbs * factor,
      fat: fat * factor,
    );
  }
}

class ServingPreset {
  const ServingPreset({required this.label, required this.grams});

  factory ServingPreset.fromJson(Map<String, dynamic> json) => ServingPreset(
    label: json['label'] as String,
    grams: (json['grams'] as num).round(),
  );

  final String label;
  final int grams;
}

/// One Khana class plus its nutrition/ingredient knowledge.
class DishInfo {
  const DishInfo({
    required this.id,
    required this.name,
    required this.family,
    required this.ingredients,
    required this.per100g,
    required this.servings,
  });

  /// The model label (lower-case Khana class id).
  factory DishInfo.fromJson(String id, Map<String, dynamic> json) => DishInfo(
    id: id,
    name: json['name'] as String,
    family: json['family'] as String,
    ingredients: (json['ingredients'] as List<dynamic>)
        .map((e) => e as String)
        .toList(growable: false),
    per100g: DishMacros.fromJson(json['per100g'] as Map<String, dynamic>),
    servings: (json['servings'] as List<dynamic>)
        .map((e) => ServingPreset.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );

  final String id;

  /// Display name.
  final String name;

  /// Cuisine/format family (curry, rice, bread, ...). Used by the
  /// fallback to recognise nutritionally-equivalent candidates.
  final String family;

  /// Key ingredients, shown to help the user verify a low-confidence
  /// prediction (single-model ingredient fallback).
  final List<String> ingredients;

  final DishMacros per100g;
  final List<ServingPreset> servings;
}

/// The dish catalog: every class the app can label, plus its nutrition
/// knowledge.
///
/// The class ORDER here is the catalog's own (sorted) taxonomy order. It
/// is NOT the model output order: that lives in
/// `assets/models/labels.json`, and a model output index is mapped to a
/// dish by NAME (`labels.json[index]` -> `catalog[label]`). Never
/// index into [classes] with a model output index.
class DishCatalog {
  const DishCatalog({required this.classes, required this.dishes});

  factory DishCatalog.fromJson(Map<String, dynamic> json) {
    final dishesJson = json['dishes'] as Map<String, dynamic>;
    return DishCatalog(
      classes: (json['classes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(growable: false),
      dishes: {
        for (final entry in dishesJson.entries)
          entry.key: DishInfo.fromJson(
            entry.key,
            entry.value as Map<String, dynamic>,
          ),
      },
    );
  }

  /// Every class in the catalog, sorted. See the class docs: this is
  /// the taxonomy order, not the model output order.
  final List<String> classes;
  final Map<String, DishInfo> dishes;

  /// Look a dish up by its model label.
  DishInfo? operator [](String label) => dishes[label];
}
