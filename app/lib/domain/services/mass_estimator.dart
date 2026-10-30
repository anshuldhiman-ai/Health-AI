import 'dart:math' as math;

import 'package:app/domain/entities/dish_record.dart';
import 'package:app/domain/services/volumetric_math.dart';

/// Role morphological height priors (AGENTS.md §6.2) in cm (P10, P50, P90).
class RoleHeightPrior {
  const RoleHeightPrior(this.p10, this.p50, this.p90);
  final double p10;
  final double p50;
  final double p90;
}

/// Production mass estimation engine in pure Dart (AGENTS.md §6.2, §6.3).
///
/// Implements physics prior × data-calibrated correction, outputting P10 / P50 / P90.
/// Parity guaranteed with ml/src/ml_pipeline/mass/reference.py.
class MassEstimator {
  const MassEstimator._();

  // Initial priors — PLACEHOLDER(T8.2), copied from AGENTS.md §6.2
  static const Map<Role, RoleHeightPrior> roleHeightPriors = {
    Role.gravyCurry: RoleHeightPrior(0.6, 1.0, 1.5),
    Role.moundedCarb: RoleHeightPrior(1.4, 2.0, 2.8),
    Role.drySabzi: RoleHeightPrior(1.0, 1.6, 2.4),
    Role.saladRaw: RoleHeightPrior(0.8, 1.2, 1.8),
    Role.condiment: RoleHeightPrior(0.5, 0.8, 1.2),
  };

  // Initial density priors in g/ml (g/cm³) — PLACEHOLDER(T8.2)
  static const Map<Role, double> roleDefaultDensities = {
    Role.gravyCurry: 1.05,
    Role.moundedCarb: 0.85,
    Role.drySabzi: 0.65,
    Role.saladRaw: 0.38,
    Role.condiment: 1.20,
    Role.flatBread: 0.72,
    Role.proteinPiece: 1.00,
    Role.otherFood: 0.90,
  };

  /// Estimates mass range (P10, P50, P90) in grams for food inside a spherical-cap katori.
  static Range estimateBowlMass({
    required double surfaceAreaCm2,
    required double rimRadiusCm,
    required double depthCm,
    double? densityGPerMl,
    Role role = Role.gravyCurry,
    double calibrationFactor = 1.0,
    double q10 = -0.15,
    double q50 = 0.0,
    double q90 = 0.15,
  }) {
    final density = densityGPerMl ?? roleDefaultDensities[role] ?? 1.05;
    final volumeMl = VolumetricMath.bowlVolumeMl(
      surfaceAreaCm2: surfaceAreaCm2,
      rimRadiusCm: rimRadiusCm,
      depthCm: depthCm,
    );

    final massPhysG = volumeMl * density;
    final base = massPhysG * calibrationFactor;

    return Range(
      p10: base * math.exp(q10),
      p50: base * math.exp(q50),
      p90: base * math.exp(q90),
    );
  }

  /// Estimates mass range (P10, P50, P90) in grams for food mounded or layered on a flat plate.
  static Range estimateMoundMass({
    required double areaCm2,
    required Role role,
    double? densityGPerMl,
    double? customHEffP10,
    double? customHEffP50,
    double? customHEffP90,
    double calibrationFactor = 1.0,
  }) {
    final density = densityGPerMl ?? roleDefaultDensities[role] ?? 0.85;
    final prior =
        roleHeightPriors[role] ?? const RoleHeightPrior(1.0, 1.5, 2.2);

    final h10 = customHEffP10 ?? prior.p10;
    final h50 = customHEffP50 ?? prior.p50;
    final h90 = customHEffP90 ?? prior.p90;

    final v10 = VolumetricMath.moundVolumeMl(
      areaCm2: areaCm2,
      effectiveHeightCm: h10,
    );
    final v50 = VolumetricMath.moundVolumeMl(
      areaCm2: areaCm2,
      effectiveHeightCm: h50,
    );
    final v90 = VolumetricMath.moundVolumeMl(
      areaCm2: areaCm2,
      effectiveHeightCm: h90,
    );

    return Range(
      p10: v10 * density * calibrationFactor,
      p50: v50 * density * calibrationFactor,
      p90: v90 * density * calibrationFactor,
    );
  }

  /// Estimates mass range (P10, P50, P90) in grams for piece-based foods (rotis, idlis, samosas).
  static Range estimatePieceMass({
    required int count,
    required double unitMassGrams,
    double? pieceAreaCm2,
    double? referencePieceAreaCm2,
    double calibrationFactor = 1.0,
    double q10 = -0.12,
    double q50 = 0.0,
    double q90 = 0.12,
  }) {
    final massPhysG = VolumetricMath.pieceMassGrams(
      count: count,
      unitMassGrams: unitMassGrams,
      pieceAreaCm2: pieceAreaCm2,
      referencePieceAreaCm2: referencePieceAreaCm2,
    );

    final base = massPhysG * calibrationFactor;
    return Range(
      p10: base * math.exp(q10),
      p50: base * math.exp(q50),
      p90: base * math.exp(q90),
    );
  }
}
