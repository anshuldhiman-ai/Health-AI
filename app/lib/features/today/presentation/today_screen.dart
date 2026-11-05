import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:app/core/format/count_format.dart';
import 'package:app/data/preferences/body_metrics_controller.dart';
import 'package:app/data/preferences/sleep_controller.dart';
import 'package:app/data/preferences/water_controller.dart';
import 'package:app/data/sensors/step_tracker.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/activity_snapshot.dart';
import 'package:app/domain/entities/macro.dart';
import 'package:app/features/today/application/today_state.dart';

/// Screen: Main Dashboard (Today) elevated to the premium dark fitness visual
/// language specified in step.png.
///
/// Visual Palette:
/// - Background: Deep black-green #001C19 with ambient radial teal glow
/// - Surfaces: Dark emerald glassmorphic #072521 with hairline #103F38 borders
/// - Highlights: Neon mint #00D6A0, secondary emerald #19B88A, accent gold #FFC247
/// - Typography: White #FFFFFF bold values, soft teal-gray #A7BDB8 labels
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todayStateProvider);
    final metrics = ref.watch(bodyMetricsProvider);

    final displayName = metrics.name.trim().isEmpty
        ? 'Anshul'
        : metrics.name.trim();

    return Scaffold(
      backgroundColor: const Color(0xFF001C19),
      body: Stack(
        children: [
          // 1. Ambient background radial gradient glow
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.7, -0.65),
                  radius: 1.1,
                  colors: [
                    Color(0xFF013B32),
                    Color(0xFF00221E),
                    Color(0xFF001714),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 2. Subtle organic leaf background accent at top-left
          Positioned(
            top: -30,
            left: -40,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.10,
                child: CustomPaint(
                  size: const Size(180, 220),
                  painter: _LeafSilhouettePainter(),
                ),
              ),
            ),
          ),

          // 3. Subtle organic leaf background accent at bottom-right
          Positioned(
            bottom: 110,
            right: -30,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.08,
                child: Transform.rotate(
                  angle: 2.4,
                  child: CustomPaint(
                    size: const Size(160, 200),
                    painter: _LeafSilhouettePainter(),
                  ),
                ),
              ),
            ),
          ),

          // 4. Main Scrollable Dashboard Content
          SafeArea(
            bottom: false,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                16,
                AppSpacing.screenPadding,
                130, // Clear floating bottom nav bar & raised scan button
              ),
              children: [
                _HeaderSection(name: displayName),
                const SizedBox(height: 18),

                // Top Hero Section: Calories Ring & Real Macronutrient Breakdown
                _CaloriesAndMacrosCard(state: state),
                const SizedBox(height: 18),

                // Quick Stats Row: Steps, Water, Sleep
                const _QuickStatsGrid(),
                const SizedBox(height: 18),

                // Prominent AI Nutrition Scanner / Quick Food Log Card
                const _AiNutritionCoachCard(),
                const SizedBox(height: 20),

                // Daily Highlights Section
                _DailyHighlightsSection(state: state),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Header with dynamic time-of-day greeting, bold white user name, date pill, and avatar.
class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning,'
        : hour < 17
            ? 'Good afternoon,'
            : 'Good evening,';
    final greetingIcon = hour < 12
        ? Icons.wb_sunny_rounded
        : hour < 17
            ? Icons.sunny
            : Icons.nights_stay_rounded;

    final dateFormatted = DateFormat('EEE, d MMM').format(DateTime.now());

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(greetingIcon, size: 14, color: const Color(0xFFFFC247)),
                  const SizedBox(width: 5),
                  Text(
                    greeting,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFA7BDB8),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ),

        // Date pill badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF072521),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF104038)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: Color(0xFF00D6A0),
              ),
              const SizedBox(width: 6),
              Text(
                dateFormatted,
                style: const TextStyle(
                  color: Color(0xFFA7BDB8),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Avatar with emerald/mint halo ring
        Semantics(
          button: true,
          label: 'Account and Profile',
          child: GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5A3), Color(0xFF0F5A3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: const Color(0xFF00E5A3).withValues(alpha: 0.6),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5A3).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Container(
                  color: const Color(0xFF012924),
                  child: Center(
                    child: Text(
                      name.characters.first.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF00E5A3),
                        fontSize: 17,
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

/// Calories & Real Macronutrient Breakdown Card with central hero ring.
class _CaloriesAndMacrosCard extends ConsumerWidget {
  const _CaloriesAndMacrosCard({required this.state});

  final TodayState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consumed = state.caloriesConsumed;
    final target = state.caloriesTarget > 0 ? state.caloriesTarget : 2000;
    final remaining = math.max(0, target - consumed);
    final progressRatio = (consumed / target).clamp(0.0, 1.0);

    final stepSnapshot = ref.watch(stepTrackerProvider).valueOrNull;
    final burnedKcal =
        ((stepSnapshot?.steps ?? 0) * kKcalPerStepEstimate).round();

    final protein = state.macros.firstWhere(
      (m) => m.kind == MacroKind.protein,
      orElse: () =>
          const MacroLine(kind: MacroKind.protein, value: 0, target: 100),
    );
    final carbs = state.macros.firstWhere(
      (m) => m.kind == MacroKind.carbs,
      orElse: () =>
          const MacroLine(kind: MacroKind.carbs, value: 0, target: 180),
    );
    final fat = state.macros.firstWhere(
      (m) => m.kind == MacroKind.fat,
      orElse: () => const MacroLine(kind: MacroKind.fat, value: 0, target: 60),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF072521),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF104038), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00110E).withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.hourglass_top_rounded,
                        size: 13,
                        color: Color(0xFFFFC247),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Remaining',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFA7BDB8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatCount(remaining),
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFC247),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Text(
                    'kcal left',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFA7BDB8),
                    ),
                  ),
                ],
              ),

              // Center: Calories consumed / target hero circular ring
              _CenterHeroCircularIndicator(
                consumed: consumed,
                target: target,
                progress: progressRatio,
              ),

              // Right: Calories Burned from steps
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 13,
                        color: Color(0xFFFF8A65),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Burned',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFA7BDB8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatCount(burnedKcal),
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFF8A65),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Text(
                    'active kcal',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFA7BDB8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFF104038)),
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
                  color: const Color(0xFF00D6A0),
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
                  color: const Color(0xFFFFC247),
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
                  color: const Color(0xFF19B88A),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF062A25),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF104038), width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFA7BDB8),
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
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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
                  backgroundColor: const Color(0xFF021B17),
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
    return SizedBox(
      width: 126,
      height: 126,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner dark depth circle
          Container(
            width: 98,
            height: 98,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF031E1B),
            ),
          ),

          // Illuminated mint circular arc
          CustomPaint(
            size: const Size(126, 126),
            painter: _ArcProgressPainter(
              progress: progress,
              strokeWidth: 9.5,
              trackColor: const Color(0xFF0A332C),
              progressColor: const Color(0xFF00D6A0),
              gradientColors: const [Color(0xFF00F0A8), Color(0xFF00D6A0)],
            ),
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.restaurant_rounded,
                size: 15,
                color: Color(0xFF00D6A0),
              ),
              const SizedBox(height: 2),
              Text(
                formatCount(consumed),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  color: Colors.white,
                ),
              ),
              Text(
                'Goal ${formatCount(target)}',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFA7BDB8),
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

