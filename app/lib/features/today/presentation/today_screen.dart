import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/format/count_format.dart';
import 'package:app/app/log_store.dart';
import 'package:app/data/preferences/sleep_controller.dart';
import 'package:app/data/preferences/water_controller.dart';
import 'package:app/data/sensors/step_tracker.dart';
import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/components/meter_bar.dart';
import 'package:app/design_system/components/progress_ring.dart';
import 'package:app/design_system/components/stat_tile.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/macro.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/domain/entities/log_entry.dart';
import 'package:app/features/today/application/today_state.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/extensions.dart';

/// Dashboard per ref_ui.png/ref_ui2.png: date, greeting, calorie ring,
/// live on-track insight, activity/water/sleep tiles and quick actions.
///
/// Food-history detail deliberately lives in Diary, so the two screens
/// do not repeat the same meal list.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todayStateProvider);
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final hour = DateTime.now().hour;
    final greeting = switch (hour) {
      < 12 => l10n.greetingMorning,
      < 17 => l10n.greetingAfternoon,
      _ => l10n.greetingEvening,
    };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.x2,
            AppSpacing.screenPadding,
            104, // clears the floating nav + docked scan button
          ),
          children: [
            const _Header(),
            const SizedBox(height: 14),
            Text(greeting, style: text.displayLarge),
            const SizedBox(height: 4),
            Text(
              l10n.todayTagline,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _CaloriesRingCard(state: state),
            const SizedBox(height: 12),
            _TrackBanner(state: state),
            const SizedBox(height: 12),
            const _HealthTiles(),
            const SizedBox(height: 20),
            const _TodaysMeals(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateLabel = MaterialLocalizations.of(context)
        .formatMediumDate(DateTime.now());

    return Row(
      children: [
        // Date + chevron: the reference lets the user jump between
        // days straight from the dashboard header. No chip background:
        // a filled pill here reads heavier than the reference.
        Icon(Icons.calendar_today_outlined, size: 17, color: scheme.onSurface),
        const SizedBox(width: 8),
        Text(
          dateLabel,
          style: AppTypography.itemS.copyWith(
            color: scheme.onSurface,
            fontSize: 13.5,
          ),
        ),
        Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 18,
          color: scheme.onSurfaceVariant,
        ),
        const Spacer(),
        // Notification bell.
        Icon(
          Icons.notifications_none_rounded,
          size: 21,
          color: scheme.onSurface,
        ),
      ],
    );
  }
}

class _CaloriesRingCard extends StatelessWidget {
  const _CaloriesRingCard({required this.state});

