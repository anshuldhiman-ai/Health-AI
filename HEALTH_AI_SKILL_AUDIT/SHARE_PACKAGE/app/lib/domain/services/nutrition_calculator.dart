import 'dart:math' as math;

import 'package:app/domain/entities/dish_record.dart';

/// Item input representation for meal-wide nutrition aggregation.
class DishItemInput {
  const DishItemInput({
    required this.grams,
    required this.nutrition,
    this.variant,
  });

  final Range grams;
  final NutritionPer100g nutrition;
  final DishVariant? variant;
}

/// Pure Dart service for food nutrition calculations, variant adjustments,
/// Atwater sanity validation, and Monte-Carlo meal uncertainty aggregation (AGENTS.md §5.2, §6.2).
class NutritionCalculator {
  const NutritionCalculator._();

  /// Z-score for 90th percentile in standard normal distribution (nominal 80% coverage interval).
  static const double _z90 = 1.2815515655;

  /// Evaluates whether the declared caloric content complies with the Atwater factor
  /// 4P + 4C + 9F within the acceptable relative tolerance (default ±12% per AGENTS.md §5.2).
  static bool isAtwaterCompliant(
    NutritionPer100g nutrition, {
    double tolerance = 0.12,
  }) {
    if (nutrition.kcal <= 0.0) {
      return nutrition.atwaterKcal <= 1e-3;
    }
    return atwaterRelativeError(nutrition) <= tolerance;
  }

  /// Returns the absolute relative discrepancy between declared kcal and theoretical Atwater kcal.
  static double atwaterRelativeError(NutritionPer100g nutrition) {
    if (nutrition.kcal <= 0.0) return 0.0;
    return (nutrition.kcal - nutrition.atwaterKcal).abs() / nutrition.kcal;
  }

  /// Derives adjusted nutrition per 100g when applying a cooking variant (AGENTS.md §5.2).
  ///
  /// Adjusts fat by [DishVariant.fatDeltaGPer100g] (clamped at >= 0g) and shifts
  /// kcal by exactly 9.0 kcal per gram of fat delta.
  static NutritionPer100g applyVariant(
    NutritionPer100g base,
    DishVariant variant,
  ) {
    final adjustedFat = math.max(0.0, base.fatG + variant.fatDeltaGPer100g);
    final fatDelta = adjustedFat - base.fatG;
    final adjustedKcal = math.max(0.0, base.kcal + (fatDelta * 9.0));

    return NutritionPer100g(
      kcal: adjustedKcal,
      proteinG: base.proteinG,
      carbG: base.carbG,
      fatG: adjustedFat,
      fiberG: base.fiberG,
      sugarG: base.sugarG,
      sodiumMg: base.sodiumMg,
    );
  }

  /// Scales per-100g nutrition by an item's estimated mass range (P10 / P50 / P90 grams).
  static DishNutritionResult calculateItemNutrition({
    required NutritionPer100g baseNutrition,
    required Range grams,
    DishVariant? variant,
  }) {
    final effective = variant != null
        ? applyVariant(baseNutrition, variant)
        : baseNutrition;

    Range scale(double per100g) {
      return Range(
        p10: (grams.p10 * per100g) / 100.0,
        p50: (grams.p50 * per100g) / 100.0,
        p90: (grams.p90 * per100g) / 100.0,
      );
    }

    return DishNutritionResult(
      kcal: scale(effective.kcal),
      macros: Macros(
        proteinG: scale(effective.proteinG),
        carbG: scale(effective.carbG),
        fatG: scale(effective.fatG),
      ),
    );
  }

