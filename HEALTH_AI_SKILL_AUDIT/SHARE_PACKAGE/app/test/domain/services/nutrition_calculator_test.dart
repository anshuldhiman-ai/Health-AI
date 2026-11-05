import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:app/domain/entities/dish_record.dart';
import 'package:app/domain/services/nutrition_calculator.dart';

void main() {
  group('NutritionCalculator - Atwater Sanity Checks', () {
    test('passes Atwater check when 4P + 4C + 9F is within ±12% of kcal', () {
      // Dal Tadka: 118 kcal, P: 6.1g, C: 15.8g, F: 3.2g
      // 4*(6.1) + 4*(15.8) + 9*(3.2) = 24.4 + 63.2 + 28.8 = 116.4 kcal (diff: 1.3%)
      const dal = NutritionPer100g(
        kcal: 118.0,
        proteinG: 6.1,
        carbG: 15.8,
        fatG: 3.2,
      );
      expect(NutritionCalculator.isAtwaterCompliant(dal), isTrue);
      expect(
        NutritionCalculator.atwaterRelativeError(dal),
        closeTo(0.0135, 0.002),
      );
    });

    test('fails Atwater check when values deviate beyond ±12%', () {
      const corrupt = NutritionPer100g(
        kcal: 300.0,
        proteinG: 5.0,
        carbG: 10.0,
        fatG: 5.0, // Expected: 4*5 + 4*10 + 9*5 = 105 kcal, but catalog claims 300 kcal!
      );
      expect(NutritionCalculator.isAtwaterCompliant(corrupt), isFalse);
    });
  });

  group('NutritionCalculator - Variant Adjustments', () {
    const base = NutritionPer100g(
      kcal: 120.0,
      proteinG: 6.0,
      carbG: 14.0,
      fatG: 4.0,
    );

    test('home_regular (fatDelta = 0) leaves nutrition unchanged', () {
      const variant = DishVariant(id: 'home_regular', fatDeltaGPer100g: 0.0);
      final adj = NutritionCalculator.applyVariant(base, variant);

      expect(adj.kcal, closeTo(120.0, 1e-4));
      expect(adj.fatG, closeTo(4.0, 1e-4));
      expect(adj.proteinG, closeTo(6.0, 1e-4));
      expect(adj.carbG, closeTo(14.0, 1e-4));
    });

    test('home_light_oil (fatDelta = -1.5) reduces fat and energy density by 9 kcal/g', () {
      const variant = DishVariant(id: 'home_light_oil', fatDeltaGPer100g: -1.5);
      final adj = NutritionCalculator.applyVariant(base, variant);

      expect(adj.fatG, closeTo(2.5, 1e-4));
      // 120 - (1.5 * 9) = 106.5 kcal
      expect(adj.kcal, closeTo(106.5, 1e-4));
      expect(adj.proteinG, closeTo(6.0, 1e-4));
      expect(adj.carbG, closeTo(14.0, 1e-4));
    });

    test(
      'restaurant_rich (fatDelta = +3.5) increases fat and energy density',
      () {
        const variant = DishVariant(
          id: 'restaurant_rich',
          fatDeltaGPer100g: 3.5,
        );
        final adj = NutritionCalculator.applyVariant(base, variant);

        expect(adj.fatG, closeTo(7.5, 1e-4));
        // 120 + (3.5 * 9) = 151.5 kcal
        expect(adj.kcal, closeTo(151.5, 1e-4));
      },
    );

    test('negative fat delta clamps fat and calories at zero without negative values', () {
      const variant = DishVariant(id: 'zero_oil', fatDeltaGPer100g: -20.0);
      final adj = NutritionCalculator.applyVariant(base, variant);

      expect(adj.fatG, equals(0.0));
      // Base without fat = 120 - (4 * 9) = 84 kcal
      expect(adj.kcal, closeTo(84.0, 1e-4));
    });
  });

  group('NutritionCalculator - Item Nutrition Scaling', () {
    const nutrition = NutritionPer100g(
      kcal: 100.0,
      proteinG: 10.0,
      carbG: 10.0,
      fatG: 2.0,
    );
    const grams = Range(p10: 100.0, p50: 150.0, p90: 200.0);

    test('scales calories and macros across P10/P50/P90 ranges', () {
      final res = NutritionCalculator.calculateItemNutrition(
        baseNutrition: nutrition,
        grams: grams,
      );

      // P10: 100g => 100 kcal, P: 10g, C: 10g, F: 2g
      expect(res.kcal.p10, closeTo(100.0, 1e-4));
      expect(res.macros.proteinG.p10, closeTo(10.0, 1e-4));
      expect(res.macros.carbG.p10, closeTo(10.0, 1e-4));
      expect(res.macros.fatG.p10, closeTo(2.0, 1e-4));

      // P50: 150g => 150 kcal, P: 15g, C: 15g, F: 3g
      expect(res.kcal.p50, closeTo(150.0, 1e-4));
      expect(res.macros.proteinG.p50, closeTo(15.0, 1e-4));
      expect(res.macros.carbG.p50, closeTo(15.0, 1e-4));
      expect(res.macros.fatG.p50, closeTo(3.0, 1e-4));

      // P90: 200g => 200 kcal, P: 20g, C: 20g, F: 4g
      expect(res.kcal.p90, closeTo(200.0, 1e-4));
      expect(res.macros.proteinG.p90, closeTo(20.0, 1e-4));
      expect(res.macros.carbG.p90, closeTo(20.0, 1e-4));
      expect(res.macros.fatG.p90, closeTo(4.0, 1e-4));
    });
  });

  group('NutritionCalculator - Meal Total Monte-Carlo Aggregation', () {
    test('aggregates multiple items with shared plate scale variance', () {
      // Dish 1: 150g P50 (120 - 180), 100 kcal / 100g => ~150 kcal
      // Dish 2: 200g P50 (160 - 240), 150 kcal / 100g => ~300 kcal
      // Expected total: ~450 kcal
      final items = [
        const DishItemInput(
          grams: Range(p10: 120.0, p50: 150.0, p90: 180.0),
          nutrition: NutritionPer100g(
            kcal: 100.0,
            proteinG: 5.0,
            carbG: 15.0,
            fatG: 2.0,
          ),
        ),
        const DishItemInput(
          grams: Range(p10: 160.0, p50: 200.0, p90: 240.0),
          nutrition: NutritionPer100g(
            kcal: 150.0,
            proteinG: 10.0,
            carbG: 20.0,
            fatG: 3.0,
          ),
        ),
      ];

      final total = NutritionCalculator.calculateMealTotal(
        items: items,
        sharedPlateScaleSigma: 0.05,
        sampleCount: 500,
        random: math.Random(42),
      );

      // P50 should be within 3% of deterministic sum (150 + 300 = 450 kcal)
      expect(total.kcal.p50, closeTo(450.0, 15.0));
      expect(total.kcal.p10, lessThan(total.kcal.p50));
      expect(total.kcal.p90, greaterThan(total.kcal.p50));

      // Total Protein: 1.5*5 + 2.0*10 = 7.5 + 20 = 27.5g
      expect(total.macros.proteinG.p50, closeTo(27.5, 2.0));
    });

    test('handles empty item list gracefully with zero ranges', () {
      final total = NutritionCalculator.calculateMealTotal(items: []);
      expect(total.kcal.p50, equals(0.0));
      expect(total.macros.proteinG.p50, equals(0.0));
    });
  });
}
