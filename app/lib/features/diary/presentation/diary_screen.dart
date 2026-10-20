import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/app/log_store.dart';
import 'package:app/core/format/count_format.dart';
import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/components/empty_state.dart';
import 'package:app/design_system/components/group_header.dart';
import 'package:app/design_system/components/progress_ring.dart';
import 'package:app/design_system/components/screen_header.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/macro.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/features/diary/application/diary_state.dart';
import 'package:app/features/diary/presentation/meal_detail_sheet.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/extensions.dart';

/// Diary per ref_ui.png: week strip (last 7 days, switchable), the
/// selected day's calories summary with "left" chip and progress bar,
/// per-meal bars, nutrition breakdown donut, meal log list, empty-day
/// CTA.
class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  /// UI window: today + the six previous days.
  static const maxOffset = DayLog.diaryDays - 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedOffset = ref.watch(selectedDiaryOffsetProvider);

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
              icon: Icons.menu_book_rounded,
              title: l10n.diaryTitle,
              trailing: FilledButton.tonalIcon(
                onPressed: () => context.push(
                  '/search?day=$selectedOffset'
                  '&meal=${mealForHour(DateTime.now().hour).name}',
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.addFood),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _WeekStrip(),
            const SizedBox(height: 20),
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
      spacing: 7,
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

    return Material(
      color: selected ? scheme.primary : scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Column(
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: selected
                      ? scheme.onPrimary.withValues(alpha: 0.82)
                      : scheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$dayOfMonth',
                style: AppTypography.itemTitle.copyWith(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          onAction: () => context.push(
            '/search?day=$offset'
            '&meal=${mealForHour(DateTime.now().hour).name}',
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CaloriesBlock(
          consumed: state.caloriesConsumed,
          target: state.caloriesTarget,
          remaining: state.caloriesRemaining,
        ),
        const SizedBox(height: 20),
        _MealBars(bars: state.mealBars),
        const SizedBox(height: 24),
        GroupHeader(title: l10n.nutritionBreakdown),
        const SizedBox(height: 12),
        _BreakdownCard(state: state),
        const SizedBox(height: 24),
        GroupHeader(title: l10n.mealLog),
        const SizedBox(height: 12),
        _MealLog(entries: state.mealLog, dayOffset: offset),
      ],
    );
  }
}

/// The selected diary day, written by the week strip and read by the
/// body. Local-vs-shared state note: one small provider is simpler
/// and rebuilds only the body.
final selectedDiaryOffsetProvider = StateProvider<int>((ref) => 0);

class _CaloriesBlock extends StatelessWidget {
  const _CaloriesBlock({
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
    final colors = context.appColors;
    final progress = (consumed / target).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.caloriesLabel,
          style: AppTypography.titleM.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              formatCount(consumed),
              style: AppTypography.value20.copyWith(
                color: scheme.onSurface,
                fontSize: 22,
              ),
            ),
            Text(
              ' / ${formatCount(target)} ${l10n.kcalUnit}',
              style: AppTypography.bodyM.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadii.pill.x),
              ),
              child: Text(
                l10n.caloriesLeft(formatCount(remaining)),
                style: AppTypography.caption.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill.x),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: scheme.outlineVariant,
            valueColor: AlwaysStoppedAnimation(scheme.primary),
          ),
        ),
      ],
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
    final maxKcal = bars.fold<int>(
      1,
      (m, b) => m > b.calories ? m : b.calories,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 10,
      children: [
        for (final bar in bars)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatCount(bar.calories),
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 62,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: bar.calories == 0
                          ? 0
                          : (10 + 52 * bar.calories / maxKcal) / 62,
                      widthFactor: 0.52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.mealLabel(bar.mealKind),
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
      ],
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
    final colors = context.appColors;
    final percent = (state.targetsCompletion * 100).round();

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Row(
        spacing: 20,
        children: [
          ProgressRing(
            size: 116,
            segments: _macroSegments(state.macros, colors),
            semanticLabel: l10n.ofTargets('$percent'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percent%',
                  style: AppTypography.value20.copyWith(
                    color: scheme.onSurface,
                    fontSize: 24,
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
              spacing: 13,
              children: [
                for (final macro in state.macros)
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: _macroColor(macro.kind, colors),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.macroLabel(macro.kind),
                          style: AppTypography.caption.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      Text(
                        '${formatCount(macro.value)} / '
                        '${formatCount(macro.target)} g',
                        style: AppTypography.caption.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
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

class _MealLog extends StatelessWidget {
  const _MealLog({required this.entries, required this.dayOffset});

  final List<MealLogEntry> entries;
  final int dayOffset;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: Theme.of(context).colorScheme.outline),
            _MealLogRow(
              entry: entries[i],
              onTap: () async {
                final addAnother = await showMealDetailSheet(
                  context,
                  dayOffset: dayOffset,
                  meal: entries[i].mealKind,
                );
                if (addAnother == true && context.mounted) {
                  await context.push(
                    '/search?day=$dayOffset'
                    '&meal=${entries[i].mealKind.name}',
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _MealLogRow extends StatelessWidget {
  const _MealLogRow({required this.entry, required this.onTap});

  final MealLogEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            if (entry.mealKind == MealKind.lunch)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/brand/meal_thali.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primaryWash,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.restaurant, size: 20, color: scheme.primary),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.mealLabel(entry.mealKind),
                    style: AppTypography.itemS.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.dish,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${formatCount(entry.calories)} ${l10n.kcalUnit}',
              style: AppTypography.caption.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// --- macro colour mapping: green / turmeric / mid-green ---

Color _macroColor(MacroKind kind, AppColorScheme colors) {
  return switch (kind) {
    MacroKind.protein => colors.macroProtein,
    MacroKind.carbs => colors.macroCarbs,
    MacroKind.fat => colors.macroFat,
  };
}

List<RingSegment> _macroSegments(
  List<MacroLine> macros,
  AppColorScheme colors,
) {
  final total = macros.fold<double>(0, (sum, m) => sum + m.value);
  if (total <= 0) return const [];
  return [
    for (final m in macros)
      RingSegment(value: m.value / total, color: _macroColor(m.kind, colors)),
  ];
}