  /// Calculates meal total nutrition and uncertainty ranges using Monte-Carlo simulation (AGENTS.md §6.2).
  ///
  /// Accounts for correlated uncertainty across items caused by shared plate scale error
  /// ([sharedPlateScaleSigma]), plus independent per-item mass variations.
  static DishNutritionResult calculateMealTotal({
    required List<DishItemInput> items,
    double sharedPlateScaleSigma = 0.05,
    int sampleCount = 500,
    math.Random? random,
  }) {
    if (items.isEmpty) {
      const zeroRange = Range(p10: 0.0, p50: 0.0, p90: 0.0);
      return const DishNutritionResult(
        kcal: zeroRange,
        macros: Macros(proteinG: zeroRange, carbG: zeroRange, fatG: zeroRange),
      );
    }

    final rand = random ?? math.Random();

    // Prepare item distributions and per-100g values
    final itemMus = <double>[];
    final itemSigmaIndeps = <double>[];
    final effectiveNutritions = <NutritionPer100g>[];

    final sharedVar = sharedPlateScaleSigma * sharedPlateScaleSigma;

    for (final item in items) {
      final eff = item.variant != null
          ? applyVariant(item.nutrition, item.variant!)
          : item.nutrition;
      effectiveNutritions.add(eff);

      final p10 = math.max(1e-2, item.grams.p10);
      final p50 = math.max(1e-2, item.grams.p50);
      final p90 = math.max(p50, item.grams.p90);

      final mu = math.log(p50);
      final totalSigma = (math.log(p90) - math.log(p10)) / (2.0 * _z90);
      final indepVar = math.max(0.0, (totalSigma * totalSigma) - sharedVar);

      itemMus.add(mu);
      itemSigmaIndeps.add(math.sqrt(indepVar));
    }

    final kcalSamples = List<double>.filled(sampleCount, 0.0);
    final proteinSamples = List<double>.filled(sampleCount, 0.0);
    final carbSamples = List<double>.filled(sampleCount, 0.0);
    final fatSamples = List<double>.filled(sampleCount, 0.0);

    for (int k = 0; k < sampleCount; k++) {
      final zShared = _sampleStandardNormal(rand);
      double sampleKcal = 0.0;
      double sampleProtein = 0.0;
      double sampleCarb = 0.0;
      double sampleFat = 0.0;

      for (int i = 0; i < items.length; i++) {
        final zIndep = _sampleStandardNormal(rand);
        final logMass =
            itemMus[i] +
            (sharedPlateScaleSigma * zShared) +
            (itemSigmaIndeps[i] * zIndep);
        final mass = math.exp(logMass);

        final eff = effectiveNutritions[i];
        sampleKcal += (mass * eff.kcal) / 100.0;
        sampleProtein += (mass * eff.proteinG) / 100.0;
        sampleCarb += (mass * eff.carbG) / 100.0;
        sampleFat += (mass * eff.fatG) / 100.0;
      }

      kcalSamples[k] = sampleKcal;
      proteinSamples[k] = sampleProtein;
      carbSamples[k] = sampleCarb;
      fatSamples[k] = sampleFat;
    }

    kcalSamples.sort();
    proteinSamples.sort();
    carbSamples.sort();
    fatSamples.sort();

    Range quantiles(List<double> sorted) {
      final p10Idx = ((sorted.length - 1) * 0.10).round();
      final p50Idx = ((sorted.length - 1) * 0.50).round();
      final p90Idx = ((sorted.length - 1) * 0.90).round();
      return Range(
        p10: sorted[p10Idx],
        p50: sorted[p50Idx],
        p90: sorted[p90Idx],
      );
    }

    return DishNutritionResult(
      kcal: quantiles(kcalSamples),
      macros: Macros(
        proteinG: quantiles(proteinSamples),
        carbG: quantiles(carbSamples),
        fatG: quantiles(fatSamples),
      ),
    );
  }

  /// Box-Muller transform to generate standard normal variate N(0, 1).
  static double _sampleStandardNormal(math.Random rand) {
    double u1 = rand.nextDouble();
    while (u1 <= 1e-12) {
      u1 = rand.nextDouble();
    }
    final u2 = rand.nextDouble();
    return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
  }
}
