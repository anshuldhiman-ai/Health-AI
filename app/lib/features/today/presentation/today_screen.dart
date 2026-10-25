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
      backgroundColor: const Color(0xFFF7F9FB),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F9FB),
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

              // Top Section: 3 Prominent Circular Progress Indicators
              _TripleCircularNutritionCard(state: state),
              const SizedBox(height: 18),

              // Quick Stats Row: Steps, Water, Sleep, Active Cal
              const _QuickStatsGrid(),
              const SizedBox(height: 18),

              // Prominent AI Nutrition Coach Chatbot Entry Card
              const _AiNutritionCoachCard(),
              const SizedBox(height: 20),

              // Daily Highlights & Micro-trends Section
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good morning,',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6C7278),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1C1E),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E885F), Color(0xFF0F5A3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F5A3C).withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Container(
                  color: const Color(0xFFE8F2ED),
                  child: Center(
                    child: Text(
                      name.characters.first.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF0F5A3C),
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

/// Top Section: Three prominent circular progress indicators side-by-side:
/// - Left: "Kcal 1,480 remaining"
/// - Center: "Calories 1,480 / 2,400"
/// - Right: "Active Kcal 320 remaining"
/// - Bottom: "📈 Inline micro-trends >"
class _TripleCircularNutritionCard extends StatelessWidget {
  const _TripleCircularNutritionCard({required this.state});

  final TodayState state;

  @override
  Widget build(BuildContext context) {
    // Dummy showcase defaults if empty, per task instructions
    final consumed = state.caloriesConsumed > 0 ? state.caloriesConsumed : 1480;
    final target = state.caloriesTarget > 0 ? state.caloriesTarget : 2400;
    final remaining = math.max(0, target - consumed);
    final activeBurned = 320;

    final progressRatio = (consumed / target).clamp(0.0, 1.0);

    return AppCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Ring: Kcal Remaining
              _SideCircularIndicator(
                label: 'Kcal',
                value: formatCount(remaining),
                subLabel: 'remaining',
                progress: (remaining / target).clamp(0.0, 1.0),
                color: const Color(0xFFD4AF37), // Subtle Gold
              ),

              // Center Prominent Ring: Calories consumed / target
              _CenterHeroCircularIndicator(
                consumed: consumed,
                target: target,
                progress: progressRatio,
              ),

              // Right Ring: Active Kcal
              _SideCircularIndicator(
                label: 'Active Kcal',
                value: formatCount(activeBurned),
                subLabel: 'remaining',
                progress: 0.45,
                color: const Color(0xFF1E885F), // Vibrant Emerald
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: const Color(0xFFE5E9EE).withValues(alpha: 0.8)),
          const SizedBox(height: 12),

          // "📈 Inline micro-trends >"
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/insights'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E885F).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        size: 14,
                        color: Color(0xFF0F5A3C),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Inline micro-trends',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F5A3C),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF0F5A3C),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideCircularIndicator extends StatelessWidget {
  const _SideCircularIndicator({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final String subLabel;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6C7278),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(72, 72),
                painter: _ArcProgressPainter(
                  progress: progress,
                  strokeWidth: 5.5,
                  trackColor: const Color(0xFFE5E9EE),
                  progressColor: color,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1C1E),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subLabel,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6C7278),
          ),
        ),
      ],
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
              trackColor: const Color(0xFFE5E9EE),
              progressColor: const Color(0xFF0F5A3C),
              gradientColors: const [Color(0xFF1E885F), Color(0xFF0F5A3C)],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Calories',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C7278),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatCount(consumed),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  color: Color(0xFF1A1C1E),
                ),
              ),
              Text(
                '1,480/2,400',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C7278),
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

/// Quick Stats Row: Steps, Water (Liters), Sleep duration, Active time
class _QuickStatsGrid extends ConsumerWidget {
  const _QuickStatsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepSnapshot = ref.watch(stepTrackerProvider).valueOrNull;
    final water = ref.watch(waterTodayProvider);
    final sleep = ref.watch(sleepTodayProvider);

    // Dummy values showcasing rich UI matching ref_ui_updated.png
    final stepCount = (stepSnapshot != null && stepSnapshot.steps > 0)
        ? stepSnapshot.steps
        : 7842;
    final waterLiters = water.glasses > 0 ? water.liters : 2.1;
    final sleepMinutes = sleep != null ? sleep.durationMinutes : 7 * 60 + 20;

