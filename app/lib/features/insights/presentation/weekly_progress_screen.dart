import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/app/log_store.dart';
import 'package:app/core/format/count_format.dart';
import 'package:app/data/preferences/goal_kind_controller.dart';
import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/components/empty_state.dart';
import 'package:app/design_system/components/meter_bar.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/macro.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/domain/entities/nutrition_targets.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/extensions.dart';

enum _WeekTab { calories, macros, meals }

class _DayStat {
  const _DayStat({
    required this.date,
    required this.kcal,
    required this.target,
    required this.entries,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final DateTime date;
  final int kcal;
  final int target;
  final int entries;
  final int protein;
  final int carbs;
  final int fat;

  bool get logged => entries > 0;

  bool get onTarget => logged && kcal <= target;
}

/// Day-by-day weekly consistency: calories against the plan, average
/// macro completion and the week's meal split. It complements the
/// longer 30/90-day trend in Insights instead of repeating it.
class WeeklyProgressScreen extends ConsumerStatefulWidget {
  const WeeklyProgressScreen({super.key});

  @override
  ConsumerState<WeeklyProgressScreen> createState() =>
      _WeeklyProgressScreenState();
}

class _WeeklyProgressScreenState extends ConsumerState<WeeklyProgressScreen> {
  _WeekTab _tab = _WeekTab.calories;
  int _selected = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final targets = ref.watch(nutritionTargetsProvider);
    ref.watch(dayLogProvider);
    final log = ref.read(dayLogProvider.notifier);
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);

    final days = [
      for (var offset = 6; offset >= 0; offset--)
        () {
          final date = todayDay.subtract(Duration(days: offset));
          final totals = log.totalsFor(offset);
          return _DayStat(
            date: date,
            kcal: totals.consumed,
            target: targets.kcal,
            entries: log.entriesFor(offset).length,
            protein: totals.protein,
            carbs: totals.carbs,
            fat: totals.fat,
          );
        }(),
    ];
    final loggedDays = days.where((d) => d.logged).length;
    final onTarget = days.where((d) => d.onTarget).length;
    final avgKcal = (days.fold<int>(0, (s, d) => s + d.kcal) / 7).round();
    final selected = days[_selected.clamp(0, days.length - 1)];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.x2,
            AppSpacing.screenPadding,
            AppSpacing.x4,
          ),
          children: [
            _Header(title: l10n.weeklyProgress, subtitle: l10n.weeklySubtitle),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryMetric(
                      value: formatCount(avgKcal),
                      label: l10n.weeklyAverage,
                      unit: l10n.kcalUnit,
                    ),
                  ),
                  _SummaryDivider(),
                  Expanded(
                    child: _SummaryMetric(
                      value: '$onTarget/7',
                      label: l10n.daysOnTarget,
                    ),
                  ),
                  _SummaryDivider(),
                  Expanded(
                    child: _SummaryMetric(
                      value: '$loggedDays/7',
                      label: l10n.weeklyConsistency,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _TabStrip(
              tab: _tab,
              onChanged: (tab) => setState(() => _tab = tab),
            ),
            const SizedBox(height: 14),
            if (loggedDays == 0)
              EmptyState(
                icon: Icons.bar_chart_rounded,
                title: l10n.noWeeklyData,
                message: l10n.startDayBody,
              )
            else
              switch (_tab) {
                _WeekTab.calories => _CaloriesTab(
                  days: days,
                  selected: _selected,
                  onSelected: (index) => setState(() => _selected = index),
                ),
                _WeekTab.macros => _MacrosTab(days: days, targets: targets),
                _WeekTab.meals => _MealsTab(log: log),
              },
            if (_tab == _WeekTab.calories && loggedDays > 0) ...[
              const SizedBox(height: 12),
              _SelectedDayCard(day: selected),
            ],
            const SizedBox(height: 18),
            _Note(text: l10n.weeklyNote),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleL.copyWith(color: scheme.onSurface),
              ),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.value, required this.label, this.unit});

  final String value;
  final String label;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.value20.copyWith(
            color: scheme.onSurface,
            fontSize: 20,
          ),
        ),
        if (unit != null)
          Text(
            unit!,
            style: AppTypography.caption.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(
            color: scheme.onSurfaceVariant,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.tab, required this.onChanged});

  final _WeekTab tab;
  final ValueChanged<_WeekTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tabs = [
      (_WeekTab.calories, l10n.caloriesTab),
      (_WeekTab.macros, l10n.macrosTab),
      (_WeekTab.meals, l10n.mealsTab),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appColors.canvas,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final (value, label) in tabs)
            Expanded(
              child: Material(
                color: tab == value ? scheme.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  onTap: () => onChanged(value),
                  borderRadius: BorderRadius.circular(11),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: tab == value
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                        fontWeight: tab == value
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CaloriesTab extends StatelessWidget {
  const _CaloriesTab({
    required this.days,
    required this.selected,
    required this.onSelected,
  });

  final List<_DayStat> days;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final target = days.isEmpty ? 0 : days.first.target;
    final maxKcal = days.fold<int>(target, (m, d) => math.max(m, d.kcal));
    final maxY = ((maxKcal * 1.15) / 500).ceil() * 500.0;
    final weekdays = MaterialLocalizations.of(context).narrowWeekdays;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Text(
                  '${l10n.goalLabel}: ${formatCount(target)} ${l10n.kcalUnit}',
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Container(width: 18, height: 2, color: colors.accent),
                const SizedBox(width: 5),
                Text(
                  l10n.goalLabel,
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => scheme.inverseSurface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                          '${formatCount(rod.toY.round())} ${l10n.kcalUnit}',
                          AppTypography.caption.copyWith(
                            color: scheme.onInverseSurface,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ),
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent) {
                      final index = response?.spot?.touchedBarGroupIndex;
                      if (index != null) onSelected(index);
                    }
                  },
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: scheme.outlineVariant, strokeWidth: 0.7),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: 500,
                      getTitlesWidget: (value, meta) => Text(
                        compactCount(value.round()),
                        style: AppTypography.caption.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            weekdays[days[index].date.weekday % 7],
                            style: AppTypography.caption.copyWith(
                              color: index == selected
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                              fontWeight: index == selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: target.toDouble(),
                      color: colors.accent,
                      strokeWidth: 1.3,
                      dashArray: [5, 4],
                    ),
                  ],
                ),
                barGroups: [
                  for (var i = 0; i < days.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: days[i].kcal.toDouble(),
                          width: 17,
                          color: i == selected
                              ? scheme.primary
                              : scheme.primary.withValues(alpha: 0.40),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacrosTab extends StatelessWidget {
  const _MacrosTab({required this.days, required this.targets});

  final List<_DayStat> days;
  final NutritionTargets targets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final protein = (days.fold<int>(0, (s, d) => s + d.protein) / 7).round();
    final carbs = (days.fold<int>(0, (s, d) => s + d.carbs) / 7).round();
    final fat = (days.fold<int>(0, (s, d) => s + d.fat) / 7).round();
    final rows = [
      (MacroKind.protein, protein, targets.protein, colors.macroProtein),
      (MacroKind.carbs, carbs, targets.carbs, colors.macroCarbs),
      (MacroKind.fat, fat, targets.fat, colors.macroFat),
    ];

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.weeklyAverage,
            style: AppTypography.itemS.copyWith(
              color: scheme.onSurface,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 14),
          for (final (kind, value, target, color) in rows) ...[
            MeterBar(
              label: l10n.macroLabel(kind),
              value: value,
              target: target,
              barColor: color,
            ),
            const SizedBox(height: 14),
          ],
          Text(
            l10n.weeklyNote,
            style: AppTypography.caption.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealsTab extends StatelessWidget {
  const _MealsTab({required this.log});

  final DayLog log;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final totals = {
      for (final kind in MealKind.values)
        kind: [
          for (var offset = 0; offset < 7; offset++)
            log.kcalForMeal(offset, kind),
        ].fold<int>(0, (sum, value) => sum + value),
    };
    final max = totals.values.fold<int>(1, math.max);
    final palette = [
      colors.macroProtein,
      colors.macroCarbs,
      colors.macroFat,
      colors.water,
    ];

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        children: [
          for (var i = 0; i < MealKind.values.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.mealLabel(MealKind.values[i]),
                    style: AppTypography.caption.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                Text(
                  '${formatCount((totals[MealKind.values[i]]! / 7).round())} '
                  '${l10n.kcalUnit}',
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: totals[MealKind.values[i]]! / max,
                minHeight: 7,
                backgroundColor: context.appColors.canvas,
                valueColor: AlwaysStoppedAnimation(palette[i]),
              ),
            ),
            const SizedBox(height: 13),
          ],
        ],
      ),
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  const _SelectedDayCard({required this.day});

  final _DayStat day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final over = day.kcal > day.target;
    final difference = (day.kcal - day.target).abs();
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MaterialLocalizations.of(context).formatMediumDate(day.date),
                  style: AppTypography.itemS.copyWith(
                    color: scheme.onSurface,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatCount(day.kcal)} / ${formatCount(day.target)} '
                  '${l10n.kcalUnit}',
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: over
                  ? context.appColors.accentWash
                  : context.appColors.primaryWash,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              over
                  ? l10n.kcalOverShort(formatCount(difference))
                  : l10n.kcalLeftShort(formatCount(difference)),
              style: AppTypography.caption.copyWith(
                color: over ? context.appColors.accent : scheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.accentWash,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 9,
        children: [
          Icon(Icons.info_outline_rounded, size: 17, color: colors.accent),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
