import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/app/log_store.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/domain/entities/macro.dart';

/// Today-screen state, now derived from the shared [dayLogProvider]
/// log store: the ring, macro meters and meal rows all update live
/// when a meal is added or undone.
///
/// [QuietStat] keeps the placeholder steps/water/sleep values until
/// Health Connect reads arrive (ADR 0008).
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
    this.dish,
  });

  final MealKind mealKind;
  final bool logged;
  final int? calories;
  final String? timeLabel;
  final String? dish;
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

  bool get isEmpty => caloriesConsumed == 0;
}

/// Aggregates the canonical meal rows for the dashboard: one row per
/// meal kind — the newest logged entry wins, unlogged shows the
/// "Add food" affordance.
final todayStateProvider = Provider<TodayState>((ref) {
  final log = ref.watch(dayLogProvider.notifier);
  final totals = log.totalsFor(0);

  return TodayState(
    caloriesConsumed: totals.consumed,
    caloriesTarget: kcalTarget,
    macros: totals.macroLines,
    stats: const [
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
      for (final kind in MealKind.values)
        () {
          final entries = log
              .entriesFor(0)
              .where((e) => e.mealKind == kind)
              .toList();
          if (entries.isEmpty) {
            return MealEntry(mealKind: kind, logged: false);
          }
          final e = entries.last;
          return MealEntry(
            mealKind: kind,
            logged: true,
            calories: e.kcal,
            timeLabel: e.timeLabel,
            dish: e.dish,
          );
        }(),
    ],
  );
});
