import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/domain/entities/macro.dart';
import 'package:app/domain/entities/meal.dart';

/// Diary-screen state. SAMPLE DATA (UI v0); the real feed is the
/// drift diary DAO through the M1 data layer.
class DiaryDay {
  const DiaryDay({
    required this.weekdayLabel,
    required this.dayOfMonth,
    required this.isSelected,
  });

  final String weekdayLabel;
  final int dayOfMonth;
  final bool isSelected;
}

class MealBar {
  const MealBar({required this.mealKind, required this.calories});

  final MealKind mealKind;
  final int calories;
}

class MealLogEntry {
  const MealLogEntry({
    required this.mealKind,
    required this.dish,
    required this.calories,
  });

  final MealKind mealKind;
  final String dish;
  final int calories;
}

class DiaryState {
  const DiaryState({
    required this.caloriesConsumed,
    required this.caloriesTarget,
    required this.days,
    required this.mealBars,
    required this.macros,
    required this.mealLog,
  });

  final int caloriesConsumed;
  final int caloriesTarget;

  int get caloriesRemaining {
    final left = caloriesTarget - caloriesConsumed;
    return left < 0 ? 0 : left;
  }

  final List<DiaryDay> days;

  /// One bar per meal kind, in canonical order.
  final List<MealBar> mealBars;

  final List<MacroLine> macros;

  final List<MealLogEntry> mealLog;

  /// Overall completion of today's targets (the donut fraction, 0..1),
  /// computed across the macro lines.
  double get targetsCompletion {
    final sum = macros.fold<double>(0, (acc, m) => acc + m.ratio);
    return (sum / macros.length).clamp(0.0, 1.0);
  }
}

/// Mirrors reference values (ref_ui.png, Diary screen).
final sampleDiaryProvider = Provider<DiaryState>((ref) {
  return const DiaryState(
    caloriesConsumed: 1230,
    caloriesTarget: 1800,
    days: [
      DiaryDay(weekdayLabel: 'Mon', dayOfMonth: 21, isSelected: false),
      DiaryDay(weekdayLabel: 'Tue', dayOfMonth: 22, isSelected: false),
      DiaryDay(weekdayLabel: 'Wed', dayOfMonth: 23, isSelected: false),
      DiaryDay(weekdayLabel: 'Thu', dayOfMonth: 24, isSelected: true),
      DiaryDay(weekdayLabel: 'Fri', dayOfMonth: 25, isSelected: false),
      DiaryDay(weekdayLabel: 'Sat', dayOfMonth: 26, isSelected: false),
      DiaryDay(weekdayLabel: 'Sun', dayOfMonth: 27, isSelected: false),
    ],
    mealBars: [
      MealBar(mealKind: MealKind.breakfast, calories: 420),
      MealBar(mealKind: MealKind.lunch, calories: 380),
      MealBar(mealKind: MealKind.dinner, calories: 350),
      MealBar(mealKind: MealKind.snacks, calories: 80),
    ],
    macros: [
      MacroLine(kind: MacroKind.protein, value: 72, target: 100),
      MacroLine(kind: MacroKind.carbs, value: 120, target: 180),
      MacroLine(kind: MacroKind.fat, value: 28, target: 60),
    ],
    mealLog: [
      MealLogEntry(
        mealKind: MealKind.lunch,
        dish: 'Paneer Butter Masala + Rice',
        calories: 320,
      ),
    ],
  );
});
