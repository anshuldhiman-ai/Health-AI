/// One logged meal portion. Pure Dart (R9: no Flutter imports).
///
/// Swap this record for the drift `diary` row type in M1 — the store
/// and screens treat it as opaque data.
library;

import 'package:app/domain/entities/meal.dart';

class LogEntry {
  const LogEntry({
    required this.mealKind,
    required this.dish,
    required this.kcal,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    this.timeLabel,
  });

  final MealKind mealKind;

  /// Free text the user confirms — sample data seeds use plain names.
  final String dish;

  /// Estimated TOTAL calories for the portion (never a single trusted
  /// number downstream — the UI shows ranges, Section 8.1).
  final int kcal;

  /// Deterministic macro estimate from the portion energy.
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;

  /// Optional clock label shown next to the meal ("8:15 AM").
  /// TODO(l10n): format from a real timestamp once the data layer
  /// stores actual DateTime values.
  final String? timeLabel;

  /// 20 / 55 / 25 kcal split converted to grams (4 / 4 / 9 kmcal/g).
  // A static factory is the honest shape here: the numbers are
  // computed with instance methods that cannot be const-evaluated.
  // ignore: prefer_constructors_over_static_methods
  static LogEntry estimated({
    required MealKind mealKind,
    required String dish,
    required int kcal,
    String? timeLabel,
  }) {
    return LogEntry(
      mealKind: mealKind,
      dish: dish,
      kcal: kcal,
      proteinGrams: ((kcal * 0.20) / 4).round(),
      carbsGrams: ((kcal * 0.55) / 4).round(),
      fatGrams: ((kcal * 0.25) / 9).round(),
      timeLabel: timeLabel,
    );
  }
}
