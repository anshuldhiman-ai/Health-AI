import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/format/count_format.dart';
import 'package:app/data/preferences/body_metrics_controller.dart';
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
import 'package:app/features/today/application/today_state.dart';
import 'package:app/l10n/app_localizations.dart';

/// Dashboard Home Page matching ui_design2.jpg Screen 1 & user specifications:
/// - Top Bar: Menu hamburger, "Health AI" centered logo, user avatar
/// - Dynamic time-based greeting with user's name: "Good morning, [Name]!"
/// - Calories Circle showing total calories eaten today & remaining
/// - Moving transition Daily Activity area (Steps, Water, Sleep, Active Cal)
/// - Today's Macros in short (Protein, Carbs, Fats) - Clickable to open
///   the 3-tab Macro Breakdown Screen showing dish contributions!
/// - Clean & uncluttered: no extra things on the home page.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todayStateProvider);
    final metrics = ref.watch(bodyMetricsProvider);
    final scheme = Theme.of(context).colorScheme;

    final greeting = _timeGreeting();
    final displayName = metrics.name.trim().isNotEmpty ? metrics.name.trim() : 'there';

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
            const SizedBox(height: 18),
            // Dynamic Time-based greeting with user's name
            Text(
              '$greeting, $displayName!',
              style: AppTypography.hero.copyWith(
                color: scheme.onSurface,
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Personalized your morning & daily wellness.',
              style: AppTypography.bodyM.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            // Hero Calories Progress Circle Card
            _CaloriesRingCard(state: state),
            const SizedBox(height: 16),
            // Moving Transition Daily Activity Area
            const _DailyActivityCard(),
            const SizedBox(height: 16),
            // Today's Macros in short: Protein, Carbs, Fats (Clickable)
            _MacronutrientsShortCard(state: state),
          ],
        ),
      ),
    );
  }

  static String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    return 'Good evening';
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
            LeafGlyph(size: 22, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              'Health AI',
              style: AppTypography.itemTitle.copyWith(
                fontSize: 19,
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
              child: Container(
                color: scheme.surface,
                child: Icon(Icons.person_rounded, size: 22, color: scheme.primary),
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
                title: const Text('Food Diary', style: AppTypography.itemS),
                subtitle: const Text(
                  'Daily meal log & calorie breakdown',
                  style: AppTypography.caption,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/diary');
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Hero Calories Ring Card showing total calories eaten today & remaining
class _CaloriesRingCard extends StatelessWidget {
  const _CaloriesRingCard({required this.state});

  final TodayState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          ProgressRing(
            progress: state.ringProgress,
            size: 176,
            strokeWidth: 15,
            gradientColors: colors.calorieRingColors,
            semanticLabel: 'Calories eaten: ${state.caloriesEaten} of ${state.targetCalories} kcal',
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
                  formatCount(state.caloriesEaten),
                  style: text.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 34,
                    letterSpacing: -0.5,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  'eaten today',
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatCount(state.caloriesRemaining)} kcal left',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Subtle target progress label
          Text(
            'Daily Goal: ${state.targetCalories} kcal',
            style: AppTypography.caption.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Moving transition Daily Activity area (Steps, Water, Sleep, Active Cal)
class _DailyActivityCard extends ConsumerStatefulWidget {
  const _DailyActivityCard();

  @override
  ConsumerState<_DailyActivityCard> createState() => _DailyActivityCardState();
}

class _DailyActivityCardState extends ConsumerState<_DailyActivityCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

    return FadeTransition(
      opacity: _anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic)),
        child: AppCard(
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
                        fontWeight: FontWeight.w700,
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
                      if (steps.valueOrNull?.status == StepStatus.permissionDenied) {
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
        ),
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
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: ringColor, size: 24),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.itemS.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Today's Macronutrients card in short: [Protein] [Carbs] [Fats]
/// Tapping on any of them navigates to the 3-tab Macro Breakdown Screen!
class _MacronutrientsShortCard extends StatelessWidget {
  const _MacronutrientsShortCard({required this.state});

  final TodayState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    final protein = state.macros.firstWhere(
      (m) => m.kind == MacroKind.protein,
      orElse: () => const MacroLine(kind: MacroKind.protein, value: 0, target: 100),
    );
    final carbs = state.macros.firstWhere(
      (m) => m.kind == MacroKind.carbs,
      orElse: () => const MacroLine(kind: MacroKind.carbs, value: 0, target: 180),
    );
    final fat = state.macros.firstWhere(
      (m) => m.kind == MacroKind.fat,
      orElse: () => const MacroLine(kind: MacroKind.fat, value: 0, target: 60),
    );

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Macronutrients',
                style: AppTypography.titleM.copyWith(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Tap for dish breakdown',
                style: AppTypography.caption.copyWith(
                  color: colors.primary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ClickableMacroItem(
                  label: 'Protein',
                  amount: '${protein.value}g',
                  target: '${protein.target}g',
                  color: colors.macroProtein,
                  onTap: () => context.push('/macro-breakdown?kind=protein'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ClickableMacroItem(
                  label: 'Carbs',
                  amount: '${carbs.value}g',
                  target: '${carbs.target}g',
                  color: colors.macroCarbs,
                  onTap: () => context.push('/macro-breakdown?kind=carbs'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ClickableMacroItem(
                  label: 'Fats',
                  amount: '${fat.value}g',
                  target: '${fat.target}g',
                  color: colors.macroFat,
                  onTap: () => context.push('/macro-breakdown?kind=fat'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClickableMacroItem extends StatelessWidget {
  const _ClickableMacroItem({
    required this.label,
    required this.amount,
    required this.target,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String amount;
  final String target;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                amount,
                style: AppTypography.itemTitle.copyWith(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Goal $target',
                style: AppTypography.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
