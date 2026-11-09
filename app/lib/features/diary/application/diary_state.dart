import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/app/log_store.dart';
import 'package:app/domain/entities/macro.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/data/preferences/goal_kind_controller.dart';

/// Diary-screen state for ONE day ([offset] family: 0 = today,
/// positive = days back), derived from the shared log store.
class MealBar {
  const MealBar({required this.mealKind, required this.calories});

  final MealKind mealKind;
  final int calories;
}

class MealLogEntry {
  const MealLogEntry({
    required this.index,
    required this.mealKind,
    required this.dish,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    this.timeLabel,
  });

  /// Index in the day's raw entry list, used by the detail sheet delete.
  final int index;
  final MealKind mealKind;
  final String dish;
  final int calories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final String? timeLabel;
}

class DiaryState {
  const DiaryState({
    required this.dtOffset,
    required this.caloriesConsumed,
    required this.caloriesTarget,
    required this.macros,
    required this.mealBars,
    required this.mealLog,
    this.mealLogByKind = const {},
  });

  final int dtOffset;
  final int caloriesConsumed;
  final int caloriesTarget;
  final List<MacroLine> macros;
  final List<MealBar> mealBars;
  final List<MealLogEntry> mealLog;
  final Map<MealKind, List<MealLogEntry>> mealLogByKind;

  List<MealLogEntry> entriesForMeal(MealKind kind) =>
      mealLogByKind[kind] ?? const [];

  int get caloriesRemaining {
    final left = caloriesTarget - caloriesConsumed;
    return left < 0 ? 0 : left;
  }

  double get targetsCompletion {
    var sum = 0.0;
    for (var i = 0; i < macros.length; i++) {
      sum += macros[i].ratio;
    }
    return (sum / (macros.isEmpty ? 1 : macros.length)).clamp(0.0, 1.0);
  }

  bool get isEmpty => caloriesConsumed == 0;
}

final diaryStateProvider = Provider.family<DiaryState, int>((ref, offset) {
  final targets = ref.watch(nutritionTargetsProvider);
  // Rebuild when entries change, not just when the store is created.
  ref.watch(dayLogProvider);
  final log = ref.read(dayLogProvider.notifier);
  final entries = log.entriesFor(offset);

  final mealKcal = <MealKind, int>{
    for (final kind in MealKind.values) kind: 0,
  };
  final mealLogByKind = <MealKind, List<MealLogEntry>>{
    for (final kind in MealKind.values) kind: [],
  };
  final mealLog = <MealLogEntry>[];

  var consumed = 0;
  var protein = 0;
  var carbs = 0;
  var fat = 0;

  for (var i = 0; i < entries.length; i++) {
    final e = entries[i];
    consumed += e.kcal;
    protein += e.proteinGrams;
    carbs += e.carbsGrams;
    fat += e.fatGrams;
    mealKcal[e.mealKind] = (mealKcal[e.mealKind] ?? 0) + e.kcal;

    final entry = MealLogEntry(
      index: i,
      mealKind: e.mealKind,
      dish: e.dish,
      calories: e.kcal,
      proteinGrams: e.proteinGrams,
      carbsGrams: e.carbsGrams,
      fatGrams: e.fatGrams,
      timeLabel: e.timeLabel,
    );
    mealLog.add(entry);
    mealLogByKind[e.mealKind]?.add(entry);
  }

  final totals = DayTotals(
    consumed: consumed,
    protein: protein,
    carbs: carbs,
    fat: fat,
  );

  return DiaryState(
    dtOffset: offset,
    caloriesConsumed: consumed,
    caloriesTarget: targets.kcal,
    macros: totals.macroLines(targets),
    mealBars: [
      for (final kind in MealKind.values)
        MealBar(mealKind: kind, calories: mealKcal[kind] ?? 0),
    ],
    mealLog: mealLog,
    mealLogByKind: mealLogByKind,
  );
});
