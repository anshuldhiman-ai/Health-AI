import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/design_system/components/group_header.dart';
import 'package:app/design_system/components/progress_ring.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/features/insights/application/insights_state.dart';
import 'package:app/domain/entities/macro.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/extensions.dart';

/// Insights per ref_ui.png: range chips, calorie-trend chart, nutrition
/// balance ring. Charts are always paired with a text summary so
/// screen readers get the real information (R14).
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(insightsStateProvider);
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.x4,
            AppSpacing.screenPadding,
            AppSpacing.x6,
          ),
          children: [
            Text(l10n.insightsTitle, style: text.titleLarge),
            const SizedBox(height: AppSpacing.x4),
            const _RangeChips(),
            const SizedBox(height: AppSpacing.x4),
            _TrendCard(state: state),
            const SizedBox(height: AppSpacing.x6),
            GroupHeader(title: l10n.nutritionBalance),
            const SizedBox(height: AppSpacing.x3),
            _BalanceCard(state: state),
          ],
        ),
      ),
    );
  }
}

class _RangeChips extends StatefulWidget {
  const _RangeChips();

  @override
  State<_RangeChips> createState() => _RangeChipsState();
}

class _RangeChipsState extends State<_RangeChips> {
  int _selected = 0;

  static const _labels = <String>['7D', '30D', '90D'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      spacing: AppSpacing.x2,
      children: [
        for (var i = 0; i < _labels.length; i++)
          ChoiceChip.elevated(
            label: Text(_labels[i]),
            selected: i == _selected,
            showCheckmark: false,
            onSelected: (_) => setState(() => _selected = i),
            backgroundColor: scheme.surface,
            selectedColor: scheme.primary,
            // TODO(M1/M3): 30D/90D ranges feed from the DB series.
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.pill.x),
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
    final text = Theme.of(context).textTheme;
    final up = state.trendChangePercent >= 0;
    final change = up
        ? l10n.trendChangeUp('${state.trendChangePercent}')
        : l10n.trendChangeDown('${state.trendChangePercent}');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.card.x),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.x3,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.calorieTrend, style: text.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadii.pill.x),
                ),
                // Text + arrow, not colour alone (R14).
                child: Text(
                  change,
                  style: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${state.avgKcalPerDay}',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                ' ${l10n.avgKcalPerDay}',
                style: text.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 140,
            // The chart itself is a graphic; the numbers above are the
            // accessible summary of the same data.
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: scheme.outlineVariant,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (final p in state.trend)
                        FlSpot(p.dayIndex.toDouble(), p.kcal.toDouble()),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.3,
                    barWidth: 3,
                    color: scheme.primary,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: scheme.primary.withValues(alpha: 0.12),
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

  // Pad the y-range so the line doesn't kiss the card edges.
  double _floor(List<TrendPoint> s) {
    final min = s.fold<double>(
      1e9,
      (m, p) => p.kcal < m ? p.kcal.toDouble() : m,
    );
    return (min - 60).floorToDouble();
  }

  double _ceil(List<TrendPoint> s) {
    final max = s.fold<double>(0, (m, p) => p.kcal > m ? p.kcal.toDouble() : m);
    return (max + 60).ceilToDouble();
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard({required this.state});

  final InsightsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final percent = (state.balanceCompletion * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.card.x),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        spacing: AppSpacing.x4,
        children: [
          ProgressRing(
            progress: state.balanceCompletion,
            size: 108,
            strokeWidth: 9,
            semanticLabel: '$percent%',
            child: Text(
              '$percent%',
              style: text.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Column(
              spacing: AppSpacing.x2,
              children: [
                for (final (kind, share) in state.balance)
                  Row(
                    spacing: AppSpacing.x2,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: kind == MacroKind.carbs
                              ? scheme.tertiary
                              : scheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          l10n.macroLabel(kind),
                          style: text.labelLarge,
                        ),
                      ),
                      Text(
                        '$share%',
                        style: text.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
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
