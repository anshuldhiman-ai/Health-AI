import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:app/core/format/count_format.dart';
import 'package:app/data/sensors/step_tracker.dart';
import 'package:app/design_system/components/app_toast.dart';
import 'package:app/design_system/components/unified_floating_nav_bar.dart';
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
      bottomNavigationBar: const UnifiedFloatingNavBar(activeBranchIndex: 0),
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
  String _chartPeriod = 'Day'; // 'Day' or 'Week'
  // No default bar: the chart highlights the current hour/day, computed
  // from real data, rather than an arbitrary 6 PM placeholder.
  int? _selectedBarIndex;

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
    final l10n = AppLocalizations.of(context)!;
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
    // Measured walking time only. A day the app never watched reads "—"
    // instead of a step-derived guess (Section 7.3: estimates are never
    // dressed up as measurements).
    final activeMinutes = activeSeconds ~/ 60;
    final measuredActive = activeSeconds > 0;

    final calories = (displaySteps * kKcalPerStepEstimate).round();
    final cadence = isViewingHistory ? 0 : widget.snapshot.displayCadence;
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
                        l10n.activityViewingDay(
                          _formatDayLabel(_selectedDay!.date),
                        ),
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
                      child: Text(
                        l10n.activityBackToToday,
                        style: const TextStyle(
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
            measuredActive: measuredActive,
            cadenceSpm: cadence,
          ),
          const SizedBox(height: 16),

          // D. Step Activity Chart Card
          _StepActivityChartCard(
            hourlySteps: activeHourly,
            history: widget.snapshot.history,
            displaySteps: displaySteps,
            chartPeriod: _chartPeriod,
            selectedBarIndex: _selectedBarIndex,
            onPeriodChanged: (p) => setState(() {
              _chartPeriod = p;
              _selectedBarIndex = null;
            }),
            onBarSelected: (idx) => setState(() => _selectedBarIndex = idx),
            isViewingHistory: isViewingHistory,
            reconciledSteps: isViewingHistory
                ? (_selectedDay?.reconciledSteps ?? 0)
                : widget.snapshot.reconciledSteps,
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
    final l10n = AppLocalizations.of(context)!;
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
            children: [
              Text(
                l10n.activityStepTracker,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.activityTagline,
                style: const TextStyle(
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
          child: Text(
            l10n.activityLogSteps,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
    final l10n = AppLocalizations.of(context)!;
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
                              Text(
                                l10n.activityStepsUnit,
                                style: const TextStyle(
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
                        title: l10n.activityDailyGoal,
                        value: formatCount(goalSteps),
                        unit: l10n.activityStepsUnit,
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
                        title: l10n.activityCaloriesBurned,
                        value: formatCount(calories),
                        unit: l10n.activityKcalUnit,
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
    required this.measuredActive,
    required this.cadenceSpm,
  });

  final double distanceKm;
  final int activeMinutes;

  /// False when no walking interval was measured (for example a day the
  /// app only saw through 15-minute background samples). The card then
  /// shows an em dash instead of inventing time from the step count.
  final bool measuredActive;
  final int cadenceSpm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hours = activeMinutes ~/ 60;
    final mins = activeMinutes % 60;
    final timeStr = !measuredActive
        ? '—'
        : (hours > 0 ? '${hours}h ${mins}m' : '${mins}m');

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
          // Distance (an estimate: average stride × measured steps)
          Expanded(
            child: _SummaryMetric(
              icon: Icons.location_on_rounded,
              value: distanceKm.toStringAsFixed(1),
              unit: 'km',
              label: l10n.activityDistance,
            ),
          ),

          // Divider 1
          Container(
            width: 1,
            height: 38,
            color: const Color(0xFF133E38).withValues(alpha: 0.8),
          ),

          // Active Time (measured walking intervals only)
          Expanded(
            child: _SummaryMetric(
              icon: Icons.access_time_rounded,
              value: timeStr,
              unit: '',
              label: l10n.activityActiveTime,
            ),
          ),

          // Divider 2
          Container(
            width: 1,
            height: 38,
            color: const Color(0xFF133E38).withValues(alpha: 0.8),
          ),

          // Cadence is measured from event timing; stairs are not
          // available from the step counter, so they are not shown.
          Expanded(
            child: _SummaryMetric(
              icon: Icons.speed_rounded,
              value: cadenceSpm > 0 ? '$cadenceSpm' : '—',
              unit: cadenceSpm > 0 ? 'spm' : '',
              label: l10n.activityCadence,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF00D6A0), size: 21),
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
    required this.history,
    required this.displaySteps,
    required this.chartPeriod,
    required this.selectedBarIndex,
    required this.onPeriodChanged,
    required this.onBarSelected,
    required this.isViewingHistory,
    required this.reconciledSteps,
  });

  final List<int> hourlySteps;
  final List<DaySteps> history;
  final int displaySteps;
  final String chartPeriod;
  final int? selectedBarIndex;
  final ValueChanged<String> onPeriodChanged;
  final ValueChanged<int> onBarSelected;
  final bool isViewingHistory;
  final int reconciledSteps;

  bool get _isWeek => chartPeriod == 'Week';

  /// Bars come only from recorded data. There is no generated curve: a
  /// day with no steps draws no bars, and an unrecorded hour is zero.
  List<_ChartBar> _barsFor(Locale locale) {
    if (_isWeek) {
      return [
        for (final day in history)
          _ChartBar(
            label: _weekdayLabel(day.date, locale),
            detail: '${day.date.day}/${day.date.month}',
            steps: day.steps,
          ),
      ];
    }
    final hourly = hourlySteps.length == 24
        ? hourlySteps
        : List<int>.filled(24, 0);
    return [
      for (var hour = 0; hour < 24; hour++)
        _ChartBar(
          label: _hourLabel(hour, locale),
          detail: _hourLabel(hour, locale),
          steps: hourly[hour],
        ),
    ];
  }

  int get _defaultIndex {
    if (_isWeek) return math.max(0, history.length - 1);
    if (isViewingHistory) {
      final peak = peakHourOfDay(hourlySteps);
      if (peak != null) return peak;
    }
    return DateTime.now().hour;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bars = _barsFor(Localizations.localeOf(context));
    final maxStep = bars.fold<int>(
      0,
      (value, bar) => math.max(value, bar.steps),
    );
    final effectiveMax = math.max(1500, (maxStep * 1.15).round());
    final selected = (selectedBarIndex ?? _defaultIndex).clamp(
      0,
      bars.length - 1,
    );
    final selectedValue = bars[selected].steps;
    final bestHour = peakHourOfDay(hourlySteps);
    final hasRealHourly =
        hourlySteps.length == 24 && hourlySteps.any((s) => s > 0);

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
                  Text(
                    l10n.activityChartTitle,
                    style: const TextStyle(
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
                      label: l10n.activityPeriodDay,
                      active: chartPeriod == 'Day',
                      onTap: () => onPeriodChanged('Day'),
                    ),
                    _PeriodToggleItem(
                      label: l10n.activityPeriodWeek,
                      active: chartPeriod == 'Week',
                      onTap: () => onPeriodChanged('Week'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // If viewing history with no hourly detail, show the honest fallback text.
          // The Week view does not need hourly buckets: it plots real day
          // totals from the seven-day history.
          if (!_isWeek && isViewingHistory && !hasRealHourly) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  l10n.activityNoHourlyDetail,
                  style: const TextStyle(
                    color: Color(0xFFA7BDB8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ] else if (displaySteps <= 0) ...[
            // Nothing recorded for this day. An empty chart states that
            // plainly instead of drawing an invented curve.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  l10n.activityNoStepsRecorded,
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
                  // Horizontal grid lines, labelled from the real maximum of this
                  // chart rather than a fixed 1.5k scale.
                  Positioned.fill(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ChartGridRow(label: _axisLabel(effectiveMax)),
                        _ChartGridRow(
                          label: _axisLabel((effectiveMax * 2 / 3).round()),
                        ),
                        _ChartGridRow(
                          label: _axisLabel((effectiveMax / 3).round()),
                        ),
                        const _ChartGridRow(label: '0'),
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
                        children: List.generate(bars.length, (idx) {
                          final step = bars[idx].steps;
                          // A zero hour draws no bar. The old build used a
                          // minimum height, which made an empty day look
                          // like measured movement.
                          final barRatio = step <= 0
                              ? 0.0
                              : (step / effectiveMax).clamp(0.06, 0.94);
                          final isSelected = idx == selected;

                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onBarSelected(idx),
                              child: Container(
                                alignment: Alignment.bottomCenter,
                                padding: EdgeInsets.symmetric(
                                  horizontal: _isWeek ? 6.0 : 1.4,
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.topCenter,
                                  children: [
                                    // Vertical bar
                                    FractionallySizedBox(
                                      heightFactor: barRatio,
                                      child: Container(
                                        width: _isWeek ? 18 : 6,
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
                    left: _calculateTooltipLeft(selected, bars.length),
                    top: _calculateTooltipTop(selectedValue, effectiveMax),
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
                        '${bars[selected].detail} · '
                        '${l10n.activityStepsCount(formatCount(selectedValue))}',
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

            // X-axis labels: five time markers for a day, one per bar for a
            // week. Both are derived from the same data the bars use.
            Padding(
              padding: const EdgeInsets.only(left: 36, right: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _isWeek
                    ? [
                        for (final bar in bars)
                          Text(
                            bar.label,
                            style: const TextStyle(
                              color: Color(0xFF7E9D97),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ]
                    : [
                        for (final hour in const [0, 6, 12, 18, 0])
                          Text(
                            _hourLabel(hour, Localizations.localeOf(context)),
                            style: const TextStyle(
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
                  Text(
                    l10n.activityBusiestHour,
                    style: const TextStyle(
                      color: Color(0xFFA7BDB8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _hourLabel(bestHour, Localizations.localeOf(context)),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.activityStepsCount(formatCount(hourlySteps[bestHour])),
                    style: const TextStyle(
                      color: Color(0xFF00D6A0),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],

            // Steps recovered from a gap longer than two hours (the app was
            // not running). Said plainly rather than hidden, because the
            // hour-by-hour split of a long gap is an interpolation.
            if (reconciledSteps > 0) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: Color(0xFF7E9D97),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.activityReconciledNote(formatCount(reconciledSteps)),
                      style: const TextStyle(
                        color: Color(0xFF7E9D97),
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
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

  /// Clock label for a chart hour, formatted by `intl` for the active
  /// locale so a 24-hour locale reads "18" rather than "6 PM".
  ///
  /// Falls back to a compact fixed form if the locale's date symbols are
  /// not loaded: a missing translation table must never crash a chart.
  static String _hourLabel(int hour, Locale locale) {
    try {
      final label = DateFormat(
        'j',
        locale.toLanguageTag(),
      ).format(DateTime(2000, 1, 1, hour));
      // CLDR separates the hour from AM/PM with U+202F (narrow no-break
      // space). It looks identical but breaks search, so normalise it to
      // an ordinary space and keep the label greppable.
      return label.replaceAll(' ', ' ').replaceAll(' ', ' ');
    } catch (_) {
      if (hour == 0) return '12 AM';
      if (hour < 12) return '$hour AM';
      if (hour == 12) return '12 PM';
      return '${hour - 12} PM';
    }
  }

  /// Compact Y-axis label: 1200 -> "1.2k". Values stay readable at the
  /// 32 px width the grid gutter allows.
  static String _axisLabel(int value) {
    if (value < 1000) return '$value';
    final thousands = value / 1000;
    return thousands >= 10
        ? '${thousands.round()}k'
        : '${thousands.toStringAsFixed(1)}k';
  }

  /// Weekday abbreviation for a history bar, localised by `intl`, with a
  /// numeric fallback so a missing locale table cannot crash the chart.
  static String _weekdayLabel(DateTime date, Locale locale) {
    try {
      return DateFormat.E(locale.toLanguageTag()).format(date);
    } catch (_) {
      return '${date.day}/${date.month}';
    }
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
}

/// One column of the activity chart. Labels come from the data itself, so
/// a day view is labelled by hour and a week view by weekday.
class _ChartBar {
  const _ChartBar({
    required this.label,
    required this.detail,
    required this.steps,
  });

  final String label;
  final String detail;
  final int steps;
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
    final l10n = AppLocalizations.of(context)!;
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
                Text(
                  l10n.activityOnTrack,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  remainingSteps > 0
                      ? l10n.activityStepsLeftToGoal(
                          formatCount(remainingSteps),
                        )
                      : l10n.activityGoalReached,
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

    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final now = DateTime.now();

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
          Text(
            l10n.activitySevenDayHistory,
            style: const TextStyle(
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
                          DateFormat.E(locale.toLanguageTag())
                              .format(day.date)
                              .characters
                              .first,
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
// 3. Floating Bottom Navigation Bar (Uses UnifiedFloatingNavBar)
// ---------------------------------------------------------------------------

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
    final l10n = AppLocalizations.of(context)!;
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
              Text(
                l10n.activityHistoryTitle,
                style: const TextStyle(
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
            label: Text(
              l10n.activityLogSteps,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            l10n.activityHistoryHint,
            style: const TextStyle(
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
                    l10n.activityStepsCount(formatCount(day.steps)),
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
  final l10n = AppLocalizations.of(context)!;
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
                      Text(
                        l10n.activityLogActivitySteps,
                        style: const TextStyle(
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
                  Text(
                    l10n.activityManualSheetBody,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFA7BDB8),
                    ),
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
                      labelText: l10n.activityCustomStepCount,
                      labelStyle: const TextStyle(color: Color(0xFFA7BDB8)),
                      hintText: l10n.activityCustomStepHint,
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
                            message: l10n.activityStepsAdded(
                              formatCount(input),
                            ),
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
                    child: Text(
                      l10n.activityAddSteps,
                      style: const TextStyle(
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
    final l10n = AppLocalizations.of(context)!;
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
          Text(
            l10n.activityPermissionHeading,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.activityPermissionReason,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFA7BDB8), fontSize: 13),
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
            child: Text(
              l10n.activityGrantPermission,
              style: const TextStyle(fontWeight: FontWeight.w800),
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
