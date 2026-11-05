import 'dart:convert';
import 'dart:io';

import 'package:app/domain/entities/dish_record.dart';
import 'package:app/domain/services/mass_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'MassEstimator - Python/Dart Parity on mass_vectors.json (AGENTS.md §6.3)',
    () {
      test('Matches mass vectors with relative error <= 1e-6', () {
        final file = File('test/fixtures/mass_vectors.json');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'test/fixtures/mass_vectors.json must exist',
        );

        final content = file.readAsStringSync();
        final vectors = jsonDecode(content) as List<dynamic>;

        for (final vec in vectors) {
          final mode = vec['mode'] as String;

          if (mode == 'bowl') {
            final range = MassEstimator.estimateBowlMass(
              surfaceAreaCm2: (vec['surface_area_cm2'] as num).toDouble(),
              rimRadiusCm: (vec['rim_radius_cm'] as num).toDouble(),
              depthCm: (vec['depth_cm'] as num).toDouble(),
              densityGPerMl: (vec['density_g_per_ml'] as num).toDouble(),
              q10: (vec['residual_q10'] as num).toDouble(),
              q50: (vec['residual_q50'] as num).toDouble(),
              q90: (vec['residual_q90'] as num).toDouble(),
            );

            final exp10 = (vec['expected_p10_g'] as num).toDouble();
            final exp50 = (vec['expected_p50_g'] as num).toDouble();
            final exp90 = (vec['expected_p90_g'] as num).toDouble();

            expect((range.p10 - exp10).abs() / exp10, lessThanOrEqualTo(1e-6));
            expect((range.p50 - exp50).abs() / exp50, lessThanOrEqualTo(1e-6));
            expect((range.p90 - exp90).abs() / exp90, lessThanOrEqualTo(1e-6));
          } else if (mode == 'mound') {
            final range = MassEstimator.estimateMoundMass(
              areaCm2: (vec['area_cm2'] as num).toDouble(),
              role: Role.moundedCarb,
              densityGPerMl: (vec['density_g_per_ml'] as num).toDouble(),
              customHEffP10: (vec['h_eff_p10_cm'] as num).toDouble(),
              customHEffP50: (vec['h_eff_p50_cm'] as num).toDouble(),
              customHEffP90: (vec['h_eff_p90_cm'] as num).toDouble(),
            );

            final exp10 = (vec['expected_p10_g'] as num).toDouble();
            final exp50 = (vec['expected_p50_g'] as num).toDouble();
            final exp90 = (vec['expected_p90_g'] as num).toDouble();

            expect((range.p10 - exp10).abs() / exp10, lessThanOrEqualTo(1e-6));
            expect((range.p50 - exp50).abs() / exp50, lessThanOrEqualTo(1e-6));
            expect((range.p90 - exp90).abs() / exp90, lessThanOrEqualTo(1e-6));
          } else if (mode == 'piece') {
            final range = MassEstimator.estimatePieceMass(
              count: vec['count'] as int,
              unitMassGrams: (vec['unit_mass_g'] as num).toDouble(),
              pieceAreaCm2: (vec['piece_area_cm2'] as num).toDouble(),
              referencePieceAreaCm2: (vec['reference_piece_area_cm2'] as num)
                  .toDouble(),
              q10: (vec['residual_q10'] as num).toDouble(),
              q50: (vec['residual_q50'] as num).toDouble(),
              q90: (vec['residual_q90'] as num).toDouble(),
            );

            final exp10 = (vec['expected_p10_g'] as num).toDouble();
            final exp50 = (vec['expected_p50_g'] as num).toDouble();
            final exp90 = (vec['expected_p90_g'] as num).toDouble();

            expect((range.p10 - exp10).abs() / exp10, lessThanOrEqualTo(1e-6));
            expect((range.p50 - exp50).abs() / exp50, lessThanOrEqualTo(1e-6));
            expect((range.p90 - exp90).abs() / exp90, lessThanOrEqualTo(1e-6));
          }
        }
      });
    },
  );
}
