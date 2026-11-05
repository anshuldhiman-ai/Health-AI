import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/app/log_store.dart';
import 'package:app/core/format/count_format.dart';
import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/components/progress_ring.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/features/insights/application/insights_state.dart';
import 'package:app/l10n/app_localizations.dart';

/// Insights matching Health AI Showcase Screen 5:
/// - Range tabs: Week | Month | 3 Months
/// - Nutrition Balance Donut with 78% Well Balanced and real macros
/// - Live interactive Calorie Trend chart with curved fill, dots & tips
/// - Key Insights card ("You're doing great!...")
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(insightsStateProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.x2,
            AppSpacing.screenPadding,
            96,
          ),
          children: [
            _InsightsHeader(),
            const SizedBox(height: 16),
            const _RangeChips(),
            const SizedBox(height: 18),
            // Nutrition Balance Donut Card
            _BalanceCard(state: state),
            const SizedBox(height: 18),
            // Live Interactive Calorie Trend Chart Card
            _TrendCard(state: state),
            const SizedBox(height: 18),
            // Key Insights Card from showcase
            _KeyInsightsCard(state: state),
            const SizedBox(height: 16),
            _WeeklyProgressCard(),
          ],
        ),
      ),
    );
  }
}

class _InsightsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        const SizedBox(width: 4),
        Text(
          'Insights',
          style: AppTypography.titleL.copyWith(
            color: scheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.washOf(colors.primary),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.insights_rounded, color: colors.primary, size: 20),
        ),
      ],
    );
  }
}

class _RangeChips extends ConsumerWidget {
  const _RangeChips();

