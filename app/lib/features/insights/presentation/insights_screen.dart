import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/format/count_format.dart';
import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/components/group_header.dart';
import 'package:app/design_system/components/progress_ring.dart';
import 'package:app/design_system/components/screen_header.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/macro.dart';
import 'package:app/features/insights/application/insights_state.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/extensions.dart';

/// Insights per ref_ui.png: range chips, calorie-trend chart with
/// dotted curve, nutrition balance donut. Charts are always paired
/// with a text summary so screen readers get the real information
/// (R14).
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(insightsStateProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.x4,
            AppSpacing.screenPadding,
            120,
          ),
          children: [
            ScreenHeader(
              icon: Icons.insights_rounded,
              title: l10n.insightsTitle,
            ),
            const SizedBox(height: 20),
            const _RangeChips(),
            const SizedBox(height: 18),
            _TrendCard(state: state),
            const SizedBox(height: 12),
            _WeeklyProgressCard(),
            const SizedBox(height: 26),
            GroupHeader(title: l10n.nutritionBalance),
            const SizedBox(height: 12),
            _BalanceCard(state: state),
          ],
        ),
      ),
    );
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return AppCard(
      onTap: () => context.push('/weekly'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryWash,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: scheme.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.weeklyProgress,
                  style: AppTypography.itemS.copyWith(
                    color: scheme.onSurface,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.weeklySubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
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

class _RangeChips extends ConsumerWidget {
  const _RangeChips();

  static const _ranges = <int>[7, 30, 90];
  static const _labels = <String>['7D', '30D', '90D'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final selected = ref.watch(insightsRangeProvider);

    return Row(
      spacing: 10,
      children: [
        for (var i = 0; i < _ranges.length; i++)
          Expanded(
            child: Material(
              color: _ranges[i] == selected ? scheme.primary : scheme.surface,
              shape: StadiumBorder(
                side: BorderSide(
                  color: _ranges[i] == selected
                      ? scheme.primary
                      : scheme.outline,
                ),
              ),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () =>
                    ref.read(insightsRangeProvider.notifier).state = _ranges[i],
                child: SizedBox(
                  height: 38,
                  child: Center(
                    child: Text(
                      _labels[i],
                      style: AppTypography.caption.copyWith(
                        color: _ranges[i] == selected
                            ? scheme.onPrimary
                            : scheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.state});

  final InsightsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final up = state.trendChangePercent >= 0;
    final change = up
        ? l10n.trendChangeUp('${state.trendChangePercent}')
        : l10n.trendChangeDown('${state.trendChangePercent.abs()}');

    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.calorieTrend,
                  style: AppTypography.titleM.copyWith(color: scheme.onSurface),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryWash,
                  borderRadius: BorderRadius.circular(AppRadii.pill.x),
                ),
                // Text + arrow, not colour alone (R14).
                child: Text(
                  change,
                  style: AppTypography.caption.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatCount(state.avgKcalPerDay),
                style: AppTypography.value20.copyWith(color: scheme.onSurface),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.avgKcalPerDay,
                style: AppTypography.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 148,
            // The chart itself is a graphic; the numbers above are the
            // accessible summary of the same data.
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: scheme.outlineVariant, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: const AxisTitles(),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 200,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          _compact(value),
                          style: AppTypography.caption.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (final p in state.trend)
                        FlSpot(p.dayIndex.toDouble(), p.kcal.toDouble()),
                    ],
                    isCurved: true,
                    barWidth: 2.6,
                    color: scheme.primary,
                    dotData: FlDotData(
                      show: state.trend.length <= 30,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                            radius: 3.2,
                            color: scheme.primary,
                            strokeWidth: 1.5,
                            strokeColor: scheme.surface,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          scheme.primary.withValues(alpha: 0.14),
                          scheme.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                minX: 0,
                maxX: (state.trend.length - 1).toDouble(),
                minY: _floor(state.trend),
                maxY: _ceil(state.trend),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _compact(double value) {
    if (value >= 1000) {
      final k = value / 1000;
      return '${k.toStringAsFixed(1)}k';
    }
    return value.round().toString();
  }

  // Pad the y-range to 200-kcal boundaries so the tick labels land on
  // the chart edges instead of overlapping outside the plot.
  double _floor(List<TrendPoint> s) {
    final min = s.fold<double>(
      1e9,
      (m, p) => p.kcal < m ? p.kcal.toDouble() : m,
    );
    return ((((min - 40) / 200).floor()) * 200).toDouble();
  }

  double _ceil(List<TrendPoint> s) {
    final max = s.fold<double>(0, (m, p) => p.kcal > m ? p.kcal.toDouble() : m);
    return ((((max + 40) / 200).ceil()) * 200).toDouble();
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard({required this.state});

  final InsightsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final percent = (state.balanceCompletion * 100).round();

    final palette = {
      MacroKind.protein: colors.macroProtein,
      MacroKind.carbs: colors.macroCarbs,
      MacroKind.fat: colors.macroFat,
    };

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Row(
        spacing: 22,
        children: [
          ProgressRing(
            size: 118,
            segments: [
              for (final (kind, share) in state.balance)
                RingSegment(value: share / 100, color: palette[kind]!),
            ],
            semanticLabel: l10n.ofTargets('$percent'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percent%',
                  style: AppTypography.value20.copyWith(
                    color: scheme.onSurface,
                    fontSize: 22,
                  ),
                ),
                Text(
                  l10n.ofTargetsCaption,
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              spacing: 14,
              children: [
                for (final (kind, share) in state.balance)
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: palette[kind],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.macroLabel(kind),
                          style: AppTypography.caption.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      Text(
                        '$share%',
                        style: AppTypography.caption.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
