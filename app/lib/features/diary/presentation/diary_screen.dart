import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/design_system/components/group_header.dart';
import 'package:app/design_system/components/meter_bar.dart';
import 'package:app/design_system/components/progress_ring.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/macro.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/features/diary/application/diary_state.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/extensions.dart';

/// Diary per ref_ui.png: week strip, calories summary with "left"
/// chip, per-meal bars, nutrition breakdown donut, meal log list.
class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sampleDiaryProvider);
    final l10n = AppLocalizations.of(context)!;

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
            Text(l10n.diaryTitle, style: _pageTitle(context)),
            const SizedBox(height: AppSpacing.x4),
            _WeekStrip(days: state.days),
            const SizedBox(height: AppSpacing.x4),
            _CaloriesCard(
              consumed: state.caloriesConsumed,
              target: state.caloriesTarget,
              remaining: state.caloriesRemaining,
            ),
            const SizedBox(height: AppSpacing.x4),
            _MealBars(bars: state.mealBars),
            const SizedBox(height: AppSpacing.x6),
            GroupHeader(title: l10n.nutritionBreakdown),
            const SizedBox(height: AppSpacing.x3),
            _BreakdownCard(state: state),
            const SizedBox(height: AppSpacing.x6),
            GroupHeader(title: l10n.mealLog),
            const SizedBox(height: AppSpacing.x3),
            for (final entry in state.mealLog)
              _MealLogRow(entry: entry),
          ],
        ),
      ),
    );
  }
}

TextStyle _pageTitle(BuildContext context) => Theme.of(context)
    .textTheme
    .titleLarge ?? const TextStyle(fontSize: 28, fontWeight: FontWeight.w700);

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.days});

  final List<DiaryDay> days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Row(
      spacing: AppSpacing.x2,
      children: [
        for (final day in days)
          Expanded(
            child: InkWell(
              onTap: () {}, // TODO(M1): switch diary date
              borderRadius: BorderRadius.circular(AppRadii.card.x),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: day.isSelected ? scheme.primary : scheme.surface,
                  borderRadius: BorderRadius.circular(AppRadii.card.x),
                  border: Border.all(
                    color: day.isSelected ? scheme.primary : scheme.outline,
                  ),
                ),
                child: Column(
                  spacing: 2,
                  children: [
                    Text(
                      day.weekdayLabel,
                      style: text.labelSmall?.copyWith(
                        color: day.isSelected
                            ? scheme.onPrimary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${day.dayOfMonth}',
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: day.isSelected
                            ? scheme.onPrimary
                            : scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

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
                      widthFactor: 0.55,
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
              entry.mealKind == MealKind.lunch
                  ? Icons.lunch_dining_outlined
                  : Icons.restaurant_outlined,
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
