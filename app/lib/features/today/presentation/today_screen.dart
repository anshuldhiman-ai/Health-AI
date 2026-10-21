import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/format/count_format.dart';
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
            88, // cleanly clears the 66dp floating nav + scan button
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
            const SizedBox(height: 12),
            _QuickActions(meal: mealForHour(hour)),
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
        Icon(Icons.calendar_today_outlined, size: 19, color: scheme.onSurface),
        const SizedBox(width: 10),
        Text(
          dateLabel,
          style: AppTypography.itemS.copyWith(color: scheme.onSurface),
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
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      child: Row(
        children: [
          ProgressRing(
            progress: state.ringProgress,
            size: 146,
            strokeWidth: 13,
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
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              spacing: 15,
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

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.meal});

  final MealKind meal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/search?day=0&meal=${meal.name}'),
            icon: const Icon(Icons.search_rounded, size: 19),
            label: Text(l10n.searchFood),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
          ),
        ),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => context.go('/diary'),
            icon: const Icon(Icons.menu_book_rounded, size: 18),
            label: Text(l10n.viewDiary),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
          ),
        ),
      ],
    );
  }
}

String formatSleepDuration(AppLocalizations l10n, int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return l10n.durationMinutes('$rest');
  return l10n.durationHoursMinutes('$hours', '$rest');
}
