/// Nutrition and health safety rules (Section 9.4).
///
/// These constants are SAFETY-CRITICAL. They are enforced in the
/// domain layer and covered by tests.
///
/// Sources and a "last reviewed" date live in `docs/safety/`.
/// Review them with a qualified nutrition professional before public
/// release. Do not tune these without that review.
///
/// Pure Dart (R9).
library;

/// Safety rules for calorie targets and weight-change goals.
abstract final class SafetyRules {
  SafetyRules._();

  /// Date these constants were last reviewed by a qualified
  /// nutrition professional. Update when the file changes.
  /// TODO(M5): fill in after professional review.
  static const lastReviewed = 'NOT YET REVIEWED — 2026-10-12';

  // --- Age gate (Section 9.4) ---

  /// Minimum age for any goal setup.
  static const minAgeYears = 13;

  /// Under this age: no calorie-deficit or weight-loss targets;
  /// maintenance / healthy-habits mode only.
  static const adultAgeYears = 18;

  // --- BMI floor ---

  /// Below this BMI, no weight-loss goal; tracking only.
  static const bmiMinForWeightLoss = 18.5;

  // --- Calorie floors ---
  /// NEVER set a daily target below these floors (commonly cited
  /// unsupervised floors; confirm against current guidance with a
  /// nutrition professional before release — Section 17).
  /// The planner clamps and explains.
  static const kcalFloorWomen = 1200;
  static const kcalFloorMen = 1500;

  /// Used when sex is unspecified: the more conservative floor.
  static int kcalFloorFor({required bool male}) =>
      male ? kcalFloorMen : kcalFloorWomen;

  // --- Rate cap ---

  /// Default maximum weight-change rate.
  static const defaultWeeklyRateKg = 0.5;

  /// Hard cap: about 1 kg/week OR 1% of body weight per week,
  /// whichever is lower.
  static const hardWeeklyRateKg = 1.0;

  /// Returns the applicable hard cap for a body weight.
  static double weeklyRateHardCapKg(double bodyWeightKg) {
    const percentOfBody = 0.01;
    final byPercent = bodyWeightKg * percentOfBody;
    return byPercent < hardWeeklyRateKg ? byPercent : hardWeeklyRateKg;
  }

  // --- Medical flags ---

  /// Flags that require "tracking only" (no automatic deficit plan):
  /// pregnancy/breastfeeding, diabetes, kidney disease, history of
  /// eating disorders, under medical supervision.
  static const medicalFlagCount = 5;

  // --- Consecutive-days low-intake check ---

  /// If logged intake is far below the floor for this many
  /// consecutive days, show a calm check-in message (not a lecture).
  static const lowIntakeConsecutiveDays = 3;
}