/// Quick Stats Row: Steps, Water, Sleep with live progress metrics.
class _QuickStatsGrid extends ConsumerWidget {
  const _QuickStatsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            iconColor: const Color(0xFF00D6A0),
            iconBg: const Color(0xFF00D6A0).withValues(alpha: 0.15),
            value: formatCount(stepCount),
            subtext: 'Goal ${formatCount(stepGoal)}',
            progress: (stepCount / (stepGoal > 0 ? stepGoal : 10000))
                .clamp(0.0, 1.0),
            progressColor: const Color(0xFF00D6A0),
            onTap: () => context.push('/activity'),
          ),
        ),
        const SizedBox(width: 8),

        // Water Card
        Expanded(
          child: _StatCard(
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFF00B4D8),
            iconBg: const Color(0xFF00B4D8).withValues(alpha: 0.15),
            value: '${waterLiters.toStringAsFixed(1)}L',
            subtext: 'Goal ${waterGoal.toStringAsFixed(1)}L',
            progress: water.progress,
            progressColor: const Color(0xFF00B4D8),
            onTap: () => context.push('/water'),
          ),
        ),
        const SizedBox(width: 8),

        // Sleep Card
        Expanded(
          child: _StatCard(
            icon: Icons.bedtime_rounded,
            iconColor: const Color(0xFF818CF8),
            iconBg: const Color(0xFF818CF8).withValues(alpha: 0.15),
            value: sleepMinutes > 0
                ? '${sleepMinutes ~/ 60}h ${sleepMinutes % 60}m'
                : '0h 0m',
            subtext:
                'Goal ${(sleepGoalMinutes / 60).toStringAsFixed(1)}h',
            progress: (sleepMinutes /
                    (sleepGoalMinutes > 0 ? sleepGoalMinutes : 480))
                .clamp(0.0, 1.0),
            progressColor: const Color(0xFF818CF8),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF072521),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF104038), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00110E).withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtext,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFA7BDB8),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: const Color(0xFF021B17),
                    valueColor: AlwaysStoppedAnimation(progressColor),
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

