import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/app/log_store.dart';
import 'package:app/domain/entities/macro.dart';
import 'package:app/domain/entities/meal.dart';

/// Diary-screen state for ONE day ([offset] family: 0 = today,
/// positive = days back), derived from the shared log store.
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
    required this.dtOffset,
    required this.caloriesConsumed,
    required this.caloriesTarget,
    required this.macros,
    required this.mealBars,
    required this.mealLog,
  });

  final int dtOffset;
  final int caloriesConsumed;
  final int caloriesTarget;
  final List<MacroLine> macros;
  final List<MealBar> mealBars;
  final List<MealLogEntry> mealLog;

  int get caloriesRemaining {
    final left = caloriesTarget - caloriesConsumed;
    return left < 0 ? 0 : left;
  }

  double get targetsCompletion {
    final sum = macros.fold<double>(0, (acc, m) => acc + m.ratio);
    return (sum / macros.length).clamp(0.0, 1.0);
  }

  bool get isEmpty => caloriesConsumed == 0;
}

final diaryStateProvider = Provider.family<DiaryState, int>((ref, offset) {
  final log = ref.watch(dayLogProvider.notifier);
  final totals = log.totalsFor(offset);

  return DiaryState(
    dtOffset: offset,
    caloriesConsumed: totals.consumed,
    caloriesTarget: kcalTarget,
    macros: totals.macroLines,
    mealBars: [
      for (final kind in MealKind.values)
        MealBar(
          mealKind: kind,
          calories: log.kcalForMeal(offset, kind),
        ),
    ],
    mealLog: [
      for (final e in log.entriesFor(offset).reversed)
        MealLogEntry(
          mealKind: e.mealKind,
          dish: e.dish,
          calories: e.kcal,
        ),
    ],
  );
});
