import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/app/log_store.dart';
import 'package:app/domain/entities/macro.dart';

/// Insights-screen state, derived from the shared log store's last
/// seven days. The "before" delta uses [previousWeekAverageKcal]
/// until M1 holds real two-week history.
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
  final int trendChangePercent;
  final List<TrendPoint> trend;
  final double balanceCompletion;
  final List<(MacroKind, int percent)> balance;
}

final insightsStateProvider = Provider<InsightsState>((ref) {
  final log = ref.watch(dayLogProvider.notifier);

  final trend = <TrendPoint>[
    for (var i = DayLog.maxDays - 1; i >= 0; i--)
      TrendPoint(
        DayLog.maxDays - 1 - i,
        log.totalsFor(i).consumed,
      ),
  ];

  final avg =
      trend.fold<int>(0, (sum, p) => sum + p.kcal) ~/ trend.length;
  final delta = avg - previousWeekAverageKcal;
  final percent = previousWeekAverageKcal <= 0
      ? 0
      : (delta * 100 / previousWeekAverageKcal).round();

  // Share of today's calories eaten per macro.
  final totals = log.totalsFor(0);
  final pcal = totals.protein * 4;
  final ccal = totals.carbs * 4;
  final fcal = totals.fat * 9;
  final total = (pcal + ccal + fcal).clamp(1, 1 << 30);

  return InsightsState(
    avgKcalPerDay: avg,
    trendChangePercent: percent,
    trend: trend,
    balanceCompletion: totals.targetsCompletion,
    balance: [
      (MacroKind.protein, (pcal * 100 / total).round()),
      (MacroKind.carbs, (ccal * 100 / total).round()),
      (MacroKind.fat, (fcal * 100 / total).round()),
    ],
  );
});
