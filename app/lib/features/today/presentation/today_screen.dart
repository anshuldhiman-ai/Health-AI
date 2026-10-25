import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/format/count_format.dart';
import 'package:app/data/preferences/body_metrics_controller.dart';
import 'package:app/data/preferences/sleep_controller.dart';
import 'package:app/data/preferences/water_controller.dart';
import 'package:app/data/sensors/step_tracker.dart';
import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/components/brand_mark.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/macro.dart';
import 'package:app/domain/entities/sleep_record.dart';
import 'package:app/features/today/application/today_state.dart';

/// Screen 2: Main Dashboard (Welcome Back) matching ref_ui_updated.png
///
/// Features:
/// - Header: "Good morning, [Name]" with circular avatar
/// - Three prominent circular progress indicators side-by-side for
///   Calories Remaining, Current Calories (hero ring), and Active Kcal.
/// - Inline micro-trends entry point
/// - Quick Stats Row: 4 sleek cards for Steps, Water (Liters), Sleep duration, Active Cal
/// - Prominent AI Nutrition Coach / Scan Meal card
/// - Daily Highlights carousel with micro-visualizations & macronutrient balances
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todayStateProvider);
    final metrics = ref.watch(bodyMetricsProvider);
    final c = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    final displayName = metrics.name.trim().isEmpty ? 'Anshul' : metrics.name.trim();

    return Scaffold(
      backgroundColor: c.canvas,
      body: Container(
        decoration: BoxDecoration(
          color: c.canvas,
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              16,
              AppSpacing.screenPadding,
              120, // Clear floating bottom nav bar & scan button
            ),
            children: [
              _HeaderSection(name: displayName),
              const SizedBox(height: 18),

              // Top Section: Calories Ring & Real Macros Intake (Protein, Carbs, Fat)
              _CaloriesAndMacrosCard(state: state),
              const SizedBox(height: 18),

              // Quick Stats Row: Steps, Water, Sleep (Active Cal removed)
              const _QuickStatsGrid(),
              const SizedBox(height: 18),

              // Prominent AI Nutrition Coach Chatbot Entry Card
              const _AiNutritionCoachCard(),
              const SizedBox(height: 20),

              // Daily Highlights Section
              _DailyHighlightsSection(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header matching ref_ui_updated.png:
/// "Good morning," subtitle, "[Name]" bold title, right avatar
class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning,',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: 'Account and Profile',
          child: GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [colors.accent, colors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? colors.gold
                      : Colors.white,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Container(
                  color: colors.primaryWash,
                  child: Center(
                    child: Text(
                      name.characters.first.toUpperCase(),
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
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

/// Calories & Real Macronutrient Breakdown Card
class _CaloriesAndMacrosCard extends StatelessWidget {
  const _CaloriesAndMacrosCard({required this.state});

  final TodayState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    final consumed = state.caloriesConsumed;
    final target = state.caloriesTarget > 0 ? state.caloriesTarget : 2000;
    final remaining = math.max(0, target - consumed);
    final progressRatio = (consumed / target).clamp(0.0, 1.0);

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
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Calories Remaining
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Remaining',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatCount(remaining),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colors.gold,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    'kcal left',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              // Center: Calories consumed / target hero ring
              _CenterHeroCircularIndicator(
                consumed: consumed,
                target: target,
                progress: progressRatio,
              ),

              // Right: Calories Eaten
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Eaten',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatCount(consumed),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colors.primary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    'of ${formatCount(target)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: scheme.outlineVariant),
          const SizedBox(height: 14),

          // 3 Real Macronutrient Progress Bars (Protein, Carbs, Fat)
          Row(
            children: [
              Expanded(
                child: _MacroProgressItem(
                  label: 'Protein',
                  grams: '${protein.value}g',
                  percentage: '${(protein.ratio * 100).toInt()}%',
                  ratio: protein.ratio,
                  color: colors.macroProtein,
                  onTap: () => context.push('/macro-breakdown?kind=protein'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroProgressItem(
                  label: 'Carbs',
                  grams: '${carbs.value}g',
                  percentage: '${(carbs.ratio * 100).toInt()}%',
                  ratio: carbs.ratio,
                  color: colors.macroCarbs,
                  onTap: () => context.push('/macro-breakdown?kind=carbs'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroProgressItem(
                  label: 'Fat',
                  grams: '${fat.value}g',
                  percentage: '${(fat.ratio * 100).toInt()}%',
                  ratio: fat.ratio,
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

class _MacroProgressItem extends StatelessWidget {
  const _MacroProgressItem({
    required this.label,
    required this.grams,
    required this.percentage,
    required this.ratio,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String grams;
  final String percentage;
  final double ratio;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: colors.primaryWash.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    grams,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    percentage,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterHeroCircularIndicator extends StatelessWidget {
  const _CenterHeroCircularIndicator({
    required this.consumed,
    required this.target,
    required this.progress,
  });

  final int consumed;
  final int target;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return SizedBox(
      width: 124,
      height: 124,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(124, 124),
            painter: _ArcProgressPainter(
              progress: progress,
              strokeWidth: 10,
              trackColor: scheme.outlineVariant,
              progressColor: colors.primary,
              gradientColors: [colors.accent, colors.primary],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Calories',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatCount(consumed),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                'Goal ${formatCount(target)}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcProgressPainter extends CustomPainter {
  const _ArcProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
    this.gradientColors,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;
  final List<Color>? gradientColors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Progress arc
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (gradientColors != null && gradientColors!.length >= 2) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      progressPaint.shader = SweepGradient(
        colors: gradientColors!,
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi,
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    } else {
      progressPaint.color = progressColor;
    }

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcProgressPainter old) =>
      old.progress != progress || old.progressColor != progressColor;
}

/// Quick Stats Row: Steps, Water, Sleep (Only 3 tiles, Active Cal removed)
class _QuickStatsGrid extends ConsumerWidget {
  const _QuickStatsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final stepSnapshot = ref.watch(stepTrackerProvider).valueOrNull;
    final stepGoal = ref.watch(stepGoalProvider);
    final water = ref.watch(waterTodayProvider);
    final sleep = ref.watch(sleepTodayProvider);
    final sleepState = ref.watch(sleepProvider);

    final stepCount = stepSnapshot?.steps ?? 0;
    final waterLiters = water.liters;
    final waterGoal = water.goalLiters;
    final sleepMinutes = sleep?.durationMinutes ?? 0;
    final sleepGoalMinutes = sleepState.targetMinutes;

    return Row(
      children: [
        // Steps Card
        Expanded(
          child: _StatCard(
            icon: Icons.directions_walk_rounded,
            iconColor: colors.primary,
            iconBg: colors.primary.withValues(alpha: 0.12),
            value: formatCount(stepCount),
            subtext: 'Goal ${formatCount(stepGoal)}',
            progress: (stepCount / stepGoal).clamp(0.0, 1.0),
            progressColor: colors.primary,
            onTap: () => context.push('/activity'),
          ),
        ),
        const SizedBox(width: 8),

        // Water Card
        Expanded(
          child: _StatCard(
            icon: Icons.water_drop_rounded,
            iconColor: colors.water,
            iconBg: colors.water.withValues(alpha: 0.12),
            value: '${waterLiters.toStringAsFixed(1)}L',
            subtext: 'Goal ${waterGoal.toStringAsFixed(1)}L',
            progress: water.progress,
            progressColor: colors.water,
            onTap: () => context.push('/water'),
          ),
        ),
        const SizedBox(width: 8),

        // Sleep Card
        Expanded(
          child: _StatCard(
            icon: Icons.bedtime_rounded,
            iconColor: colors.sleep,
            iconBg: colors.sleep.withValues(alpha: 0.12),
            value: sleepMinutes > 0
                ? '${sleepMinutes ~/ 60}h ${sleepMinutes % 60}m'
                : '0h 0m',
            subtext: 'Goal ${(sleepGoalMinutes / 60).toStringAsFixed(1)}h',
            progress: (sleepMinutes / sleepGoalMinutes).clamp(0.0, 1.0),
            progressColor: colors.sleep,
            onTap: () => context.push('/sleep'),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.subtext,
    required this.progress,
    required this.progressColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String subtext;
  final double progress;
  final Color progressColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: scheme.outlineVariant,
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Prominent "AI Nutrition Coach chatbot" entry card matching ref_ui_updated.png
class _AiNutritionCoachCard extends StatelessWidget {
  const _AiNutritionCoachCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return AppCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => context.push('/scan'),
      child: Row(
        children: [
          // Glowing avatar disc
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [colors.accent, colors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.accent.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Nutrition Coach',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Meal detection • Instant logging • Insights',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt_outlined, color: scheme.onPrimary, size: 14),
                const SizedBox(width: 5),
                Text(
                  'Scan',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

/// "Daily Highlights" section
class _DailyHighlightsSection extends StatelessWidget {
  const _DailyHighlightsSection({required this.state});

  final TodayState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    final hasMeals = state.caloriesConsumed > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Highlights',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/diary'),
              child: Text(
                'Diary >',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 118,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _HighlightCard(
                title: 'Daily Nutrition',
                subtitle: hasMeals
                    ? 'Logged ${state.caloriesConsumed} kcal today across meals.'
                    : 'No meals logged yet today. Tap Scan to capture your breakfast, lunch or snack.',
                icon: Icons.insights_rounded,
                iconColor: colors.primary,
                chipText: hasMeals ? 'Active' : 'Get Started',
                chipColor: colors.primary,
                onTap: () => context.push('/diary'),
              ),
              const SizedBox(width: 12),
              _HighlightCard(
                title: 'Macronutrient Targets',
                subtitle: hasMeals
                    ? 'Check your personalized protein, carbs, and fat breakdown in Insights.'
                    : 'Personalized targets calculated to help reach your wellness goal.',
                icon: Icons.pie_chart_outline_rounded,
                iconColor: colors.gold,
                chipText: 'Target',
                chipColor: colors.gold,
                onTap: () => context.push('/insights'),
              ),
              const SizedBox(width: 12),
              _HighlightCard(
                title: 'Hydration Status',
                subtitle: 'Track your daily water glasses to keep energy and metabolism high.',
                icon: Icons.water_drop_outlined,
                iconColor: colors.water,
                chipText: 'Hydration',
                chipColor: colors.water,
                onTap: () => context.push('/water'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.chipText,
    required this.chipColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String chipText;
  final Color chipColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant,
          width: 1.0,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 16, color: iconColor),
                        const SizedBox(width: 6),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: chipColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        chipText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: chipColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
