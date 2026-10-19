import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/domain/entities/meal.dart';
import 'package:app/domain/entities/macro.dart';

/// Today-screen state. SAMPLE DATA for the UI v0: the real provider
/// will watch the drift `user.db` diary stream through the M1 data
/// layer; the shape of these records is the contract that layer must
/// satisfy. Delete the sample constants at that point (keep the
/// provider surface).
///
/// [MacroLine]/[MealKind] come from domain so Today and Diary share
/// one vocabulary (Section 5.1).
class QuietStat {
  const QuietStat({
    required this.icon,
    required this.value,
    required this.kind,
  });

  final IconData icon;
  final String value;
  final QuietStatKind kind;
}

enum QuietStatKind { steps, water, sleep }

class MealEntry {
  const MealEntry({
    required this.mealKind,
    required this.logged,
    this.calories,
    this.timeLabel,
  });

  final MealKind mealKind;

  /// Whether anything was logged for this meal today.
  final bool logged;
  final int? calories;

  /// Pre-formatted clock label ("8:15 AM") — localisation lands with
  /// the data layer.
  final String? timeLabel;
}

class TodayState {
  const TodayState({
    required this.caloriesConsumed,
    required this.caloriesTarget,
    required this.macros,
    required this.stats,
    required this.meals,
  });

  final int caloriesConsumed;
  final int caloriesTarget;
  final List<MacroLine> macros;
  final List<QuietStat> stats;
  final List<MealEntry> meals;

  int get caloriesRemaining {
    final left = caloriesTarget - caloriesConsumed;
    return left < 0 ? 0 : left;
  }

  double get ringProgress =>
      (caloriesConsumed / caloriesTarget).clamp(0.0, 1.0);
}

/// Sample matching the reference design (ref_ui.png). Steps/water/
/// sleep numbers are placeholders until Health Connect reads arrive
/// (ADR 0008).
final sampleTodayProvider = Provider<TodayState>((ref) {
  return const TodayState(
    caloriesConsumed: 1318,
    caloriesTarget: 1800,
    macros: [
      MacroLine(kind: MacroKind.protein, value: 72, target: 100),
      MacroLine(kind: MacroKind.carbs, value: 120, target: 180),
      MacroLine(kind: MacroKind.fat, value: 28, target: 60),
    ],
    stats: [
      QuietStat(
        icon: Icons.directions_walk,
        value: '6,320',
        kind: QuietStatKind.steps,
      ),
      QuietStat(
        icon: Icons.water_drop,
        value: '1.6 L',
        kind: QuietStatKind.water,
      ),
      QuietStat(
        icon: Icons.bedtime,
        value: '7h 20m',
        kind: QuietStatKind.sleep,
      ),
    ],
    meals: [
      MealEntry(
        mealKind: MealKind.breakfast,
        logged: true,
        calories: 420,
        timeLabel: '8:15 AM',
      ),
      MealEntry(mealKind: MealKind.lunch, logged: false),
    ],
  );
});
