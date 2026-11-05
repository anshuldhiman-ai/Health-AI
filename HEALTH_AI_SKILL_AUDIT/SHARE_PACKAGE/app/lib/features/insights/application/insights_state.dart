import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/app/log_store.dart';
import 'package:app/domain/entities/macro.dart';
import 'package:app/data/preferences/goal_kind_controller.dart';

/// Selected chart window: 7, 30 or 90 days.
final insightsRangeProvider = StateProvider<int>((ref) => 7);

class TrendPoint {
  const TrendPoint(this.dayIndex, this.kcal);

  final int dayIndex;
  final int kcal;
}

class InsightsState {
  const InsightsState({
    required this.rangeDays,
    required this.avgKcalPerDay,
    required this.trendChangePercent,
    required this.trend,
    required this.hasData,
    required this.balanceCompletion,
    required this.balance,
  });

  final int rangeDays;
  final int avgKcalPerDay;
  final int trendChangePercent;
  final List<TrendPoint> trend;
  final bool hasData;
  final double balanceCompletion;
  final List<(MacroKind, int percent)> balance;
}

final insightsStateProvider = Provider<InsightsState>((ref) {
  final targets = ref.watch(nutritionTargetsProvider);
  final range = ref.watch(insightsRangeProvider);
  // Rebuild when entries change, not just when the store is created.
  ref.watch(dayLogProvider);
  final log = ref.read(dayLogProvider.notifier);

  final trend = <TrendPoint>[
    for (var i = range - 1; i >= 0; i--)
      TrendPoint(range - 1 - i, log.totalsFor(i).consumed),
  ];

  final sum = trend.fold<int>(0, (acc, p) => acc + p.kcal);
  final avg = sum ~/ range;
  // Compare against the immediately preceding window of equal length.
  final previousSum = _sumRange(log, range, range);
  final previousAvg = previousSum ~/ range;
  final delta = avg - previousAvg;
  final percent = previousAvg <= 0 ? 0 : (delta * 100 / previousAvg).round();

  // Share of today's calories eaten per macro.
  final totals = log.totalsFor(0);
  final pcal = totals.protein * 4;
  final ccal = totals.carbs * 4;
  final fcal = totals.fat * 9;
  final total = (pcal + ccal + fcal).clamp(1, 1 << 30);

  return InsightsState(
    rangeDays: range,
    avgKcalPerDay: avg,
    trendChangePercent: percent,
    trend: trend,
    hasData: trend.any((point) => point.kcal > 0),
    balanceCompletion: totals.targetsCompletion(targets),
    balance: [
      (MacroKind.protein, (pcal * 100 / total).round()),
      (MacroKind.carbs, (ccal * 100 / total).round()),
      (MacroKind.fat, (fcal * 100 / total).round()),
    ],
  );
});

int _sumRange(DayLog log, int start, int days) {
  var sum = 0;
  for (var i = start; i < start + days; i++) {
    sum += log.totalsFor(i).consumed;
  }
  return sum;
}
