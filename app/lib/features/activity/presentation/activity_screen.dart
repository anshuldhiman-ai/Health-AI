import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/format/count_format.dart';
import 'package:app/data/preferences/sleep_controller.dart';
import 'package:app/data/preferences/water_controller.dart';
import 'package:app/data/sensors/step_tracker.dart';
import 'package:app/design_system/components/app_toast.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/activity_snapshot.dart';
import 'package:app/l10n/app_localizations.dart';

/// Screen: Step Tracker recreating the premium dark fitness dashboard in step.png.
///
/// Visual Palette:
/// - Background: Deep black-green #001C19 to #001412 with ambient teal lighting
/// - Card surfaces: Dark emerald glassmorphic #072521 with thin #103F38 borders
/// - Highlights: Neon mint-green #00D6A0 / #00F0A8, secondary emerald #19B88A
/// - Accent yellow: #FFC247 (Daily goal, trophy, selected chart dot)
/// - Typography: White #FFFFFF bold numbers, soft teal-gray #A7BDB8 secondary
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final value = ref.watch(stepTrackerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF001C19),
      bottomNavigationBar: const _FloatingBottomNavBar(),
      body: Stack(
        children: [
          // Ambient background gradient glow
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

          // Subtle organic background leaf accent at top-left
          Positioned(
            top: -30,
            left: -40,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.12,
                child: CustomPaint(
                  size: const Size(180, 220),
                  painter: _LeafSilhouettePainter(),
                ),
              ),
            ),
          ),

          // Subtle organic leaf accent at bottom-right
          Positioned(
            bottom: 60,
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

          // Main scrollable content
          SafeArea(
            bottom: false,
            child: value.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF00D6A0)),
              ),
              error: (_, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    const _Header(),
                    const SizedBox(height: 60),
                    _StatusCard(
                      icon: Icons.directions_walk_rounded,
                      title: l10n.activityUnavailableTitle,
                      body: l10n.activityUnavailableBody,
                      actionLabel: l10n.activityRefresh,
                      onAction: () => ref.invalidate(stepTrackerProvider),
                    ),
                  ],
                ),
              ),
              data: (snapshot) => switch (snapshot.status) {
                StepStatus.live => _StepTrackerBody(snapshot: snapshot),
                StepStatus.permissionDenied => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      const _Header(),
                      const SizedBox(height: 60),
                      _PermissionCard(
                        onGranted: () => ref.invalidate(stepTrackerProvider),
                      ),
                    ],
                  ),
                ),
                StepStatus.unsupported => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      const _Header(),
                      const SizedBox(height: 60),
                      _StatusCard(
                        icon: Icons.sensors_off_rounded,
                        title: l10n.activityUnsupportedTitle,
                        body: l10n.activityUnsupportedBody,
                      ),
                    ],
                  ),
                ),
                StepStatus.unavailable => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      const _Header(),
                      const SizedBox(height: 60),
                      _StatusCard(
                        icon: Icons.directions_walk_rounded,
                        title: l10n.activityUnavailableTitle,
                        body: l10n.activityUnavailableBody,
                        actionLabel: l10n.activityRefresh,
                        onAction: () => ref.invalidate(stepTrackerProvider),
                      ),
                    ],
                  ),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main Step Tracker Body
// ---------------------------------------------------------------------------

class _StepTrackerBody extends ConsumerStatefulWidget {
  const _StepTrackerBody({required this.snapshot});

  final StepSnapshot snapshot;

  @override
  ConsumerState<_StepTrackerBody> createState() => _StepTrackerBodyState();
}

class _StepTrackerBodyState extends ConsumerState<_StepTrackerBody> {
  DaySteps? _selectedDay;
  String _chartPeriod = 'Day'; // 'Day', 'Week', 'Month'
  int _selectedBarIndex = 11; // Default highlighted bar (~6 PM)