    return Row(
      children: [
        // Steps Card
        Expanded(
          child: _StatCard(
            icon: Icons.directions_walk_rounded,
            iconColor: const Color(0xFF1E885F),
            iconBg: const Color(0xFF1E885F).withValues(alpha: 0.12),
            value: formatCount(stepCount),
            subtext: '10,000',
            tag: 'with streak',
            progress: (stepCount / 10000).clamp(0.0, 1.0),
            progressColor: const Color(0xFF1E885F),
            onTap: () => context.push('/activity'),
          ),
        ),
        const SizedBox(width: 8),

        // Water Card
        Expanded(
          child: _StatCard(
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFF0284C7),
            iconBg: const Color(0xFF0284C7).withValues(alpha: 0.12),
            value: '${waterLiters.toStringAsFixed(1)}L/3L',
            subtext: '3L',
            tag: '',
            progress: (waterLiters / 3.0).clamp(0.0, 1.0),
            progressColor: const Color(0xFF0284C7),
            onTap: () => context.push('/water'),
          ),
        ),
        const SizedBox(width: 8),

        // Sleep Card
        Expanded(
          child: _StatCard(
            icon: Icons.bedtime_rounded,
            iconColor: const Color(0xFF6366F1),
            iconBg: const Color(0xFF6366F1).withValues(alpha: 0.12),
            value: '${sleepMinutes ~/ 60}h ${sleepMinutes % 60}m',
            subtext: '8h',
            tag: '',
            progress: (sleepMinutes / (8 * 60)).clamp(0.0, 1.0),
            progressColor: const Color(0xFF6366F1),
            onTap: () => context.push('/sleep'),
          ),
        ),
        const SizedBox(width: 8),

        // Active Cal Card
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFEA580C),
            iconBg: const Color(0xFFEA580C).withValues(alpha: 0.12),
            value: 'Active C',
            subtext: '320 kcal',
            tag: '',
            progress: 0.65,
            progressColor: const Color(0xFFEA580C),
            onTap: () => context.push('/activity'),
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
    required this.tag,
    required this.progress,
    required this.progressColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String subtext;
  final String tag;
  final double progress;
  final Color progressColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1C1E),
              letterSpacing: -0.3,
            ),
          ),
          if (tag.isNotEmpty) ...[
            Text(
              tag,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6C7278),
              ),
            ),
          ] else ...[
            Text(
              subtext,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6C7278),
              ),
            ),
          ],
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFE5E9EE),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF0F5A3C).withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F5A3C).withValues(alpha: 0.06),
            blurRadius: 20,
            spreadRadius: 1,
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
                // Glowing avatar disc
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E885F), Color(0xFF0F5A3C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E885F).withValues(alpha: 0.35),
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
                    children: const [
                      Text(
                        'AI Nutrition Coach chatbot',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1C1E),
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Meal detection • Instant logging • Insights',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6C7278),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F5A3C),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt_outlined, color: Colors.white, size: 14),
                      SizedBox(width: 5),
                      Text(
                        'Scan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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

/// "Daily Highlights" section matching ref_ui_updated.png
class _DailyHighlightsSection extends StatelessWidget {
  const _DailyHighlightsSection({required this.state});

  final TodayState state;

  @override
  Widget build(BuildContext context) {
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
                color: Color(0xFF1A1C1E),
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
                  color: Color(0xFF0F5A3C),
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
                title: 'Daily Highlights',
                subtitle: 'Excellent nutrition balance today. High protein, moderate fat.',
                icon: Icons.insights_rounded,
                iconColor: const Color(0xFF1E885F),
                chipText: '+5% goal',
                chipColor: const Color(0xFF1E885F),
                onTap: () => context.push('/insights'),
              ),
              const SizedBox(width: 12),
              _HighlightCard(
                title: 'Macronutrient Balances',
                subtitle: 'Protein 60% • Carbs 35% • Fats 17%',
                icon: Icons.pie_chart_outline_rounded,
                iconColor: const Color(0xFFD4AF37),
                chipText: 'Optimal',
                chipColor: const Color(0xFFD4AF37),
                onTap: () => context.push('/macro-breakdown?kind=protein'),
              ),
              const SizedBox(width: 12),
              _HighlightCard(
                title: 'Hydration Consistency',
                subtitle: '2.1L logged across 5 evenly spaced intervals',
                icon: Icons.water_drop_outlined,
                iconColor: const Color(0xFF0284C7),
                chipText: 'Streak',
                chipColor: const Color(0xFF0284C7),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F5A3C).withValues(alpha: 0.05),
            blurRadius: 16,
            spreadRadius: 1,
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
                            color: Color(0xFF1A1C1E),
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
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6C7278),
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
