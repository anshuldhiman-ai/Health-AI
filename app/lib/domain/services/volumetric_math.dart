import 'dart:math' as math;

/// Pure Dart volumetric mathematics for food portion estimation (AGENTS.md §6.2).
///
/// Implements:
/// 1. BOWL Mode (food inside a katori):
///    Spherical-cap bowl model with rim radius a_c and depth d_c:
///      R   = (a_c² + d_c²) / (2·d_c)             (sphere radius)
///      r_s = sqrt(A_surface / π)                 (contents surface radius)
///      h   = R − sqrt(R² − r_s²)                 (fill depth, clamped r_s <= a_c)
///      V   = π·h²·(3R − h) / 3                   (spherical cap volume in ml)
///
/// 2. LAYER / MOUND Mode (food on the plate):
///      V   = A_cm² × h_eff                       (volume in ml)
///
/// 3. PIECE Mode (roti, idli, vada, egg, samosa…):
///      m   = n × unit_mass × clamp(A_piece / A_ref, 0.6, 1.5)
class VolumetricMath {
  const VolumetricMath._();

  /// Calculates the sphere radius of a spherical-cap bowl with rim radius [rimRadiusCm]
  /// and depth [depthCm]: R = (a_c² + d_c²) / (2 * d_c).
  static double bowlSphereRadius({
    required double rimRadiusCm,
    required double depthCm,
  }) {
    if (depthCm <= 0) return 0.0;
    return (rimRadiusCm * rimRadiusCm + depthCm * depthCm) / (2.0 * depthCm);
  }

  /// Calculates volume of food inside a spherical-cap katori in ml (cm³).
  ///
  /// Clamps contents surface radius r_s <= rimRadiusCm.
  static double bowlVolumeMl({
    required double surfaceAreaCm2,
    required double rimRadiusCm,
    required double depthCm,
  }) {
    if (surfaceAreaCm2 <= 0.0 || rimRadiusCm <= 0.0 || depthCm <= 0.0) {
      return 0.0;
    }

    final sphereR = bowlSphereRadius(
      rimRadiusCm: rimRadiusCm,
      depthCm: depthCm,
    );
    if (sphereR <= 0.0) return 0.0;

    // r_s = sqrt(A / pi), clamped to rim radius
    final rawRs = math.sqrt(surfaceAreaCm2 / math.pi);
    final rs = math.min(rawRs, rimRadiusCm);

    // h = R - sqrt(R² - r_s²)
    final underRadical = math.max(0.0, sphereR * sphereR - rs * rs);
    final h = sphereR - math.sqrt(underRadical);

    // Spherical cap volume: V = pi * h² * (3R - h) / 3
    final volumeCm3 = (math.pi * h * h * (3.0 * sphereR - h)) / 3.0;
    return math.max(0.0, volumeCm3);
  }

  /// Calculates volume of food mound / layer on a flat plate in ml (cm³).
  ///
  /// V = A_cm² * h_eff
  static double moundVolumeMl({
    required double areaCm2,
    required double effectiveHeightCm,
  }) {
    if (areaCm2 <= 0.0 || effectiveHeightCm <= 0.0) return 0.0;
    return areaCm2 * effectiveHeightCm;
  }

  /// Calculates total mass in grams for piece-mode foods (roti, idli, egg, gulab jamun).
  ///
  /// Formula from AGENTS.md §6.2:
  ///   m = n * unit_mass * clamp(A_piece / A_ref, 0.6, 1.5)
  static double pieceMassGrams({
    required int count,
    required double unitMassGrams,
    double? pieceAreaCm2,
    double? referencePieceAreaCm2,
  }) {
    if (count <= 0 || unitMassGrams <= 0.0) return 0.0;

    var areaScaleFactor = 1.0;
    if (pieceAreaCm2 != null &&
        referencePieceAreaCm2 != null &&
        referencePieceAreaCm2 > 0.0 &&
        pieceAreaCm2 > 0.0) {
      final rawRatio = pieceAreaCm2 / referencePieceAreaCm2;
      areaScaleFactor = rawRatio.clamp(0.6, 1.5);
    }

    return count * unitMassGrams * areaScaleFactor;
  }
}
