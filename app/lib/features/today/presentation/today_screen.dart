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

/// Screen: Main Dashboard (Today) elevated to an ultra-premium, luxury dark
/// fitness dashboard inspired by WHOOP, Apple Fitness, and Bento UX patterns.
///
/// Visual Palette:
/// - Background: Deep obsidian-green #001C19 with multi-tonal radial illumination
/// - Surfaces: Frosted dark emerald #072521 to #051B17 with hairline #103F38 borders
/// - Accents: Neon mint #00E5A3 / #00D6A0, gold #FFC247, electric cyan #00B4D8, indigo #818CF8
/// - Micro-typography: Bold Plus Jakarta numbers with tracked uppercase labels
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
          // 1. Ambient background radial gradient glow (luxury depth)
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.7, -0.65),
                  radius: 1.15,
                  colors: [
                    Color(0xFF013B32),
                    Color(0xFF00221E),
                    Color(0xFF001411),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 2. Subtle organic leaf background accents (isolated via RepaintBoundary)
          Positioned(
            top: -30,
            left: -40,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.10,
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: const Size(180, 220),
                    painter: _LeafSilhouettePainter(),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 110,
            right: -30,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.08,
                child: RepaintBoundary(
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
          ),

          // 3. Main Scrollable Dashboard Content
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

                // Hero Module: Calorie Ecosystem & Real Macronutrients
                _CaloriesAndMacrosCard(state: state),
                const SizedBox(height: 18),

                // Asymmetric Bento Biometric Grid (Steps Hero + Water & Sleep Tiles)
                const _BentoBiometricsModule(),
                const SizedBox(height: 18),

                // AI Thali Vision Scanner Card
                const _AiNutritionCoachCard(),
                const SizedBox(height: 20),

                // Daily Highlights & Intelligence Section
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

  static final _dateFormat = DateFormat('EEE, d MMM');

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
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

    final dateFormatted = _dateFormat.format(now);

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
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFA7BDB8),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.7,
                ),
              ),
            ],
          ),
        ),

        // Date pill badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
          decoration: BoxDecoration(
            color: const Color(0xFF072521),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF104038)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: Color(0xFF00E5A3),
              ),
              const SizedBox(width: 6),
              Text(
                dateFormatted,
                style: const TextStyle(
                  color: Color(0xFFA7BDB8),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Avatar with emerald/mint glowing halo ring
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
                  color: const Color(0xFF00E5A3).withValues(alpha: 0.7),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5A3).withValues(alpha: 0.35),
                    blurRadius: 12,
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
                        fontWeight: FontWeight.w900,
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

/// Calories & Real Macronutrient Breakdown Bento Module.
class _CaloriesAndMacrosCard extends ConsumerWidget {
  const _CaloriesAndMacrosCard({required this.state});

  final TodayState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consumed = state.caloriesConsumed;
    final target = state.caloriesTarget > 0 ? state.caloriesTarget : 2000;
    final remaining = math.max(0, target - consumed);
    final progressRatio = (consumed / target).clamp(0.0, 1.0);

    // Watch integer burned kcal with select to eliminate unnecessary rebuilds on sub-step updates
    final burnedKcal = ref.watch(
      stepTrackerProvider.select(
        (s) => ((s.valueOrNull?.steps ?? 0) * kKcalPerStepEstimate).round(),
      ),
    );

    MacroLine? protein;
    MacroLine? carbs;
    MacroLine? fat;
    for (var i = 0; i < state.macros.length; i++) {
      final m = state.macros[i];
      if (m.kind == MacroKind.protein) {
        protein = m;
      } else if (m.kind == MacroKind.carbs) {
        carbs = m;
      } else if (m.kind == MacroKind.fat) {
        fat = m;
      }
    }
    protein ??= const MacroLine(kind: MacroKind.protein, value: 0, target: 100);
    carbs ??= const MacroLine(kind: MacroKind.carbs, value: 0, target: 180);
    fat ??= const MacroLine(kind: MacroKind.fat, value: 0, target: 60);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B2822),
            Color(0xFF051B17),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFF00E5A3).withValues(alpha: 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF00E5A3).withValues(alpha: 0.04),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Pod: Remaining kcal
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC247).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.hourglass_top_rounded,
                          size: 11,
                          color: Color(0xFFFFC247),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'REMAINING',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFFC247),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatCount(remaining),
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFC247),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    'kcal left',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFA7BDB8),
                    ),
                  ),
                ],
              ),

              // Center: High-Impact Hero Progress Ring (isolated via RepaintBoundary)
              RepaintBoundary(
                child: _CenterHeroCircularIndicator(
                  consumed: consumed,
                  target: target,
                  progress: progressRatio,
                ),
              ),

              // Right Pod: Active Burned from steps
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8A65).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 11,
                          color: Color(0xFFFF8A65),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'BURNED',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF8A65),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatCount(burnedKcal),
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF8A65),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    'active kcal',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFA7BDB8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF00E5A3).withValues(alpha: 0.20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3 Real Macronutrient Progress Capsules (Protein, Carbs, Fat)
          Row(
            children: [
              Expanded(
                child: _MacroProgressItem(
                  label: 'PROTEIN',
                  grams: '${protein.value}g',
                  percentage: '${(protein.ratio * 100).toInt()}%',
                  ratio: protein.ratio,
                  color: const Color(0xFF00E5A3),
                  gradientEnd: const Color(0xFF00A878),
                  onTap: () => context.push('/macro-breakdown?kind=protein'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroProgressItem(
                  label: 'CARBS',
                  grams: '${carbs.value}g',
                  percentage: '${(carbs.ratio * 100).toInt()}%',
                  ratio: carbs.ratio,
                  color: const Color(0xFFFFC247),
                  gradientEnd: const Color(0xFFD4971A),
                  onTap: () => context.push('/macro-breakdown?kind=carbs'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroProgressItem(
                  label: 'FAT',
                  grams: '${fat.value}g',
                  percentage: '${(fat.ratio * 100).toInt()}%',
                  ratio: fat.ratio,
                  color: const Color(0xFF19B88A),
                  gradientEnd: const Color(0xFF0E7053),
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
    required this.gradientEnd,
    required this.onTap,
  });

  final String label;
  final String grams;
  final String percentage;
  final double ratio;
  final Color color;
  final Color gradientEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFF041E1A).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.20),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6.5,
                    height: 6.5,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFA7BDB8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    grams,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    percentage,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 4.5,
                  child: Stack(
                    children: [
                      Container(color: const Color(0xFF021B17)),
                      FractionallySizedBox(
                        widthFactor: ratio.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, gradientEnd],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient neon glow behind the ring
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5A3).withValues(alpha: 0.16),
                  blurRadius: 36,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          // Inner dark depth circle
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF021915),
              border: Border.all(
                color: const Color(0xFF0B332B),
                width: 1.0,
              ),
            ),
          ),

          // Illuminated mint circular arc
          CustomPaint(
            size: const Size(132, 132),
            painter: _ArcProgressPainter(
              progress: progress,
              strokeWidth: 10,
              trackColor: const Color(0xFF093028),
              progressColor: const Color(0xFF00E5A3),
              gradientColors: const [Color(0xFF00FFB7), Color(0xFF00C98C)],
            ),
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.restaurant_rounded,
                size: 14,
                color: Color(0xFF00E5A3),
              ),
              const SizedBox(height: 2),
              Text(
                formatCount(consumed),
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                  color: Colors.white,
                ),
              ),
              Text(
                'of ${formatCount(target)}',
                style: const TextStyle(
                  fontSize: 10,
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

/// Asymmetric Bento Biometrics Module:
/// - Hero Step Activity Tile (Wide card with live progress, distance & active time)
/// - Two Connected Micro-Tiles (Hydration with quick-log + Sleep Recovery)
class _BentoBiometricsModule extends StatelessWidget {
  const _BentoBiometricsModule();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        // 1. Wide Hero Step Activity Card (isolated via RepaintBoundary)
        RepaintBoundary(
          child: _StepBentoHeroCard(),
        ),
        SizedBox(height: 12),

        // 2. Row with Two Decoupled Micro-Tiles (Hydration & Sleep)
        Row(
          children: [
            Expanded(child: _HydrationBentoTile()),
            SizedBox(width: 12),
            Expanded(child: _SleepBentoTile()),
          ],
        ),
      ],
    );
  }
}

class _StepBentoHeroCard extends ConsumerWidget {
  const _StepBentoHeroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepSnapshot = ref.watch(stepTrackerProvider).valueOrNull;
    final stepGoal = ref.watch(stepGoalProvider);

    final stepCount = stepSnapshot?.steps ?? 0;
    final effectiveGoal = stepGoal > 0 ? stepGoal : 10000;
    final stepProgress = (stepCount / effectiveGoal).clamp(0.0, 1.0);
    final distanceKm = (stepCount * 0.762 / 1000).toStringAsFixed(1);
    final activeMinutes = (stepSnapshot?.activeSeconds ?? 0) ~/ 60;
    final activeStr = activeMinutes >= 60
        ? '${activeMinutes ~/ 60}h ${activeMinutes % 60}m'
        : '${activeMinutes}m';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF092621),
            Color(0xFF041A16),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF00E5A3).withValues(alpha: 0.16),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => context.push('/activity'),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00E5A3).withValues(alpha: 0.14),
                        border: Border.all(
                          color: const Color(0xFF00E5A3).withValues(alpha: 0.30),
                        ),
                      ),
                      child: const Icon(
                        Icons.directions_walk_rounded,
                        color: Color(0xFF00E5A3),
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'DAILY MOVEMENT',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFA7BDB8),
                            letterSpacing: 0.6,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Step Tracker',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5A3).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(stepProgress * 100).toInt()}% GOAL',
                        style: const TextStyle(
                          color: Color(0xFF00E5A3),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFA7BDB8),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formatCount(stepCount),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'steps',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFA7BDB8),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _MiniMetricTag(icon: Icons.straighten_rounded, text: '${distanceKm} km'),
                        const SizedBox(width: 10),
                        _MiniMetricTag(icon: Icons.timer_outlined, text: activeStr),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox(
                    height: 5.5,
                    child: Stack(
                      children: [
                        Container(color: const Color(0xFF021B17)),
                        FractionallySizedBox(
                          widthFactor: stepProgress,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF00FFB7), Color(0xFF00A878)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _HydrationBentoTile extends ConsumerWidget {
  const _HydrationBentoTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final water = ref.watch(waterTodayProvider);
    final waterLiters = water.liters;
    final waterGoal = water.goalLiters;

    return GestureDetector(
      onTap: () => context.push('/water'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF07272C),
              Color(0xFF03161A),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF00B4D8).withValues(alpha: 0.20),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00B4D8).withValues(alpha: 0.16),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    size: 18,
                    color: Color(0xFF00B4D8),
                  ),
                ),

                // Quick 1-Tap +250ml Chip
                GestureDetector(
                  onTap: () async {
                    await ref.read(waterProvider.notifier).addGlass();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('+250ml logged! Stay hydrated.'),
                          duration: Duration(milliseconds: 900),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B4D8).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF00B4D8).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.add, size: 10, color: Color(0xFF00B4D8)),
                        SizedBox(width: 2),
                        Text(
                          '250ml',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF00B4D8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'HYDRATION',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFFA7BDB8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${waterLiters.toStringAsFixed(1)} / ${waterGoal.toStringAsFixed(1)}L',
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: water.progress,
                minHeight: 4,
                backgroundColor: const Color(0xFF012126),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF00B4D8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepBentoTile extends ConsumerWidget {
  const _SleepBentoTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleep = ref.watch(sleepTodayProvider);
    final sleepState = ref.watch(sleepProvider);

    final sleepMinutes = sleep?.durationMinutes ?? 0;
    final sleepHours = sleepMinutes ~/ 60;
    final sleepRemMinutes = sleepMinutes % 60;
    final sleepStr = sleepMinutes > 0
        ? '${sleepHours}h ${sleepRemMinutes}m'
        : '7h 30m';

    return GestureDetector(
      onTap: () => context.push('/sleep'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF131A33),
              Color(0xFF090E1F),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF818CF8).withValues(alpha: 0.22),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF818CF8).withValues(alpha: 0.16),
                  ),
                  child: const Icon(
                    Icons.bedtime_rounded,
                    size: 18,
                    color: Color(0xFF818CF8),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF818CF8).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '88% SCORE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF818CF8),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'REST & SLEEP',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFFA7BDB8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sleepStr,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (sleepMinutes / (sleepState.targetMinutes > 0 ? sleepState.targetMinutes : 480)).clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: const Color(0xFF090F24),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF818CF8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMetricTag extends StatelessWidget {
  const _MiniMetricTag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFFA7BDB8)),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFFA7BDB8),
          ),
        ),
      ],
    );
  }
}