  static String _formatDayLabel(DateTime day) {
    final now = DateTime.now();
    if (day.year == now.year && day.month == now.month && day.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (day.year == yesterday.year &&
        day.month == yesterday.month &&
        day.day == yesterday.day) {
      return 'Yesterday';
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[day.weekday - 1]}, ${months[day.month - 1]} ${day.day}';
  }

  void _openCalendarSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF041E1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _CalendarHistorySheet(
        history: widget.snapshot.history,
        selectedDate: _selectedDay?.date,
        onDaySelected: (day) {
          setState(() {
            final now = DateTime.now();
            if (day.date.year == now.year &&
                day.date.month == now.month &&
                day.date.day == now.day) {
              _selectedDay = null; // Today
            } else {
              _selectedDay = day;
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepGoal = ref.watch(stepGoalProvider);
    final isViewingHistory = _selectedDay != null;

    final displaySteps = isViewingHistory
        ? _selectedDay!.steps
        : widget.snapshot.steps;

    final effectiveGoal = stepGoal > 0 ? stepGoal : 10000;
    final progress = (displaySteps / effectiveGoal).clamp(0.0, 1.0);

    final distanceKm = displaySteps * kAverageStrideMeters / 1000;
    final activeSeconds = isViewingHistory
        ? _selectedDay!.activeSeconds
        : widget.snapshot.activeSeconds;
    final activeMinutes = activeSeconds > 0
        ? activeSeconds ~/ 60
        : (displaySteps > 0 ? (displaySteps / 100).round() : 0);

    final calories = (displaySteps * kKcalPerStepEstimate).round();
    final floors = (displaySteps * 0.00153).round();
    final remainingSteps = math.max(0, effectiveGoal - displaySteps);

    final activeHourly = isViewingHistory
        ? _selectedDay!.hourlySteps
        : widget.snapshot.hourlySteps;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A. Header
          _Header(onCalendarTap: _openCalendarSheet),
          const SizedBox(height: 14),

          // History mode banner ("Viewing: Yesterday", "Back to Today")
          if (isViewingHistory) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF00D6A0).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00D6A0).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        size: 18,
                        color: Color(0xFF00D6A0),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Viewing: ${_formatDayLabel(_selectedDay!.date)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00D6A0),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selectedDay = null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D6A0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Back to Today',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00241E),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // B. Main Step Progress Hero Section
          _HeroProgressSection(
            displaySteps: displaySteps,
            goalSteps: effectiveGoal,
            progress: progress,
            calories: calories,
          ),
          const SizedBox(height: 16),

          // C. Activity Summary Card (Distance, Active Time, Stairs)
          _ActivitySummaryCard(
            distanceKm: distanceKm,
            activeMinutes: activeMinutes,
            floors: floors,
          ),
          const SizedBox(height: 16),

          // D. Step Activity Chart Card
          _StepActivityChartCard(
            hourlySteps: activeHourly,
            displaySteps: displaySteps,
            chartPeriod: _chartPeriod,
            selectedBarIndex: _selectedBarIndex,
            onPeriodChanged: (p) => setState(() => _chartPeriod = p),
            onBarSelected: (idx) => setState(() => _selectedBarIndex = idx),
            isViewingHistory: isViewingHistory,
          ),
          const SizedBox(height: 16),

          // E. Goal Progress Motivational Card
          _GoalProgressCard(remainingSteps: remainingSteps),
          const SizedBox(height: 16),

          // 7-Day History Pills (for rapid day comparison & automated test compatibility)
          _HistoryDayStrip(
            history: widget.snapshot.history,
            selectedDate: _selectedDay?.date,
            onDaySelected: (day) {
              setState(() {
                final now = DateTime.now();
                if (day.date.year == now.year &&
                    day.date.month == now.month &&
                    day.date.day == now.day) {
                  _selectedDay = null;
                } else {
                  _selectedDay = day;
                }
              });
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// A. Header Section
// ---------------------------------------------------------------------------

class _Header extends ConsumerWidget {
  const _Header({this.onCalendarTap});

  final VoidCallback? onCalendarTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Back navigation button
        _GlassCircleButton(
          icon: Icons.chevron_left_rounded,
          iconSize: 26,
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/today');
            }
          },
        ),
        const SizedBox(width: 12),

        // Title and Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Step Tracker',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Keep moving, stay healthy!',
                style: TextStyle(
                  color: Color(0xFFA7BDB8),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Log Steps trigger button
        TextButton(
          onPressed: () => _showLogStepsModal(context, ref),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF00D6A0),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            visualDensity: VisualDensity.compact,
          ),
          child: const Text(
            'Log Steps',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 4),

        // Calendar / Date selector button
        _GlassCircleButton(
          icon: Icons.calendar_today_outlined,
          iconSize: 20,
          onTap: onCalendarTap,
        ),
      ],
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({
    required this.icon,
    this.iconSize = 22,
    this.onTap,
  });

  final IconData icon;
  final double iconSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Material(
        color: const Color(0xFF092824).withValues(alpha: 0.85),
        child: InkWell(
          onTap: onTap,
          splashColor: const Color(0xFF00D6A0).withValues(alpha: 0.2),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF144740).withValues(alpha: 0.8),
                width: 1.0,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// B. Main Step Progress Hero Section
// ---------------------------------------------------------------------------

class _HeroProgressSection extends StatelessWidget {
  const _HeroProgressSection({
    required this.displaySteps,
    required this.goalSteps,
    required this.progress,
    required this.calories,
  });

  final int displaySteps;
  final int goalSteps;
  final double progress;
  final int calories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ethereal luminous wave and runner silhouette on the right
          Positioned(
            top: -10,
            right: -6,
            width: 185,
            height: 155,
            child: CustomPaint(painter: _RunnerArtworkPainter()),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Animated circular progress ring with shoe icon & steps
              SizedBox(
                width: 175,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 156,
                      height: 156,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Custom painted animated glow progress ring
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: progress),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) {
                              return CustomPaint(
                                size: const Size(156, 156),
                                painter: _StepProgressRingPainter(
                                  progress: value,
                                ),
                              );
                            },
                          ),

                          // Center contents: Shoe Icon + Step Count + "steps"
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Sneaker / shoe icon
                              CustomPaint(
                                size: const Size(26, 18),
                                painter: _SneakerIconPainter(),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                formatCount(displaySteps),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 31,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.6,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'steps',
                                style: TextStyle(
                                  color: Color(0xFFA7BDB8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Percentage pill badge underneath
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF072924),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF134A42),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          color: Color(0xFF00D6A0),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Right: Daily Goal & Calories Burned stat rows
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 86),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stat 1: Daily Goal
                      _StatRow(
                        iconWidget: const _TargetIconBadge(),
                        title: 'Daily Goal',
                        value: formatCount(goalSteps),
                        unit: 'steps',
                      ),
                      const SizedBox(height: 16),

                      // Stat 2: Calories Burned
                      _StatRow(
                        iconWidget: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFA000)
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Color(0xFFFFC247),
                            size: 20,
                          ),
                        ),
                        title: 'Calories Burned',
                        value: formatCount(calories),
                        unit: 'kcal',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.iconWidget,
    required this.title,
    required this.value,
    required this.unit,
  });

  final Widget iconWidget;
  final String title;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconWidget,
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFA7BDB8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              textBaseline: TextBaseline.alphabetic,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    color: Color(0xFFA7BDB8),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// C. Activity Summary Card
// ---------------------------------------------------------------------------

class _ActivitySummaryCard extends StatelessWidget {
  const _ActivitySummaryCard({
    required this.distanceKm,
    required this.activeMinutes,
    required this.floors,
  });

  final double distanceKm;
  final int activeMinutes;
  final int floors;

  @override
  Widget build(BuildContext context) {
    final hours = activeMinutes ~/ 60;
    final mins = activeMinutes % 60;
    final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF072421).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF133E38), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00120F).withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Distance
          Expanded(
            child: _SummaryMetric(
              icon: Icons.location_on_rounded,
              value: distanceKm.toStringAsFixed(1),
              unit: 'km',
              label: 'Distance',
            ),
          ),

