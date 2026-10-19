import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/domain/entities/macro.dart';

/// Insights-screen state. SAMPLE DATA (UI v0); real series come from
/// the drift DB + [InsightEngine] takeaways in M1/M3.
class TrendPoint {
  const TrendPoint(this.dayIndex, this.kcal);

  final int dayIndex;
  final int kcal;
}

class InsightsState {
  const InsightsState({
    required this.avgKcalPerDay,
    required this.trendChangePercent,
    required this.trend,
    required this.balanceCompletion,
    required this.balance,
  });

  final int avgKcalPerDay;

  /// Week-over-week change as a signed percent.
  final int trendChangePercent;
  final List<TrendPoint> trend;

  /// Ring completion used for the balance donut (0..1).
  final double balanceCompletion;

  /// Share of calories eaten per macro kind.
  final List<(MacroKind, int percent)> balance;
}

final sampleInsightsProvider = Provider<InsightsState>((ref) {
  return const InsightsState(
    avgKcalPerDay: 1420,
    trendChangePercent: 8,
    trend: [
      TrendPoint(0, 1450),
      TrendPoint(1, 1380),
      TrendPoint(2, 1520),
      TrendPoint(3, 1480),
      TrendPoint(4, 1420),
      TrendPoint(5, 1380),
      TrendPoint(6, 1390),
    ],
    balanceCompletion: 0.68,
    balance: [
      (MacroKind.protein, 28),
      (MacroKind.carbs, 49),
      (MacroKind.fat, 23),
    ],
  );
});
