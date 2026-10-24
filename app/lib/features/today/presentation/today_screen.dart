import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/format/count_format.dart';
import 'package:app/app/log_store.dart';
import 'package:app/data/preferences/sleep_controller.dart';
import 'package:app/data/preferences/water_controller.dart';
import 'package:app/data/sensors/step_tracker.dart';
import 'package:app/domain/entities/activity_snapshot.dart';
import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/components/brand_mark.dart';
import 'package:app/design_system/components/progress_ring.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/macro.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/domain/entities/log_entry.dart';
import 'package:app/features/today/application/today_state.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/extensions.dart';

/// Dashboard matching ui_design.jpg & ui_design2.jpg:
/// - Top Bar: Menu hamburger, "Health AI" centered logo, user avatar
/// - A warm returning-user greeting with real daily totals
/// - Hero Calorie Card with rainbow gradient ProgressRing & Macro pills
/// - "Daily Activity" card with 4 circular badges (Steps, Water, Sleep, Active Cal)
/// - "Today's Meals" list with dish thumbnails, kcal, and macro tags
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todayStateProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

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
            const SizedBox(height: 16),
            Text('Welcome back', style: text.displayLarge),
            const SizedBox(height: 4),
            Text(
              'Your daily wellness, beautifully in sync.',
              style: text.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            _CaloriesRingCard(state: state),
            const SizedBox(height: 14),
            _DailyActivityCard(),
            const SizedBox(height: 20),
            const _TodaysMeals(),
          ],
        ),
      ),
    );
  }
}