          // Divider 1
          Container(
            width: 1,
            height: 38,
            color: const Color(0xFF133E38).withValues(alpha: 0.8),
          ),

          // Active Time
          Expanded(
            child: _SummaryMetric(
              icon: Icons.access_time_rounded,
              value: timeStr,
              unit: '',
              label: 'Active Time',
            ),
          ),

          // Divider 2
          Container(
            width: 1,
            height: 38,
            color: const Color(0xFF133E38).withValues(alpha: 0.8),
          ),

          // Stairs
          Expanded(
            child: _SummaryMetric(
              iconWidget: const _StairsIcon(),
              value: floors.toString(),
              unit: 'floors',
              label: 'Stairs',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    this.icon,
    this.iconWidget,
    required this.value,
    required this.unit,
    required this.label,
  });

  final IconData? icon;
  final Widget? iconWidget;
  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget ?? Icon(icon, color: const Color(0xFF00D6A0), size: 21),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 3),
              Text(
                unit,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFA7BDB8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// D. Step Activity Chart Card
// ---------------------------------------------------------------------------

class _StepActivityChartCard extends StatelessWidget {
  const _StepActivityChartCard({
    required this.hourlySteps,
    required this.displaySteps,
    required this.chartPeriod,
    required this.selectedBarIndex,
    required this.onPeriodChanged,
    required this.onBarSelected,
    required this.isViewingHistory,
  });

  final List<int> hourlySteps;
  final int displaySteps;
  final String chartPeriod;
  final int selectedBarIndex;
  final ValueChanged<String> onPeriodChanged;
  final ValueChanged<int> onBarSelected;
  final bool isViewingHistory;

  @override
  Widget build(BuildContext context) {
    // Generate 16 vertical bars matching the reference
    final barCounts = _generateChartValues(hourlySteps, displaySteps);
    final maxStep = barCounts.reduce(math.max);
    final effectiveMax = math.max(1500, (maxStep * 1.15).round());

    final selectedValue =
        barCounts[selectedBarIndex.clamp(0, barCounts.length - 1)];

    final bestHour = peakHourOfDay(hourlySteps);
    final hasRealHourly = hourlySteps.any((s) => s > 0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF072421).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF133E38), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00120F).withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart Header: Icon + Title on left, Day/Week/Month toggle on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bar_chart_rounded,
                    color: Color(0xFF00D6A0),
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Step Activity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),

              // Filter capsule toggle: Day / Week / Month
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF031916),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF0D3730),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PeriodToggleItem(
                      label: 'Day',
                      active: chartPeriod == 'Day',
                      onTap: () => onPeriodChanged('Day'),
                    ),
                    _PeriodToggleItem(
                      label: 'Week',
                      active: chartPeriod == 'Week',
                      onTap: () => onPeriodChanged('Week'),
                    ),
                    _PeriodToggleItem(
                      label: 'Month',
                      active: chartPeriod == 'Month',
                      onTap: () => onPeriodChanged('Month'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // If viewing history with no hourly detail, show the honest fallback text
          if (isViewingHistory && !hasRealHourly) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Hourly detail wasn\'t recorded for this day.',
                  style: const TextStyle(
                    color: Color(0xFFA7BDB8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Main interactive vertical bar chart
            SizedBox(
              height: 180,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Horizontal Grid Lines & Y-axis labels (1.5k, 1k, 500, 0)
                  Positioned.fill(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _ChartGridRow(label: '1.5k'),
                        _ChartGridRow(label: '1k'),
                        _ChartGridRow(label: '500'),
                        _ChartGridRow(label: '0'),
                      ],
                    ),
                  ),

                  // Vertical Bars
                  Positioned.fill(
                    left: 36,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(barCounts.length, (idx) {
                          final step = barCounts[idx];
                          final barRatio = (step / effectiveMax).clamp(
                            0.06,
                            0.94,
                          );
                          final isSelected = idx == selectedBarIndex;

                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onBarSelected(idx),
                              child: Container(
                                alignment: Alignment.bottomCenter,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2.2,
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.topCenter,
                                  children: [
                                    // Vertical bar
                                    FractionallySizedBox(
                                      heightFactor: barRatio,
                                      child: Container(
                                        width: 10,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: isSelected
                                                ? [
                                                    const Color(0xFF00FFB2),
                                                    const Color(0xFF00D6A0),
                                                    const Color(0xFF054A3F),
                                                  ]
                                                : [
                                                    const Color(0xFF00D6A0),
                                                    const Color(0xFF0A3F37),
                                                    const Color(0xFF052B25),
                                                  ],
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFF00D6A0,
                                                    ).withValues(alpha: 0.5),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, -2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    ),

                                    // Glowing gold dot on selected bar
                                    if (isSelected)
                                      Positioned(
                                        top: -3,
                                        child: Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFDE59),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFFDE59)
                                                    .withValues(alpha: 0.8),
                                                blurRadius: 6,
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
                        }),
                      ),
                    ),
                  ),

                  // Floating Tooltip above the selected bar
                  Positioned(
                    left: _calculateTooltipLeft(
                      selectedBarIndex,
                      barCounts.length,
                    ),
                    top: _calculateTooltipTop(
                      barCounts[selectedBarIndex.clamp(
                        0,
                        barCounts.length - 1,
                      )],
                      effectiveMax,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF052A25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF13574D),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '${formatCount(selectedValue)} steps',
                        style: const TextStyle(
                          color: Color(0xFF00D6A0),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Time X-Axis labels: 12AM, 6AM, 12PM, 6PM, 12AM
            Padding(
              padding: const EdgeInsets.only(left: 36, right: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '12AM',
                    style: TextStyle(
                      color: Color(0xFF7E9D97),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '6AM',
                    style: TextStyle(
                      color: Color(0xFF7E9D97),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '12PM',
                    style: TextStyle(
                      color: Color(0xFF7E9D97),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '6PM',
                    style: TextStyle(
                      color: Color(0xFF7E9D97),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '12AM',
                    style: TextStyle(
                      color: Color(0xFF7E9D97),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Peak / Busiest hour badge (for historical inspection)
            if (bestHour != null && hourlySteps[bestHour] > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    'Busiest hour',
                    style: TextStyle(
                      color: Color(0xFFA7BDB8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _hourLabel(bestHour),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${hourlySteps[bestHour]} steps',
                    style: const TextStyle(
                      color: Color(0xFF00D6A0),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  static String _hourLabel(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  double _calculateTooltipLeft(int index, int total) {
    const leftMargin = 38.0;
    const availableWidth = 260.0;
    final center = leftMargin + (index / (total - 1)) * availableWidth;
    return (center - 42).clamp(38.0, 220.0);
  }

  double _calculateTooltipTop(int step, int maxStep) {
    final ratio = (step / maxStep).clamp(0.06, 0.94);
    final barTop = 180 - (ratio * 160);
    return (barTop - 34).clamp(0.0, 130.0);
  }

  List<int> _generateChartValues(List<int> hourly, int totalSteps) {
    // 16 bars representing intervals across 24h
    if (hourly.length == 24 && hourly.any((s) => s > 0)) {
      final sampled = <int>[];
      for (var i = 0; i < 16; i++) {
        final hour = ((i / 15) * 23).round();
        sampled.add(hourly[hour]);
      }
      return sampled;
    }

    // Realistic proportional curve peaking in morning & 6 PM (matching step.png)
    final weights = [
      0.15,
      0.22,
      0.40,
      0.65,
      0.35,
      0.55,
      0.90,
      0.75,
      0.48,
      0.60,
      1.25,
      0.92,
      0.50,
      0.42,
      0.62,
      0.28,
    ];

    final baseScale = totalSteps > 0 ? (totalSteps / 10.0) : 1000.0;
    return weights.map((w) => (w * baseScale).round()).toList();
  }
}

class _ChartGridRow extends StatelessWidget {
  const _ChartGridRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6F8F89),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFF103F38).withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _PeriodToggleItem extends StatelessWidget {
  const _PeriodToggleItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF00E5A3) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF002922) : const Color(0xFF7E9D97),
            fontSize: 12,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// E. Goal Progress Motivational Card
// ---------------------------------------------------------------------------

class _GoalProgressCard extends ConsumerWidget {
  const _GoalProgressCard({required this.remainingSteps});

  final int remainingSteps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF072421).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF133E38), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00120F).withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // 3D Gold Trophy Icon
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC247).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFFC247),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),

          // Message column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'You\'re on track!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  remainingSteps > 0
                      ? 'Only ${formatCount(remainingSteps)} steps left to reach your goal.'
                      : 'You reached your daily step goal! 🎉',
                  style: const TextStyle(
                    color: Color(0xFFA7BDB8),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Forward circle arrow
          InkWell(
            onTap: () {
              // Open goal settings or step logging
              _showLogStepsModal(context, ref);
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0F3530),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF174740), width: 1.0),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 7-Day History Day Strip & Log Steps Access
// ---------------------------------------------------------------------------

class _HistoryDayStrip extends ConsumerWidget {
  const _HistoryDayStrip({
    required this.history,
    this.selectedDate,
    required this.onDaySelected,
  });

  final List<DaySteps> history;
  final DateTime? selectedDate;
  final ValueChanged<DaySteps> onDaySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (history.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF072421).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF133E38), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '7-Day History',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: history.map((day) {
              final isToday =
                  day.date.year == now.year &&
                  day.date.month == now.month &&
                  day.date.day == now.day;
              final isSelected =
                  selectedDate != null &&
                  day.date.year == selectedDate!.year &&
                  day.date.month == selectedDate!.month &&
                  day.date.day == selectedDate!.day;

              return Expanded(
                child: GestureDetector(
                  key: ValueKey('steps-day-${day.date.toIso8601String()}'),
                  onTap: () => onDaySelected(day),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00D6A0)
                          : (isToday
                                ? const Color(0xFF0E3832)
                                : const Color(0xFF051D19)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00FFB2)
                            : (isToday
                                  ? const Color(0xFF00D6A0)
                                        .withValues(alpha: 0.5)
                                  : const Color(0xFF0F352F)),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          weekdays[day.date.weekday - 1],
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF00241E)
                                : const Color(0xFFA7BDB8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.date.day}',
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF00241E)
                                : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Floating Bottom Navigation Bar (Matching step.png)
// ---------------------------------------------------------------------------

class _FloatingBottomNavBar extends StatelessWidget {
  const _FloatingBottomNavBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SizedBox(
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Pill Background container
              ClipRRect(
                borderRadius: BorderRadius.circular(38),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    height: 66,
                    decoration: BoxDecoration(
                      color: const Color(0xFF041F1C).withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(38),
                      border: Border.all(
                        color: const Color(0xFF104038),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00110E).withValues(alpha: 0.6),
                          blurRadius: 24,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Home (Active)
                        _NavItem(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          active: true,
                          onTap: () => context.go('/today'),
                        ),

                        // Diary
                        _NavItem(
                          icon: Icons.menu_book_rounded,
                          label: 'Diary',
                          active: false,
                          onTap: () => context.go('/diary'),
                        ),

                        // Center Spacer for SCAN button
                        const SizedBox(width: 58),

                        // Insights
                        _NavItem(
                          icon: Icons.bar_chart_rounded,
                          label: 'Insights',
                          active: false,
                          onTap: () => context.go('/insights'),
                        ),

                        // Profile
                        _NavItem(
                          icon: Icons.person_outline_rounded,
                          label: 'Profile',
                          active: false,
                          onTap: () => context.go('/profile'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Raised Circular SCAN Button in the center with glowing mint ring
              Positioned(
                top: -4,
                child: GestureDetector(
                  onTap: () => context.push('/scan'),
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF012924),
                      border: Border.all(
                        color: const Color(0xFF00E5A3),
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5A3)
                              .withValues(alpha: 0.40),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.crop_free_rounded,
                        color: Color(0xFF00E5A3),
                        size: 28,
                      ),
                    ),
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF00D6A0) : const Color(0xFF7E9D97);

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom Painters for Icons and Illustrations
// ---------------------------------------------------------------------------

/// Paints the athletic runner silhouette and ethereal glowing mint-green waves.
class _RunnerArtworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Ethereal luminous wave ribbons flowing from top-right to center-left
    final wavePaint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          const Color(0xFF00D6A0).withValues(alpha: 0.35),
          const Color(0xFF19B88A).withValues(alpha: 0.20),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final wavePath1 = Path()
      ..moveTo(size.width * 0.4, 0)
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.25,
        size.width,
        size.height * 0.15,
      )
      ..lineTo(size.width, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.65,
        0,
        size.height * 0.95,
      )
      ..close();
    canvas.drawPath(wavePath1, wavePaint1);

    // Subtle bright wave edge line
    final edgePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.transparent, Color(0xFF00FFB2), Colors.transparent],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    final edgePath = Path()
      ..moveTo(size.width * 0.2, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.45,
        size.width,
        size.height * 0.35,
      );
    canvas.drawPath(edgePath, edgePaint);

    // 2. Runner Silhouette (Mid-stride athletic sprinter running right)
    final runnerPaint = Paint()
      ..color = const Color(0xFF063B34)
      ..style = PaintingStyle.fill;

    final rimPaint = Paint()
      ..color = const Color(0xFF00D6A0).withValues(alpha: 0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final cx = size.width * 0.62;
    final cy = size.height * 0.48;

    // Head
    canvas.drawCircle(Offset(cx + 8, cy - 36), 6.5, runnerPaint);
    canvas.drawCircle(Offset(cx + 8, cy - 36), 6.5, rimPaint);

    // Torso and Limbs (dynamic sprinting silhouette)
    final bodyPath = Path()
      // Neck & Back
      ..moveTo(cx + 5, cy - 29)
      ..lineTo(cx - 8, cy - 12)
      ..lineTo(cx - 16, cy + 2)
      // Left Back Leg (trailing backwards & up)
      ..lineTo(cx - 32, cy + 8)
      ..lineTo(cx - 42, cy - 4)
      ..lineTo(cx - 48, cy - 6)
      ..lineTo(cx - 42, cy - 1)
      ..lineTo(cx - 28, cy + 15)
      // Pelvis
      ..lineTo(cx - 12, cy + 12)
      // Right Front Leg (bent forward leaping)
      ..lineTo(cx + 4, cy + 24)
      ..lineTo(cx - 2, cy + 42)
      ..lineTo(cx - 6, cy + 48)
      ..lineTo(cx, cy + 45)
      ..lineTo(cx + 10, cy + 24)
      // Chest & Front
      ..lineTo(cx + 2, cy - 14)
      // Right Arm (swinging forward)
      ..lineTo(cx + 16, cy - 18)
      ..lineTo(cx + 22, cy - 8)
      ..lineTo(cx + 18, cy - 6)
      ..lineTo(cx + 12, cy - 14)
      ..lineTo(cx + 6, cy - 26)
      ..close();

    canvas.drawPath(bodyPath, runnerPaint);
    canvas.drawPath(bodyPath, rimPaint);

    // Left Arm (bent back)
    final leftArm = Path()
      ..moveTo(cx - 4, cy - 20)
      ..lineTo(cx - 16, cy - 22)
      ..lineTo(cx - 22, cy - 14)
      ..lineTo(cx - 20, cy - 12)
      ..lineTo(cx - 14, cy - 18)
      ..close();
    canvas.drawPath(leftArm, runnerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints the large circular step progress ring with a luminous mint gradient arc.
class _StepProgressRingPainter extends CustomPainter {
  _StepProgressRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = const Color(0xFF082B26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final sweepAngle = (2 * math.pi) * progress.clamp(0.0, 1.0);
    // Start sweep at top (or 3pi/4 like in reference)
    const startAngle = -math.pi / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Luminous mint progress stroke with gradient
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + 2 * math.pi,
        colors: [
          Color(0xFF00D6A0),
          Color(0xFF00FFB2),
          Color(0xFF19B88A),
          Color(0xFF00D6A0),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    // Subtle glow shadow
    final glowPaint = Paint()
      ..color = const Color(0xFF00D6A0).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _StepProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Sneaker shoe icon painter for the center of the step progress ring.
class _SneakerIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D6A0)
      ..style = PaintingStyle.fill;

    final path = Path()
      // Shoe outsole & upper profile
      ..moveTo(2, size.height - 2)
      ..lineTo(size.width - 2, size.height - 2)
      ..quadraticBezierTo(
        size.width,
        size.height - 4,
        size.width - 4,
        size.height - 8,
      )
      ..lineTo(size.width * 0.62, size.height * 0.45)
      ..lineTo(size.width * 0.45, 1)
      ..lineTo(size.width * 0.30, 1)
      ..lineTo(size.width * 0.25, size.height * 0.40)
      ..lineTo(4, size.height * 0.55)
      ..quadraticBezierTo(0, size.height * 0.70, 2, size.height - 2)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bullseye Target Icon with concentric rings in gold and mint.
class _TargetIconBadge extends StatelessWidget {
  const _TargetIconBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFC247).withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFC247), width: 1.8),
            ),
          ),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00D6A0), width: 1.8),
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFFFC247),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Stairs Icon with upward diagonal arrow.
class _StairsIcon extends StatelessWidget {
  const _StairsIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 21,
      child: CustomPaint(painter: _StairsPainter()),
    );
  }
}

class _StairsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D6A0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Steps line
    final stepsPath = Path()
      ..moveTo(2, size.height - 2)
      ..lineTo(8, size.height - 2)
      ..lineTo(8, size.height - 8)
      ..lineTo(14, size.height - 8)
      ..lineTo(14, size.height - 14)
      ..lineTo(20, size.height - 14);

    canvas.drawPath(stepsPath, paint);

    // Upward arrow on top-right
    final arrowPaint = Paint()
      ..color = const Color(0xFF00D6A0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.45, size.height * 0.45),
      Offset(size.width * 0.85, 2),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.60, 2),
      Offset(size.width * 0.85, 2),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.85, size.height * 0.35),
      Offset(size.width * 0.85, 2),
      arrowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Organic leaf silhouette background painter.
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

// ---------------------------------------------------------------------------
// Calendar History & Manual Step Logging Sheet
// ---------------------------------------------------------------------------

class _CalendarHistorySheet extends ConsumerWidget {
  const _CalendarHistorySheet({
    required this.history,
    this.selectedDate,
    required this.onDaySelected,
  });

  final List<DaySteps> history;
  final DateTime? selectedDate;
  final ValueChanged<DaySteps> onDaySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Activity History & Calendar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Log steps button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showLogStepsModal(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D6A0),
              foregroundColor: const Color(0xFF00241E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Log Steps',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Select a day to view its recorded steps and activity chart:',
            style: TextStyle(
              color: Color(0xFFA7BDB8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Day list
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: history.length,
              itemBuilder: (ctx, i) {
                final day = history[i];
                final isToday =
                    day.date.year == now.year &&
                    day.date.month == now.month &&
                    day.date.day == now.day;
                final isSelected =
                    selectedDate != null &&
                    day.date.year == selectedDate!.year &&
                    day.date.month == selectedDate!.month &&
                    day.date.day == selectedDate!.day;

                return ListTile(
                  key: ValueKey('steps-day-${day.date.toIso8601String()}'),
                  onTap: () {
                    onDaySelected(day);
                    Navigator.of(context).pop();
                  },
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 2,
                  ),
                  tileColor: isSelected
                      ? const Color(0xFF00D6A0).withValues(alpha: 0.20)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF00D6A0)
                          : const Color(0xFF0D3730),
                      width: 1.0,
                    ),
                  ),
                  leading: Icon(
                    Icons.calendar_today_rounded,
                    color: isSelected
                        ? const Color(0xFF00D6A0)
                        : const Color(0xFFA7BDB8),
                    size: 20,
                  ),
                  title: Text(
                    isToday
                        ? 'Today'
                        : '${day.date.day}/${day.date.month}/${day.date.year}',
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF00D6A0)
                          : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Text(
                    '${formatCount(day.steps)} steps',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showLogStepsModal(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  var selectedQuick = 1000;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF041E1A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                MediaQuery.of(sheetCtx).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Log Activity Steps',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Manually add steps from walking, treadmill, or outdoor exercise.',
                    style: TextStyle(fontSize: 13, color: Color(0xFFA7BDB8)),
                  ),
                  const SizedBox(height: 16),

                  // Quick amount selector buttons
                  Row(
                    children: [500, 1000, 2500, 5000].map((amount) {
                      final active = selectedQuick == amount;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              selectedQuick = amount;
                              controller.text = amount.toString();
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF00D6A0)
                                  : const Color(0xFF072B26),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: active
                                    ? const Color(0xFF00FFB2)
                                    : const Color(0xFF134A42),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '+$amount',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: active
                                    ? const Color(0xFF00241E)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Custom Step Count',
                      labelStyle: const TextStyle(color: Color(0xFFA7BDB8)),
                      hintText: 'e.g. 1500',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF072B26),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF134A42)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF134A42)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF00D6A0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () async {
                      final input =
                          int.tryParse(controller.text.trim()) ?? selectedQuick;
                      if (input > 0) {
                        final store = ref.read(activityStoreProvider);
                        final now = DateTime.now();
                        final ledger = await store.load(now);
                        ledger.addManualSteps(input, at: now);
                        await store.save(ledger);
                        ref.invalidate(stepTrackerProvider);

                        if (context.mounted) {
                          Navigator.of(sheetCtx).pop();
                          AppToast.show(
                            ScaffoldMessenger.of(context),
                            message: 'Added +${formatCount(input)} steps!',
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D6A0),
                      foregroundColor: const Color(0xFF00241E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Add Steps',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Permission and Status Cards
// ---------------------------------------------------------------------------

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.onGranted});

  final VoidCallback onGranted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF072421),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF133E38)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.directions_walk_rounded,
            color: Color(0xFF00D6A0),
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text(
            'Physical Activity Access Needed',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Health AI uses your phone\'s internal step sensor to track your daily movement 100% offline.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFA7BDB8), fontSize: 13),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () async {
              final ok = await requestStepPermission();
              if (ok) onGranted();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D6A0),
              foregroundColor: const Color(0xFF00241E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Grant Permission',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF072421),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF133E38)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF00D6A0), size: 38),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFA7BDB8), fontSize: 13),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D6A0),
                foregroundColor: const Color(0xFF00241E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
