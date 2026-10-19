import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/domain/entities/log_entry.dart';
import 'package:app/domain/entities/macro.dart';
import 'package:app/domain/entities/meal.dart';

/// The whole UI's source of truth for dialed days.
///
/// TEMP: an in-memory store so the frontend is fully interactive.
/// The M1 data layer replaces this class with the SQLCipher-backed
/// repository behind the SAME provider (same summary methods), so
/// screens will not change when that lands. Do not persist anything
/// here — closing the app forgets it (empty first-launch behaviour,
/// Section 10.6 empty states).
///
/// Days are indexed by OFFSET from today: 0 = today, 1 = yesterday,
/// ... Negative offsets (future) are invalid by construction.
class DayTotals {
  const DayTotals({
    required this.consumed,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int consumed;
  final int protein;
  final int carbs;
  final int fat;

  List<MacroLine> get macroLines => [
        MacroLine(
          kind: MacroKind.protein,
          value: protein,
          target: _proteinTarget,
        ),
        MacroLine(
          kind: MacroKind.carbs,
          value: carbs,
          target: _carbsTarget,
        ),
        MacroLine(
          kind: MacroKind.fat,
          value: fat,
          target: _fatTarget,
        ),
      ];

  double get targetsCompletion {
    final sum = macroLines.fold<double>(0, (acc, m) => acc + m.ratio);
    return (sum / macroLines.length).clamp(0.0, 1.0);
  }
}

// Targets: proposal values from the product spec (Section 6.1);
// personalised in the onboarding flow later (M1/M2).
const _kcalTarget = 1800;
const _proteinTarget = 100;
const _carbsTarget = 180;
const _fatTarget = 60;

const kcalTarget = _kcalTarget;

class DayLog extends StateNotifier<Map<int, List<LogEntry>>> {
  DayLog() : super(_seed());

  static const maxDays = 7; // UI window: today + 6 previous days.

  List<LogEntry> entriesFor(int dayOffset) => state[dayOffset] ?? const [];

  DayTotals totalsFor(int dayOffset) {
    var protein = 0, carbs = 0, fat = 0;
    for (final e in entriesFor(dayOffset)) {
      protein += e.proteinGrams;
      carbs += e.carbsGrams;
      fat += e.fatGrams;
    }
    return DayTotals(
      consumed: entriesFor(dayOffset).fold(0, (sum, e) => sum + e.kcal),
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }

  int kcalForMeal(int dayOffset, MealKind kind) => entriesFor(dayOffset)
      .where((e) => e.mealKind == kind)
      .fold(0, (sum, e) => sum + e.kcal);

  /// Append a confirmed scan/menu pick. The UI never writes raw macro
  /// numbers — it gets an estimated entry from [LogEntry.estimated].
  void add(LogEntry entry) {
    final entries = [...entriesFor(0), entry];
    state = {...state, 0: entries};
  }

  /// Undo support: remove the newest entry of any day.
  bool removeNewest(int dayOffset) {
    final entries = entriesFor(dayOffset);
    if (entries.isEmpty) return false;
    state = {...state, dayOffset: entries.sublist(0, entries.length - 1)};
    return true;
  }
}

final dayLogProvider =
    StateNotifierProvider<DayLog, Map<int, List<LogEntry>>>(
  (ref) => DayLog(),
);

/// Previous-week baseline so the Insights delta chip has a defensible
/// "before" number without 14 real days of history. M1 replaces this
/// with the actual two-week average from the DB.
const previousWeekAverageKcal = 1292;

// ---------------------------------------------------------------------------
// Seed: reference-matching demo data for TODAY (dashboard ring reads
// 482 remaining) and plausible history for the previous six days so
// Diary/Insights have believable shapes on first open. Deleted with
// the store itself in M1.
// ---------------------------------------------------------------------------

Map<int, List<LogEntry>> _seed() {
  final today = [
    LogEntry.estimated(
      mealKind: MealKind.breakfast,
      dish: 'Poha + chai',
      kcal: 420,
      timeLabel: '8:15 AM',
    ),
    LogEntry.estimated(
      mealKind: MealKind.lunch,
      dish: 'Rajma chawal',
      kcal: 468,
      timeLabel: '1:10 PM',
    ),
    LogEntry.estimated(
      mealKind: MealKind.dinner,
      dish: 'Dal + roti',
      kcal: 350,
    ),
    LogEntry.estimated(
      mealKind: MealKind.snacks,
      dish: 'Roasted chana',
      kcal: 80,
    ),
  ];

  // Totals ~ 1280..1560 so the 7-day average sits near the previous
  // week's [previousWeekAverageKcal] with a small upward drift.
  const historyTotals = [1280, 1350, 1560, 1480, 1420, 1380, 1310];

  final out = <int, List<LogEntry>>{0: today};
  for (var i = 1; i <= DayLog.maxDays - 1; i++) {
    final total = historyTotals[i - 1];
    out[i] = [
      LogEntry.estimated(
        mealKind: MealKind.breakfast,
        dish: 'Breakfast',
        kcal: (total * 0.34).round(),
      ),
      LogEntry.estimated(
        mealKind: MealKind.lunch,
        dish: 'Lunch',
        kcal: (total * 0.31).round(),
      ),
      LogEntry.estimated(
        mealKind: MealKind.dinner,
        dish: 'Dinner',
        kcal: (total * 0.28).round(),
      ),
      LogEntry.estimated(
        mealKind: MealKind.snacks,
        dish: 'Snacks',
        kcal: (total * 0.07).round(),
      ),
    ];
  }
  return out;
}