  final TodayState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      child: Row(
        children: [
          ProgressRing(
            progress: state.ringProgress,
            size: 122,
            strokeWidth: 11,
            semanticLabel:
                '${l10n.remainingKcal}: '
                '${formatCount(state.caloriesRemaining)} ${l10n.kcalUnit}',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.remainingKcal,
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  formatCount(state.caloriesRemaining),
                  style: text.headlineMedium,
                ),
                Text(
                  l10n.kcalUnit,
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              spacing: 12,
              children: [
                for (final macro in state.macros)
                  MeterBar(
                    label: l10n.macroLabel(macro.kind),
                    value: macro.value,
                    target: macro.target,
                    barColor: switch (macro.kind) {
                      MacroKind.protein => colors.macroProtein,
                      MacroKind.carbs => colors.macroCarbs,
                      MacroKind.fat => colors.macroFat,
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackBanner extends StatelessWidget {
  const _TrackBanner({required this.state});

  final TodayState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    final (icon, title, body, tint, ink) = state.isEmpty
        ? (
            Icons.restaurant_rounded,
            l10n.startDayTitle,
            l10n.startDayBody,
            colors.accentWash,
            scheme.onSurface,
          )
        : state.isOverTarget
        ? (
            Icons.info_outline_rounded,
            l10n.overTargetTitle,
            l10n.overTargetBody(formatCount(state.caloriesOver)),
            colors.accentWash,
            scheme.onSurface,
          )
        : (
            Icons.check_circle_rounded,
            l10n.onTrackTitle,
            l10n.onTrackBody(
              formatCount(state.caloriesRemaining),
              '${state.proteinRemaining}',
            ),
            colors.primaryWash,
            scheme.onSurface,
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Icon(
            icon,
            size: 20,
            color: state.isOverTarget && !state.isEmpty
                ? colors.accent
                : scheme.primary,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.itemS.copyWith(
                    color: ink,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.4,
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

class _HealthTiles extends ConsumerWidget {
  const _HealthTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(stepTrackerProvider);
    final water = ref.watch(waterTodayProvider);
    final sleep = ref.watch(sleepTodayProvider);
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final snapshot = steps.valueOrNull;
    final live = snapshot?.isLive ?? false;
    final distance = snapshot?.distanceKm ?? 0;
    final stepsCaption = live && distance >= 0.05
        ? l10n.stepsDistanceCaption(distance.toStringAsFixed(1))
        : l10n.stepsTile;
    final sleepValue = sleep == null
        ? '—'
        : formatSleepDuration(l10n, sleep.durationMinutes);

    return Row(
      spacing: AppSpacing.x3,
      children: [
        StatTile(
          icon: Icons.directions_walk_rounded,
          iconColor: colors.primary,
          value: stepTileLabel(steps),
          caption: stepsCaption,
          expanded: true,
          onTap: () => context.push('/activity'),
        ),
        StatTile(
          icon: Icons.water_drop_rounded,
          iconColor: colors.water,
          value: '${water.liters.toStringAsFixed(1)} L',
          caption: l10n.waterTile,
          expanded: true,
          onTap: () => context.push('/water'),
        ),
        StatTile(
          icon: Icons.bedtime_rounded,
          iconColor: colors.sleep,
          value: sleepValue,
          caption: l10n.sleepTile,
          expanded: true,
          onTap: () => context.push('/sleep'),
        ),
      ],
    );
  }
}

/// "Today's Meals": the day's meal log, straight from the shared
/// store. This is the block the reference dashboard is built around -
/// without it the dashboard ends in a large empty canvas.
class _TodaysMeals extends ConsumerWidget {
  const _TodaysMeals();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final log = ref.watch(dayLogProvider);
    final entries = log[0] ?? const <LogEntry>[];

    final byMeal = <MealKind, List<LogEntry>>{
      for (final entry in entries) entry.mealKind: [],
    };
    for (final entry in entries) {
      byMeal[entry.mealKind]!.add(entry);
    }

    // The meals a person eats in order, so the list always reads as a
    // day rather than as whatever was logged first.
    const order = [
      MealKind.breakfast,
      MealKind.lunch,
      MealKind.dinner,
      MealKind.snacks,
    ];
    final shown = order.where(byMeal.containsKey).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.todaysMeals,
          style: AppTypography.titleM.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 10),
        if (shown.isEmpty)
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x4,
              vertical: AppSpacing.x3,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primaryWash,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restaurant_rounded,
                    size: 20,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.logFirstMealCta,
                    style: AppTypography.itemS.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _AddFoodChip(
                  label: l10n.addFood,
                  onTap: () => context.push(
                    '/search?day=0&meal=${mealForHour(DateTime.now().hour).name}',
                  ),
                ),
              ],
            ),
          )
        else
          for (final meal in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TodayMealRow(meal: meal, entries: byMeal[meal]!),
            ),
      ],
    );
  }
}

/// One meal line: kind, what was logged, and the day's total.
class _TodayMealRow extends StatelessWidget {
  const _TodayMealRow({required this.meal, required this.entries});

  final MealKind meal;
  final List<LogEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    final kcal = entries.fold<int>(0, (sum, e) => sum + e.kcal);
    final dish = entries.length == 1
        ? entries.first.dish
        : '${entries.length} ${l10n.mealsTab.toLowerCase()}';

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => context.push('/diary'),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primaryWash,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_rounded,
              size: 19,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.mealLabel(meal),
                  style: AppTypography.itemS.copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  dish,
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
            '${formatCount(kcal)} ${l10n.kcalUnit}',
            style: AppTypography.caption.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 13,
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

/// The light-green "Add Food" chip from the reference meal row.
class _AddFoodChip extends StatelessWidget {
  const _AddFoodChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return Material(
      color: colors.primaryWash,
      borderRadius: BorderRadius.circular(AppRadii.pill.x),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill.x),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

String formatSleepDuration(AppLocalizations l10n, int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return l10n.durationMinutes('$rest');
  return l10n.durationHoursMinutes('$hours', '$rest');
}
