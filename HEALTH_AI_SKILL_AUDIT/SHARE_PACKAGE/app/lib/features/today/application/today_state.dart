import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/app/log_store.dart';
import 'package:app/data/preferences/goal_kind_controller.dart';
import 'package:app/domain/entities/macro.dart';

/// Today-screen nutrition state, derived from the shared
/// [dayLogProvider] log store. Activity, water and sleep are separate
/// live providers; the dashboard does not duplicate the diary's food
/// log.
class TodayState {
  const TodayState({
    required this.caloriesConsumed,
    required this.caloriesTarget,
    required this.macros,
  });

  final int caloriesConsumed;
  final int caloriesTarget;
  final List<MacroLine> macros;

  int get caloriesRemaining => math.max(0, caloriesTarget - caloriesConsumed);

  int get caloriesOver => math.max(0, caloriesConsumed - caloriesTarget);

  double get ringProgress =>
      (caloriesConsumed / caloriesTarget).clamp(0.0, 1.0);

  bool get isEmpty => caloriesConsumed == 0;

  bool get isOverTarget => caloriesConsumed > caloriesTarget;

  /// Protein still to go, used by the on-track banner.
  int get proteinRemaining {
    final line = macros.firstWhere((m) => m.kind == MacroKind.protein);
    return math.max(0, line.target - line.value);
  }
}

final todayStateProvider = Provider<TodayState>((ref) {
  final targets = ref.watch(nutritionTargetsProvider);
  // Watch the LOG STATE (not only the notifier) so add/undo refreshes
  // the dashboard immediately.
  ref.watch(dayLogProvider);
  final totals = ref.read(dayLogProvider.notifier).totalsFor(0);

  return TodayState(
    caloriesConsumed: totals.consumed,
    caloriesTarget: targets.kcal,
    macros: totals.macroLines(targets),
  );
});
