import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/design_system/components/empty_state.dart';
import 'package:app/design_system/components/group_header.dart';
import 'package:app/design_system/components/meter_bar.dart';
import 'package:app/design_system/components/progress_ring.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/app/log_store.dart';
import 'package:app/domain/entities/macro.dart';
import 'package:app/features/diary/application/diary_state.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/extensions.dart';

/// Diary per ref_ui.png: week strip (last 7 days, switchable), the
/// selected day's calories summary with "left" chip, per-meal bars,
/// nutrition breakdown donut, meal log list, empty-day CTA.
class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  /// UI window: today + the six previous days.
  static const maxOffset = DayLog.maxDays - 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            Text(l10n.diaryTitle, style: text.titleLarge),
            const SizedBox(height: AppSpacing.x4),
            _WeekStrip(),
            const SizedBox(height: AppSpacing.x4),
            _DayBody(),
          ],
        ),
      ),
    );
  }
}

class _WeekStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final today = DateTime.now();
    final selectedOffset = ref.watch(selectedDiaryOffsetProvider);

    return Row(
      spacing: AppSpacing.x2,
      children: [
        for (var i = DiaryScreen.maxOffset; i >= 0; i--)
          Expanded(
            child: _DayChip(
              label: _weekdayAbbrev(
                l10n,
                today.subtract(Duration(days: i)).weekday,
              ),
              dayOfMonth: today.subtract(Duration(days: i)).day,
              selected: i == selectedOffset,
              onTap: () =>
                  ref.read(selectedDiaryOffsetProvider.notifier).state = i,
            ),
          ),
      ],
    );
  }

  static String _weekdayAbbrev(AppLocalizations l10n, int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return l10n.wdMon;
      case DateTime.tuesday:
        return l10n.wdTue;
      case DateTime.wednesday:
        return l10n.wdWed;
      case DateTime.thursday:
        return l10n.wdThu;
      case DateTime.friday:
        return l10n.wdFri;
      case DateTime.saturday:
        return l10n.wdSat;
      case DateTime.sunday:
      default:
        return l10n.wdSun;
    }
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.dayOfMonth,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int dayOfMonth;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card.x),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.card.x),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline,
          ),
        ),
        child: Column(
          spacing: 2,
          children: [
            Text(
              label,
              style: text.labelSmall?.copyWith(
                color: selected
                    ? scheme.onPrimary
                    : scheme.onSurfaceVariant,
              ),
            ),
            Text(
              '$dayOfMonth',
              style: text.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kept simple: the strip owns selection locally; reading the
    // latest offset family provider through a dependency would need
    // an InheritedWidget — the strip passes it via a shared provider
    // below instead (selectedDiaryOffset).
    final offset = ref.watch(selectedDiaryOffsetProvider);
    final state = ref.watch(diaryStateProvider(offset));
    final l10n = AppLocalizations.of(context)!;

    if (state.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.x2),
        child: EmptyState(
          icon: Icons.no_meals_outlined,
          title: l10n.logFirstMealCta,
          message: l10n.emptyDayHint,
          actionLabel: l10n.addFood,
          onAction: () => context.push('/scan'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.x4,
      children: [
        _CaloriesCard(
          consumed: state.caloriesConsumed,
          target: state.caloriesTarget,
          remaining: state.caloriesRemaining,
        ),
        _MealBars(bars: state.mealBars),
        GroupHeader(title: l10n.nutritionBreakdown),
        _BreakdownCard(state: state),
        GroupHeader(title: l10n.mealLog),
        for (final entry in state.mealLog) _MealLogRow(entry: entry),
      ],
    );
  }
}

/// The selected diary day, written by the week strip and read by the
/// body. Local-vs-shared state note: one small provider is simpler
/// and rebuilds only the body.
final selectedDiaryOffsetProvider = StateProvider<int>((ref) => 0);

class _CaloriesCard extends StatelessWidget {
  const _CaloriesCard({
    required this.consumed,
    required this.target,
    required this.remaining,
  });

  final int consumed;
  final int target;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.card.x),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$consumed',
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  ' / $target ${l10n.kcalUnit}',
                  style: text.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadii.pill.x),
            ),
            child: Text(
              l10n.caloriesLeft('$remaining'),
              style: text.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealBars extends StatelessWidget {
  const _MealBars({required this.bars});

  final List<MealBar> bars;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final maxKcal =
        bars.fold<int>(1, (m, b) => m > b.calories ? m : b.calories);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.card.x),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final bar in bars) ...[
            if (bar != bars.first)
              const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.x2,
                children: [
                  Text('${bar.calories}', style: text.labelMedium),
                  Container(
                    height: 64,
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: bar.calories / maxKcal,
                      widthFactor: bar.calories == 0 ? 0 : 0.55,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius:
                              BorderRadius.circular(AppRadii.pill.x),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    l10n.mealLabel(bar.mealKind),
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.state});

  final DiaryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final percent = (state.targetsCompletion * 100).round();

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
            progress: state.targetsCompletion,
            size: 108,
            strokeWidth: 9,
            semanticLabel: l10n.ofTargets('$percent'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percent%',
                  style: text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              spacing: AppSpacing.x3,
              children: [
                Text(
                  l10n.ofTargets('$percent'),
                  style: text.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                for (final macro in state.macros)
                  MeterBar(
                    label: l10n.macroLabel(macro.kind),
                    value: macro.value,
                    target: macro.target,
                    barColor:
                        macro.kind == MacroKind.carbs ? scheme.tertiary : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealLogRow extends StatelessWidget {
  const _MealLogRow({required this.entry});

  final MealLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.x3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.card.x),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadii.input.x),
            ),
            child: Icon(
              Icons.restaurant_outlined,
              color: scheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(entry.dish, style: text.titleSmall),
                Text(
                  l10n.mealLabel(entry.mealKind),
                  style: text.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.calories} ${l10n.kcalUnit}',
            style: text.labelLarge,
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    );
  }
}