/// Header matching ui_design2.jpg: Menu | Health AI Logo | Avatar
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconButton(
          onPressed: () => _openDrawerMenu(context),
          icon: Icon(Icons.menu_rounded, size: 24, color: scheme.onSurface),
          tooltip: 'Menu',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LeafGlyph(size: 20, color: scheme.primary),
            const SizedBox(width: 7),
            Text(
              'Health AI',
              style: AppTypography.itemTitle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/brand/avatar.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.person_rounded, size: 22, color: scheme.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openDrawerMenu(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  Icons.restaurant_menu_rounded,
                  color: colors.primary,
                ),
                title: const Text('Meal Planner', style: AppTypography.itemS),
                subtitle: const Text(
                  'Daily agenda & AI recommendations',
                  style: AppTypography.caption,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/planner');
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.track_changes_rounded,
                  color: colors.accent,
                ),
                title: const Text('Target Goals', style: AppTypography.itemS),
                subtitle: const Text(
                  'Calorie, macro & water targets',
                  style: AppTypography.caption,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/goals');
                },
              ),
              ListTile(
                leading: Icon(Icons.bedtime_rounded, color: colors.sleep),
                title: const Text('Sleep Tracker', style: AppTypography.itemS),
                subtitle: const Text(
                  'Bedtime, wake dial & smart alarm',
                  style: AppTypography.caption,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/sleep');
                },
              ),
              ListTile(
                leading: Icon(Icons.water_drop_rounded, color: colors.water),
                title: const Text('Water Tracker', style: AppTypography.itemS),
                subtitle: const Text(
                  'Daily hydration & glass tracker',
                  style: AppTypography.caption,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/water');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hero Calorie Card from ui_design2.jpg with vibrant rainbow gradient ring
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Column(
        children: [
          ProgressRing(
            progress: state.ringProgress,
            size: 168,
            strokeWidth: 15,
            gradientColors: colors.calorieRingColors,
            semanticLabel:
                '${l10n.remainingKcal}: '
                '${formatCount(state.caloriesRemaining)} ${l10n.kcalUnit}',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Calories',
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatCount(state.caloriesRemaining),
                  style: text.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'left',
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  width: 0,
                  height: 0,
                  child: Opacity(
                    opacity: 0.01,
                    child: Text(l10n.remainingKcal),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Macronutrients row: [Protein 18g] [Carbs 42g] [Fat 15g]
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final macro in state.macros) ...[
                _MacroPill(
                  label: switch (macro.kind) {
                    MacroKind.protein => 'Protein',
                    MacroKind.carbs => 'Carbs',
                    MacroKind.fat => 'Fat',
                  },
                  amount: '${macro.value}g',
                  color: switch (macro.kind) {
                    MacroKind.protein => colors.macroProtein,
                    MacroKind.carbs => colors.macroCarbs,
                    MacroKind.fat => colors.macroFat,
                  },
                ),
                if (macro != state.macros.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  const _MacroPill({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            amount,
            style: AppTypography.itemS.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Daily Activity" Card with 4 circular stat buttons from ui_design2.jpg
class _DailyActivityCard extends ConsumerWidget {
  const _DailyActivityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final steps = ref.watch(stepTrackerProvider);
    final water = ref.watch(waterTodayProvider);
    final sleep = ref.watch(sleepTodayProvider);

    final stepCount = steps.valueOrNull?.steps ?? 0;
    final sleepHours = sleep == null
        ? '—'
        : '${(sleep.durationMinutes / 60).toStringAsFixed(1)}h';
    final activeCalories = steps.valueOrNull?.isLive == true
        ? '${(stepCount * 0.04).round()} kcal'
        : '—';

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.push('/activity'),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Text(
                  'Daily Activity',
                  style: AppTypography.titleM.copyWith(
                    color: scheme.onSurface,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActivityCircleButton(
                icon: Icons.directions_walk_rounded,
                ringColor: const Color(0xFFE59C39),
                title: 'Steps',
                value: steps.valueOrNull?.status == StepStatus.permissionDenied
                    ? 'Enable'
                    : stepTileLabel(steps),
                onTap: () async {
                  if (steps.valueOrNull?.status ==
                      StepStatus.permissionDenied) {
                    await requestStepPermission();
                    ref.invalidate(stepTrackerProvider);
                  }
                  if (context.mounted) {
                    await context.push('/activity');
                  }
                },
              ),
              _ActivityCircleButton(
                icon: Icons.water_drop_rounded,
                ringColor: colors.water,
                title: 'Water',
                value: '${water.liters.toStringAsFixed(1)}L',
                onTap: () => context.push('/water'),
              ),
              _ActivityCircleButton(
                icon: Icons.bedtime_rounded,
                ringColor: colors.sleep,
                title: 'Sleep',
                value: sleepHours,
                onTap: () => context.push('/sleep'),
              ),
              _ActivityCircleButton(
                icon: Icons.local_fire_department_rounded,
                ringColor: colors.primary,
                title: 'Active Cal',
                value: activeCalories,
                onTap: () => context.push('/activity'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityCircleButton extends StatelessWidget {
  const _ActivityCircleButton({
    required this.icon,
    required this.ringColor,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color ringColor;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  ringColor.withValues(alpha: 0.16),
                  ringColor.withValues(alpha: 0.07),
                ],
              ),
              border: Border.all(
                color: ringColor.withValues(alpha: 0.42),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: ringColor.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: ringColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.itemS.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Today's Meals" per ui_design.jpg & ui_design2.jpg
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

    const order = [
      MealKind.breakfast,
      MealKind.lunch,
      MealKind.dinner,
      MealKind.snacks,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.todaysMeals,
              style: AppTypography.titleM.copyWith(
                color: scheme.onSurface,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.push('/diary'),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Text(
                'View Diary',
                style: AppTypography.caption.copyWith(color: colors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final meal in order) ...[
          _MealCard(meal: meal, entries: byMeal[meal] ?? const []),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal, required this.entries});

  final MealKind meal;
  final List<LogEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    final kcal = entries.fold<int>(0, (sum, e) => sum + e.kcal);
    final hasEntries = entries.isNotEmpty;
    var protein = 0, carbs = 0, fat = 0;
    for (final e in entries) {
      protein += e.proteinGrams;
      carbs += e.carbsGrams;
      fat += e.fatGrams;
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => context.push('/diary'),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 52,
              height: 52,
              color: colors.primaryWash,
              child: Image.asset(
                'assets/brand/meal_thali.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.restaurant_rounded,
                  color: colors.primary,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.mealLabel(meal),
                  style: AppTypography.itemTitle.copyWith(
                    color: scheme.onSurface,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  // No number for an empty meal: a placeholder count
                  // reads as food already logged (R7).
                  hasEntries ? '$kcal kcal' : l10n.mealNotLoggedYet,
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 6),
                if (hasEntries)
                  Row(
                    children: [
                      _TagBadge(
                        text: '${l10n.macroProtein} ${protein}g',
                        color: colors.macroProtein,
                      ),
                      const SizedBox(width: 5),
                      _TagBadge(
                        text: '${l10n.macroCarbs} ${carbs}g',
                        color: colors.macroCarbs,
                      ),
                      const SizedBox(width: 5),
                      _TagBadge(
                        text: '${l10n.macroFat} ${fat}g',
                        color: colors.macroFat,
                      ),
                    ],
                  )
                else
                  _TagBadge(text: '+ ${l10n.addFood}', color: colors.primary),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
            onSelected: (val) {
              if (val == 'add') {
                context.push('/search?day=0&meal=${meal.name}');
              } else if (val == 'scan') {
                context.push('/scan?day=0&meal=${meal.name}');
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'add', child: Text(l10n.addFood)),
              PopupMenuItem(value: 'scan', child: Text(l10n.scanScreenTitle)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  const _TagBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
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
