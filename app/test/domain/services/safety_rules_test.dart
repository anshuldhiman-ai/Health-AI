import 'package:app/domain/services/safety_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the safety constants (Section 9.4).
///
/// These are safety-critical: a regression here can set an unsafe
/// calorie target. If you change this file, a nutrition
/// professional must re-review (docs/safety/).
void main() {
  group('calorie floors', () {
    test('women floor is 1200 kcal', () {
      expect(SafetyRules.kcalFloorFor(male: false), 1200);
    });

    test('men floor is 1500 kcal', () {
      expect(SafetyRules.kcalFloorFor(male: true), 1500);
    });

    test('floors are positive and below typical TDEE', () {
      for (final floor in [
        SafetyRules.kcalFloorWomen,
        SafetyRules.kcalFloorMen,
      ]) {
        expect(floor, greaterThan(800));
        expect(floor, lessThan(2000));
      }
    });
  });

  group('weekly rate cap', () {
    test('default rate is 0.5 kg/week', () {
      expect(SafetyRules.defaultWeeklyRateKg, 0.5);
    });

    test('hard cap is min(1 kg, 1% of body weight)', () {
      // 1% of 60 kg = 0.6 kg → lower than the 1 kg hard cap
      expect(SafetyRules.weeklyRateHardCapKg(60), closeTo(0.6, 1e-9));
      // 1% of 150 kg = 1.5 kg → the 1 kg hard cap wins
      expect(SafetyRules.weeklyRateHardCapKg(150), closeTo(1.0, 1e-9));
      // Exactly at the crossover: 100 kg
      expect(SafetyRules.weeklyRateHardCapKg(100), closeTo(1.0, 1e-9));
    });

    test('hard cap never exceeds 1 kg', () {
      for (final w in [40.0, 55.0, 70.0, 90.0, 120.0, 200.0]) {
        expect(SafetyRules.weeklyRateHardCapKg(w), lessThanOrEqualTo(1.0));
      }
    });
  });

  group('age gate', () {
    test('adult threshold is 18', () {
      expect(SafetyRules.adultAgeYears, 18);
    });

    test('minimum setup age is 13', () {
      expect(SafetyRules.minAgeYears, 13);
    });
  });

  group('medical flags', () {
    test('five flags are recognised', () {
      expect(SafetyRules.medicalFlagCount, 5);
    });
  });

  group('low-intake check', () {
    test('three consecutive days trigger a calm check-in', () {
      expect(SafetyRules.lowIntakeConsecutiveDays, 3);
    });
  });
}