  static const _ranges = <int>[7, 30, 90];
  static const _labels = <String>['Week', 'Month', '3 Months'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final selected = ref.watch(insightsRangeProvider);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (var i = 0; i < _ranges.length; i++) ...[
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    ref.read(insightsRangeProvider.notifier).state = _ranges[i],
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    // Selected state uses primary/onPrimary so it stays
                    // legible in both themes (a fixed dark green with
                    // white text vanishes on a dark canvas).
                    color: _ranges[i] == selected
                        ? scheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      _labels[i],
                      style: TextStyle(
                        color: _ranges[i] == selected
                            ? scheme.onPrimary
                            : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Nutrition Balance Donut Card matching showcase
class _BalanceCard extends ConsumerWidget {
  const _BalanceCard({required this.state});

  final InsightsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    ref.watch(dayLogProvider);
    final log = ref.read(dayLogProvider.notifier);
    final totals = log.totalsFor(0);

    final totalGrams = totals.protein + totals.carbs + totals.fat;
    final hasLoggedFood = totalGrams > 0;
    final pPct = hasLoggedFood
        ? ((totals.protein / totalGrams) * 100).round()
        : 0;
    final cPct = hasLoggedFood
        ? ((totals.carbs / totalGrams) * 100).round()
        : 0;
    final fPct = hasLoggedFood ? (100 - pPct - cPct).clamp(0, 100) : 0;

    final completionPct = (state.balanceCompletion * 100).round();
    final balanceDisplay = hasLoggedFood ? '$completionPct%' : '0%';
    final balanceSubtext = hasLoggedFood
        ? (completionPct >= 70 ? 'Well Balanced' : 'Moderate')
        : 'No food logged';

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nutrition Balance',
                style: AppTypography.itemTitle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              // Concentric / Segmented Donut
              ProgressRing(
                size: 136,
                strokeWidth: 16,
                segments: hasLoggedFood
                    ? [
                        RingSegment(
                          value: pPct / 100,
                          color: colors.macroProtein,
                        ),
                        RingSegment(value: cPct / 100, color: colors.water),
                        RingSegment(value: fPct / 100, color: colors.accent),
                      ]
                    : [
                        RingSegment(
                          value: 0.0,
                          color: scheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ],
                semanticLabel:
                    'Nutrition Balance: $balanceDisplay $balanceSubtext',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      balanceDisplay,
                      style: TextStyle(
                        fontFamily: AppTypography.family,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      balanceSubtext,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Macro Legend List
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MacroLegendRow(
                      color: colors.macroProtein,
                      label: 'Protein',
                      amount: '${totals.protein}g',
                      percentage: '$pPct%',
                    ),
                    const SizedBox(height: 12),
                    _MacroLegendRow(
                      color: colors.water,
                      label: 'Carbs',
                      amount: '${totals.carbs}g',
                      percentage: '$cPct%',
                    ),
                    const SizedBox(height: 12),
                    _MacroLegendRow(
                      color: colors.accent,
                      label: 'Fats',
                      amount: '${totals.fat}g',
                      percentage: '$fPct%',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroLegendRow extends StatelessWidget {
  const _MacroLegendRow({
    required this.color,
    required this.label,
    required this.amount,
    required this.percentage,
  });

  final Color color;
  final String label;
  final String amount;
  final String percentage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ),
        Text(
          percentage,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Live interactive Calorie Trend Chart
class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.state});

  final InsightsState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    // Build data points
    final spots = <FlSpot>[];
    for (var i = 0; i < state.trend.length; i++) {
      spots.add(FlSpot(i.toDouble(), state.trend[i].kcal.toDouble()));
    }

    final maxVal = state.trend.fold<int>(0, (m, p) => p.kcal > m ? p.kcal : m);
    final effectiveMax = math.max(
      2400.0,
      ((maxVal + 400) / 400).ceil() * 400.0,
    );

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calorie Trend',
                style: AppTypography.itemTitle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatCount(state.avgKcalPerDay),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'avg kcal/day',
                style: AppTypography.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 800,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 800,
                      getTitlesWidget: (val, meta) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          val >= 1000
                              ? '${(val / 1000).toStringAsFixed(1)}k'
                              : '${val.toInt()}',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 1,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= state.trend.length) {
                          return const SizedBox.shrink();
                        }
                        final daysAgo = state.trend.length - 1 - idx;
                        final date = DateTime.now().subtract(
                          Duration(days: daysAgo),
                        );
                        const wds = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            wds[date.weekday - 1],
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 10.5,
                              fontWeight: daysAgo == 0
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => scheme.primary,
                    getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                      final kcal = spot.y.round();
                      final idx = spot.x.toInt();
                      final daysAgo = state.trend.length - 1 - idx;
                      final date = DateTime.now().subtract(
                        Duration(days: daysAgo),
                      );
                      const wds = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ];
                      return LineTooltipItem(
                        '${wds[date.weekday - 1]} ${date.day}\n$kcal kcal',
                        TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 3.2,
                    color: colors.primary,
                    dotData: FlDotData(
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 3.5,
                            color: colors.primary,
                            strokeWidth: 2,
                            // Halo reads as a cut-out against the card, so
                            // it follows the surface token, not white.
                            strokeColor: colors.surface,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colors.primary.withValues(alpha: 0.32),
                          colors.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                minX: 0,
                maxX: (state.trend.length - 1).toDouble(),
                minY: 0,
                maxY: effectiveMax,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Key Insights Card matching showcase
class _KeyInsightsCard extends StatelessWidget {
  const _KeyInsightsCard({required this.state});

  final InsightsState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final hasLogged = state.avgKcalPerDay > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // A tonal wash of primary rather than a fixed mint/emerald pair:
        // one definition now covers both themes.
        color: colors.washOf(colors.primary),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: scheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasLogged
                      ? "You're doing great!"
                      : 'Start Logging Your Meals',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasLogged
                      ? 'Your daily nutrient consistency is on track. '
                            'Tracking consistently helps reach your ideal '
                            'health goals.'
                      : 'Log your breakfast, lunch, or dinner to unlock AI '
                            'nutritional insights and personal macro trends.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: () => context.push('/weekly'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryWash,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: scheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.weeklyProgress,
                  style: AppTypography.itemTitle.copyWith(
                    color: scheme.onSurface,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'View day-by-day weekly breakdown & streaks',
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
