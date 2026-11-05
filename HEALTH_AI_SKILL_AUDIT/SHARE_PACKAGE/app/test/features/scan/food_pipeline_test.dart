import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:app/features/scan/application/food_recognizer.dart';
import 'package:app/features/scan/application/scan_state.dart';
import 'package:app/domain/entities/dish_info.dart';
import 'package:app/domain/entities/food_portion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<DishCatalog> loadCatalog() async {
    final raw = await rootBundle.loadString(
      'assets/nutrition/khana_catalog.json',
    );
    return DishCatalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  test('catalog covers the exported label set and is complete', () async {
    final labelsRaw = await rootBundle.loadString('assets/models/labels.json');
    final labels =
        (jsonDecode(labelsRaw) as Map<String, dynamic>)['classes']
            as List<dynamic>;
    final catalog = await loadCatalog();

    // The catalog's own order is the taxonomy order; the model output
    // order lives in labels.json. The app maps a model index to a dish
    // by NAME, so every label must be present in the catalog.
    expect(catalog.classes.length, greaterThanOrEqualTo(80));
    for (final id in labels) {
      expect(
        catalog.classes.contains(id as String),
        isTrue,
        reason: 'catalog has no class row for $id',
      );
    }

    for (final id in labels) {
      final dish = catalog[id as String];
      expect(dish, isNotNull, reason: 'missing catalog row for $id');
      expect(dish!.name, isNotEmpty);
      expect(dish.ingredients, isNotEmpty);
      expect(dish.servings, isNotEmpty);
      expect(dish.per100g.kcal, greaterThan(0));
      for (final preset in dish.servings) {
        expect(preset.grams, greaterThan(0));
        expect(preset.label, isNotEmpty);
      }
    }
  });

  test('serving ranges bracket the catalog midpoint; macros scale', () async {
    final catalog = await loadCatalog();
    final dish = catalog['paneer masala']!;
    final options = portionOptionsFor(dish);

    expect(options, isNotEmpty);
    for (final option in options) {
      expect(option.lowKcal, lessThan(option.midKcal));
      expect(option.midKcal, lessThan(option.highKcal));
      expect(option.midKcal, ((option.lowKcal + option.highKcal) / 2).round());
    }

    final serving = options.first;
    final expected = dish.per100g.forGrams(serving.grams);
    expect(serving.proteinGrams, expected.protein.round());
    expect(serving.carbsGrams, expected.carbs.round());
    expect(serving.fatGrams, expected.fat.round());
  });

  test('scan session keeps unknown labels and supports selection', () async {
    final catalog = await loadCatalog();
    final session = scanSessionFrom(
      output: const RecognitionOutput(
        top: [
          DishScore(label: 'paneer masala', confidence: 0.62),
          DishScore(label: 'chole bhature', confidence: 0.21),
          DishScore(label: 'not-a-real-dish', confidence: 0.1),
        ],
        uncertain: true,
        ratio: 2.9,
        usedTta: true,
        latencyMs: 220,
      ),
      catalog: catalog,
      photo: Uint8List(4),
    );

    // A label the catalog has no row for is still surfaced: dropping
    // it silently hides a correct answer.
    expect(session.topMatches, hasLength(3));
    expect(session.topMatches.first.label, 'Paneer Masala');
    expect(session.topMatches.last.dish.hasNutritionData, isFalse);
    expect(session.uncertain, isTrue);
    expect(session.usedTta, isTrue);

    final switched = session.selectMatch(1);
    expect(switched.chosenPrediction.label, 'Chole Bhature');
    expect(switched.selectedServing, 0);
    expect(switched.servings, isNotEmpty);
  });

  test('preprocessing yields 224x224 NHWC RGB floats in 0..1', () {
    final source = img.Image(width: 300, height: 300);
    img.fill(source, color: img.ColorRgb8(255, 0, 0));
    final bytes = Uint8List.fromList(img.encodePng(source));

    final tensor = preprocessFoodPhoto(bytes);

    expect(tensor, hasLength(224 * 224 * 3));
    // First pixel is pure red, encoded R,G,B.
    expect(tensor[0], closeTo(1.0, 1e-6));
    expect(tensor[1], closeTo(0.0, 1e-6));
    expect(tensor[2], closeTo(0.0, 1e-6));
    // Last pixel too (all rows present).
    const last = (224 * 224 - 1) * 3;
    expect(tensor[last], closeTo(1.0, 1e-6));
  });

  test('horizontal flip TTA mirrors the left/right halves', () {
    final source = img.Image(width: 300, height: 300);
    img.fill(source, color: img.ColorRgb8(255, 0, 0));
    img.fillRect(
      source,
      x1: 150,
      y1: 0,
      x2: 299,
      y2: 299,
      color: img.ColorRgb8(0, 0, 255),
    );
    final tensor = preprocessFoodPhoto(
      Uint8List.fromList(img.encodePng(source)),
    );

    // Centre crop keeps the boundary: left is red, right is blue.
    expect(tensor[0], closeTo(1.0, 1e-6));
    const last = (224 * 224 - 1) * 3;
    expect(tensor[last + 2], closeTo(1.0, 1e-6));

    final flipped = flipHorizontally(tensor);
    expect(flipped[0], closeTo(0.0, 1e-6));
    expect(flipped[2], closeTo(1.0, 1e-6));
    expect(flipped[last], closeTo(1.0, 1e-6));
    expect(flipped[last + 2], closeTo(0.0, 1e-6));
  });

  group('TopConfidence', () {
    test('summarises the three best classes regardless of order', () {
      final c = TopConfidence.fromProbabilities([0.2, 0.5, 0.15, 0.05]);

      expect(c.top1, closeTo(0.5, 1e-12));
      expect(c.top2, closeTo(0.2, 1e-12));
      expect(c.top3Mass, closeTo(0.85, 1e-12));
      expect(c.ratio, closeTo(2.5, 1e-12));
    });

    test('a near-zero runner-up clamps the ratio instead of dividing by 0', () {
      final c = TopConfidence.fromProbabilities([0.9, 0.0, 0.0]);

      expect(c.ratio, 1e9);
      expect(c.ratio.isFinite, isTrue);
    });

    test('an empty distribution is not food', () {
      final c = TopConfidence.fromProbabilities(const []);

      expect(c.isLikelyFood, isFalse);
    });

    test('a clear dish reads as food and as certain', () {
      final c = TopConfidence.fromProbabilities([
        0.62,
        0.21,
        0.09,
        0.04,
        0.02,
        0.02,
      ]);

      expect(c.isLikelyFood, isTrue);
      expect(c.isUncertain, isFalse);
    });

    test('a flat distribution reads as not-food', () {
      // An empty wall or a keyboard: nothing wins, and the mass is
      // smeared across unrelated classes.
      final c = TopConfidence.fromProbabilities([
        0.06,
        0.055,
        0.05,
        0.048,
        0.047,
        0.045,
        0.04,
      ]);

      expect(c.isLikelyFood, isFalse);
    });

    test('a structured non-food object reads as not-food', () {
      // A pet or a piece of furniture: one class leads, but the mass is
      // still spread too thin to claim a dish.
      final c = TopConfidence.fromProbabilities([0.22, 0.15, 0.10, 0.07]);

      expect(c.top1, greaterThanOrEqualTo(0.20));
      expect(c.isLikelyFood, isFalse);
    });

    test('two look-alike dishes stay food, and are flagged uncertain', () {
      // Dal tadka vs dal makhani. A near-tie between two dishes is
      // evidence of food, not of a keyboard: the answer is "which one?",
      // so this must reach the result sheet, not the not-food dialog.
      final c = TopConfidence.fromProbabilities([0.31, 0.30, 0.05, 0.03]);

      expect(c.isLikelyFood, isTrue);
      expect(c.isUncertain, isTrue);
    });

    test('a distinctive dish is food even with little mass behind it', () {
      // One class far ahead of everything else is food evidence on its
      // own, and rescues a picture the top-3 mass floor would reject.
      final c = TopConfidence.fromProbabilities([0.25, 0.08, 0.06, 0.05]);

      expect(c.top3Mass, lessThan(0.55));
      expect(c.isLikelyFood, isTrue);
    });
  });

  test('scan session carries the non-food verdict through selection', () async {
    final catalog = await loadCatalog();
    final session = scanSessionFrom(
      output: const RecognitionOutput(
        top: [DishScore(label: 'paneer masala', confidence: 0.22)],
        uncertain: true,
        ratio: 1.1,
        usedTta: true,
        latencyMs: 180,
        isFood: false,
      ),
      catalog: catalog,
      photo: Uint8List(4),
    );

    // The camera gates on this before opening the sheet; selection must
    // not quietly turn a rejection into an acceptable result.
    expect(session.isFood, isFalse);
    expect(session.selectMatch(0).isFood, isFalse);
    expect(session.selectServing(0).isFood, isFalse);
  });
}