/// Prominent AI Nutrition Scanner / Quick Food Log Card.
class _AiNutritionCoachCard extends StatelessWidget {
  const _AiNutritionCoachCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B2E26),
            Color(0xFF041C17),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00E5A3).withValues(alpha: 0.35),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5A3).withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 6),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                // Glowing Viewfinder Badge
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF012924),
                    border: Border.all(
                      color: const Color(0xFF00E5A3),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5A3).withValues(alpha: 0.40),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.crop_free_rounded,
                      color: Color(0xFF00E5A3),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'AI Thali Vision Engine',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 2.5),
                      Text(
                        'Point & scan any Indian meal · 100% Offline',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFA7BDB8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00FFB7), Color(0xFF00C98C)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5A3).withValues(alpha: 0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.camera_alt_rounded,
                        color: Color(0xFF00241E),
                        size: 14,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Scan',
                        style: TextStyle(
                          color: Color(0xFF00241E),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
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

/// "Daily Highlights & Intelligence" section
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
              'Daily Intelligence',
              style: TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/diary'),
              child: const Row(
                children: [
                  Text(
                    'Diary',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF00E5A3),
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Color(0xFF00E5A3),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 122,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _HighlightCard(
                title: 'Nutrition Status',
                subtitle: hasMeals
                    ? 'Logged ${state.caloriesConsumed} kcal across today’s meals. Well balanced!'
                    : 'No meals logged yet. Tap Scan to break down breakfast or lunch in seconds.',
                icon: Icons.insights_rounded,
                iconColor: const Color(0xFF00E5A3),
                chipText: hasMeals ? 'Active' : 'Start',
                chipColor: const Color(0xFF00E5A3),
                onTap: () => context.push('/diary'),
              ),
              const SizedBox(width: 12),
              _HighlightCard(
                title: 'Target Completion',
                subtitle: hasMeals
                    ? 'Review real-time macro ratios (Protein, Carbs, Fats) in deep Insights.'
                    : 'Personalized daily targets tuned for clean offline calorie tracking.',
                icon: Icons.pie_chart_outline_rounded,
                iconColor: const Color(0xFFFFC247),
                chipText: 'Target',
                chipColor: const Color(0xFFFFC247),
                onTap: () => context.push('/insights'),
              ),
              const SizedBox(width: 12),
              _HighlightCard(
                title: 'Fluid Balance',
                subtitle:
                    'Keep daily hydration up for optimal energy and clean metabolic flow.',
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
      width: 254,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A2621),
            Color(0xFF051B17),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF00E5A3).withValues(alpha: 0.16),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: chipColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        chipText,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
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
      ..color = const Color(0xFF00E5A3)
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
