import 'dart:math' as math;

import 'package:app/domain/services/volumetric_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VolumetricMath - Bowl Spherical Cap Mode (§6.2)', () {
    test(
      'Hand-computed benchmark: a_c=5, d_c=4 => R=5.125, full bowl ≈ 190.6 ml',
      () {
        const rimRadiusCm = 5.0;
        const depthCm = 4.0;
        final sphereRadius = VolumetricMath.bowlSphereRadius(
          rimRadiusCm: rimRadiusCm,
          depthCm: depthCm,
        );
        expect(sphereRadius, equals(5.125));

        // Full surface area = pi * r_s^2 = pi * 25 ≈ 78.5398 cm²
        const surfaceAreaCm2 = math.pi * rimRadiusCm * rimRadiusCm;
        final volumeMl = VolumetricMath.bowlVolumeMl(
          surfaceAreaCm2: surfaceAreaCm2,
          rimRadiusCm: rimRadiusCm,
          depthCm: depthCm,
        );

        // Expected: pi * 16 * 11.375 / 3 = 190.589969...
        expect(volumeMl, closeTo(190.59, 0.05));
      },
    );

    test('Clamps contents surface radius when r_s > a_c', () {
      const rimRadiusCm = 5.0;
      const depthCm = 4.0;

      // Surface area 200 cm² would imply r_s ≈ 7.98 cm, which exceeds rim radius of 5.0
      const excessiveSurfaceAreaCm2 = 200.0;
      final volumeMl = VolumetricMath.bowlVolumeMl(
        surfaceAreaCm2: excessiveSurfaceAreaCm2,
        rimRadiusCm: rimRadiusCm,
        depthCm: depthCm,
      );

      // Should clamp to full capacity ~ 190.59 ml
      expect(volumeMl, closeTo(190.59, 0.05));
    });

    test('Monotonically increases as surface area increases from 0 to full capacity', () {
      const rimRadiusCm = 5.0;
      const depthCm = 4.0;
      double previousVol = 0.0;

      for (var area = 5.0; area <= 78.0; area += 10.0) {
        final vol = VolumetricMath.bowlVolumeMl(
          surfaceAreaCm2: area,
          rimRadiusCm: rimRadiusCm,
          depthCm: depthCm,
        );
        expect(vol, greaterThan(previousVol));
        previousVol = vol;
      }
    });

    test('Returns zero when surface area is zero or negative', () {
      final volZero = VolumetricMath.bowlVolumeMl(
        surfaceAreaCm2: 0.0,
        rimRadiusCm: 5.0,
        depthCm: 4.0,
      );
      expect(volZero, equals(0.0));

      final volNeg = VolumetricMath.bowlVolumeMl(
        surfaceAreaCm2: -10.0,
        rimRadiusCm: 5.0,
        depthCm: 4.0,
      );
      expect(volNeg, equals(0.0));
    });
  });

  group('VolumetricMath - Layer / Mound Mode (§6.2)', () {
    test('Volume is Area * h_eff', () {
      const areaCm2 = 120.0;
      const hEffCm = 2.0;

      final volumeMl = VolumetricMath.moundVolumeMl(
        areaCm2: areaCm2,
        effectiveHeightCm: hEffCm,
      );

      // 120 * 2.0 = 240 ml
      expect(volumeMl, equals(240.0));
    });

    test('Monotonically increases with area and height', () {
      final vol1 = VolumetricMath.moundVolumeMl(
        areaCm2: 100.0,
        effectiveHeightCm: 1.5,
      );
      final vol2 = VolumetricMath.moundVolumeMl(
        areaCm2: 150.0,
        effectiveHeightCm: 1.5,
      );
      final vol3 = VolumetricMath.moundVolumeMl(
        areaCm2: 150.0,
        effectiveHeightCm: 2.5,
      );

      expect(vol2, greaterThan(vol1));
      expect(vol3, greaterThan(vol2));
    });
  });

  group('VolumetricMath - Piece Mode (§6.2)', () {
    test('Calculates count * unit_mass * clamp(A_piece / A_ref, 0.6, 1.5)', () {
      // Normal size piece (A_piece == A_ref)
      final massNormal = VolumetricMath.pieceMassGrams(
        count: 2,
        unitMassGrams: 35.0,
        pieceAreaCm2: 80.0,
        referencePieceAreaCm2: 80.0,
      );
      // 2 * 35.0 * 1.0 = 70.0 g
      expect(massNormal, equals(70.0));

      // Small piece (ratio 0.4 < 0.6 clamp)
      final massSmall = VolumetricMath.pieceMassGrams(
        count: 2,
        unitMassGrams: 35.0,
        pieceAreaCm2: 32.0, // 32 / 80 = 0.4 -> clamped to 0.6
        referencePieceAreaCm2: 80.0,
      );
      // 2 * 35.0 * 0.6 = 42.0 g
      expect(massSmall, equals(42.0));

      // Extra large piece (ratio 2.0 > 1.5 clamp)
      final massLarge = VolumetricMath.pieceMassGrams(
        count: 2,
        unitMassGrams: 35.0,
        pieceAreaCm2: 160.0, // 160 / 80 = 2.0 -> clamped to 1.5
        referencePieceAreaCm2: 80.0,
      );
      // 2 * 35.0 * 1.5 = 105.0 g
      expect(massLarge, equals(105.0));
    });

    test('Defaults to count * unit_mass when piece areas are null', () {
      final massDefault = VolumetricMath.pieceMassGrams(
        count: 3,
        unitMassGrams: 28.0,
        pieceAreaCm2: null,
        referencePieceAreaCm2: null,
      );
      expect(massDefault, equals(84.0));
    });
  });
}