/// Prominent AI Nutrition Scanner / Quick Food Log Card
class _AiNutritionCoachCard extends StatelessWidget {
  const _AiNutritionCoachCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF072521),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00E5A3).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5A3).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => context.push('/scan'),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Glowing scanner badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF012924),
                    border: Border.all(
                      color: const Color(0xFF00E5A3),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5A3).withValues(alpha: 0.30),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.crop_free_rounded,
                      color: Color(0xFF00E5A3),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'AI Vision Scanner',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Point camera at any meal for offline macros',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFA7BDB8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D6A0),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D6A0).withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.camera_alt_outlined,
                        color: Color(0xFF00241E),
                        size: 14,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Scan',
                        style: TextStyle(
                          color: Color(0xFF00241E),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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

/// "Daily Highlights" section
class _DailyHighlightsSection extends StatelessWidget {
  const _DailyHighlightsSection({required this.state});

  final TodayState state;

  @override
  Widget build(BuildContext context) {
    final hasMeals = state.caloriesConsumed > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daily Highlights',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/diary'),
              child: const Text(
                'Diary >',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00D6A0),
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
            physics: const BouncingScrollPhysics(),
            children: [
              _HighlightCard(
                title: 'Daily Nutrition',
                subtitle: hasMeals
                    ? 'Logged ${state.caloriesConsumed} kcal today across meals.'
                    : 'No meals logged yet today. Tap Scan to capture your breakfast, lunch or snack.',
                icon: Icons.insights_rounded,
                iconColor: const Color(0xFF00D6A0),
                chipText: hasMeals ? 'Active' : 'Get Started',
                chipColor: const Color(0xFF00D6A0),
                onTap: () => context.push('/diary'),
              ),
              const SizedBox(width: 12),
              _HighlightCard(
                title: 'Macronutrient Targets',
                subtitle: hasMeals
                    ? 'Check your personalized protein, carbs, and fat breakdown in Insights.'
                    : 'Personalized targets calculated to help reach your wellness goal.',
                icon: Icons.pie_chart_outline_rounded,
                iconColor: const Color(0xFFFFC247),
                chipText: 'Target',
                chipColor: const Color(0xFFFFC247),
                onTap: () => context.push('/insights'),
              ),
              const SizedBox(width: 12),
              _HighlightCard(
                title: 'Hydration Status',
                subtitle:
                    'Track your daily water glasses to keep energy and metabolism high.',
                icon: Icons.water_drop_outlined,
                iconColor: const Color(0xFF00B4D8),
                chipText: 'Hydration',
                chipColor: const Color(0xFF00B4D8),
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
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: const Color(0xFF072521),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF104038), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00110E).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: chipColor.withValues(alpha: 0.15),
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
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFA7BDB8),
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

/// Organic leaf silhouette background painter matching step tracker aesthetics.
class _LeafSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D6A0)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.5, 0, size.width, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.7,
        0,
        size.height * 0.5,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
