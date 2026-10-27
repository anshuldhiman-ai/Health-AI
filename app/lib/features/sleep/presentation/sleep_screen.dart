import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/data/preferences/sleep_controller.dart';
import 'package:app/design_system/components/app_toast.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/sleep_record.dart';

/// Screen 5/9: Sleep Tracker & Smart Alarm matching ref_ui_updated.png
///
/// Visual Highlights:
/// - Midnight background with soft top-right teal/cyan & top-left violet aurora auras
/// - Circular back button and clean title
/// - Unified Hero Card: Dual neon circular gauges (Sleep Quality 92% & Sleep 7h 20m)
///   separated by silver '&', stage legend, and authentic stepped sleep architecture graph
/// - Interactive Smart Alarm card with "Set for 06:45 AM", +/- buttons,
///   and emerald-track tick-marked wake window slider
/// - Snooze Log Analysis card with Behavioral Routine Habits & Behavioral Snooze Habits
class SleepScreen extends ConsumerStatefulWidget {
  const SleepScreen({super.key});

  @override
  ConsumerState<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends ConsumerState<SleepScreen> {
  int _alarmHour = 6;
  int _alarmMinute = 45;
  double _wakeWindowMinutes = 20;

  @override
  void initState() {
    super.initState();
    final record = ref.read(sleepTodayProvider);
    if (record != null) {
      _alarmHour = (record.wakeMinutes ~/ 60) % 24;
      _alarmMinute = record.wakeMinutes % 60;
    }
  }

  void _adjustAlarm(int deltaMinutes) {
    setState(() {
      var total = _alarmHour * 60 + _alarmMinute + deltaMinutes;
      if (total < 0) total += 24 * 60;
      total = total % (24 * 60);
      _alarmHour = total ~/ 60;
      _alarmMinute = total % 60;
    });
  }

  Future<void> _saveAlarm() async {
    const bedMinutes = 23 * 60 + 15; // 11:15 PM
    final wakeMinutes = _alarmHour * 60 + _alarmMinute;
    await ref.read(sleepProvider.notifier).save(
          bedMinutes: bedMinutes,
          wakeMinutes: wakeMinutes,
        );
    if (!mounted) return;
    AppToast.show(
      ScaffoldMessenger.of(context),
      message: 'Alarm set for ${_formattedAlarmTime()}!',
    );
  }

  Future<void> _showSetSleepGoalSheet(BuildContext context) async {
    final sleepState = ref.read(sleepProvider);
    var selectedMinutes = sleepState.targetMinutes;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final hours = selectedMinutes ~/ 60;
            final mins = selectedMinutes % 60;
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Set Daily Sleep Goal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Recommended adult sleep is 7 to 9 hours nightly.',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed: selectedMinutes > 300
                            ? () => setSheetState(() => selectedMinutes -= 30)
                            : null,
                        icon: const Icon(Icons.remove_rounded, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.white12),
                      ),
                      const SizedBox(width: 24),
                      Column(
                        children: [
                          Text(
                            mins == 0 ? '${hours}h' : '${hours}h ${mins}m',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                          const Text(
                            'Target duration',
                            style: TextStyle(fontSize: 12, color: Colors.white60),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      IconButton.filledTonal(
                        onPressed: selectedMinutes < 720
                            ? () => setSheetState(() => selectedMinutes += 30)
                            : null,
                        icon: const Icon(Icons.add_rounded, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.white12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    children: [
                      (7 * 60, '7h'),
                      (7 * 60 + 30, '7.5h'),
                      (8 * 60, '8h'),
                      (8 * 60 + 30, '8.5h'),
                      (9 * 60, '9h'),
                    ].map((tuple) {
                      final isSel = selectedMinutes == tuple.$1;
                      return ChoiceChip(
                        label: Text(
                          tuple.$2,
                          style: TextStyle(
                            color: isSel ? Colors.black : Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        selected: isSel,
                        selectedColor: const Color(0xFF38BDF8),
                        backgroundColor: Colors.white12,
                        onSelected: (_) => setSheetState(() => selectedMinutes = tuple.$1),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      await ref.read(sleepProvider.notifier).setGoal(selectedMinutes);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    child: const Text('Save Sleep Goal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteSleep(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Today's Sleep Log?", style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to remove today\'s recorded sleep log?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(sleepProvider.notifier).removeToday();
      if (context.mounted) {
        AppToast.show(ScaffoldMessenger.of(context), message: "Today's sleep log removed");
      }
    }
  }

  String _formattedAlarmTime() {
    final period = _alarmHour >= 12 ? 'PM' : 'AM';
    final h = _alarmHour % 12 == 0 ? 12 : _alarmHour % 12;
    final m = _alarmMinute.toString().padLeft(2, '0');
    return '${h.toString().padLeft(2, '0')}:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final sleepRecord = ref.watch(sleepTodayProvider);
    final sleepState = ref.watch(sleepProvider);

    final hasRealRecord = sleepRecord != null;
    final durationMinutes = hasRealRecord ? sleepRecord.durationMinutes : 440; // Default to 7h 20m if unset
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    final goalMinutes = sleepState.targetMinutes;
    final qualityScore = hasRealRecord
        ? ((durationMinutes / goalMinutes) * 100).round().clamp(10, 100)
        : 92; // 92% per reference mockup

    final durationFormatted = hasRealRecord
        ? (minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m')
        : '7h 20m';

    return Scaffold(
      backgroundColor: const Color(0xFF090D1A),
      body: Stack(
        children: [
          // Ambient aurora gradient glow in top-right and top-left
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0D9488).withValues(alpha: 0.22),
                    const Color(0xFF10B981).withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C3AED).withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                10,
                AppSpacing.screenPadding,
                32,
              ),
              children: [
                // Top Navigation Bar
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Sleep Tracker & Smart Alarm',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
                      color: const Color(0xFF0F172A),
                      onSelected: (val) {
                        if (val == 'goal') {
                          _showSetSleepGoalSheet(context);
                        } else if (val == 'delete') {
                          _confirmDeleteSleep(context);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'goal',
                          child: Row(
                            children: [
                              Icon(Icons.tune_rounded, color: Colors.white70, size: 18),
                              SizedBox(width: 10),
                              Text('Set Sleep Goal', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        if (hasRealRecord)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                SizedBox(width: 10),
                                Text('Delete Today\'s Log', style: TextStyle(color: Colors.redAccent)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Unified Hero Card (Dual Gauges + Legend + Stepped Architecture Graph)
                _SleepQualityAndStagesHeroCard(
                  qualityPercent: qualityScore,
                  durationFormatted: durationFormatted,
                  targetMinutes: goalMinutes,
                  actualMinutes: durationMinutes,
                ),
                const SizedBox(height: 16),

                // Interactive Smart Alarm Card
                _InteractiveSmartAlarmCard(
                  formattedTime: _formattedAlarmTime(),
                  wakeWindowMinutes: _wakeWindowMinutes,
                  onMinus: () => _adjustAlarm(-15),
                  onPlus: () => _adjustAlarm(15),
                  onWindowChanged: (val) => setState(() => _wakeWindowMinutes = val),
                  onSave: _saveAlarm,
                ),
                const SizedBox(height: 16),

                // Snooze Log Analysis Card
                const _SnoozeLogAnalysisCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Unified Hero Card enclosing Dual Circular Gauges & Stepped Sleep Stages Graph
class _SleepQualityAndStagesHeroCard extends StatelessWidget {
  const _SleepQualityAndStagesHeroCard({
    required this.qualityPercent,
    required this.durationFormatted,
    required this.targetMinutes,
    required this.actualMinutes,
  });

  final int qualityPercent;
  final String durationFormatted;
  final int targetMinutes;
  final int actualMinutes;

  @override
  Widget build(BuildContext context) {
    final sleepProgress = (actualMinutes / (targetMinutes > 0 ? targetMinutes : 480))
        .clamp(0.05, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2A).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Dual Circular Gauges with '&' separator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Gauge: Sleep Quality (Violet/Purple)
              _NeonCircleGauge(
                title: 'Sleep Quality',
                value: '$qualityPercent%',
                progress: (qualityPercent / 100).clamp(0.05, 1.0),
                gradientColors: const [
                  Color(0xFFA855F7),
                  Color(0xFF8B5CF6),
                  Color(0xFF6366F1),
                ],
                glowColor: const Color(0xFFA855F7),
              ),

              // Center '&'
              const Text(
                '&',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: Colors.white54,
                ),
              ),

              // Right Gauge: Sleep Duration (Cyan/Sky-Blue)
              _NeonCircleGauge(
                title: 'Sleep',
                value: durationFormatted,
                progress: sleepProgress,
                gradientColors: const [
                  Color(0xFF38BDF8),
                  Color(0xFF06B6D4),
                  Color(0xFF2DD4BF),
                ],
                glowColor: const Color(0xFF38BDF8),
                hasHeadDot: true,
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Legend Row: Deep, REM, Light
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _StageLegendDot(color: Color(0xFF8B5CF6), label: 'Deep'),
              SizedBox(width: 20),
              _StageLegendDot(color: Color(0xFF6366F1), label: 'REM'),
              SizedBox(width: 20),
              _StageLegendDot(color: Color(0xFF38BDF8), label: 'Light'),
            ],
          ),
          const SizedBox(height: 18),

          // Stepped Sleep Architecture Graph
          SizedBox(
            height: 110,
            width: double.infinity,
            child: CustomPaint(
              painter: _SleepStagesArchitectPainter(),
            ),
          ),
          const SizedBox(height: 10),

          // Bottom Stage Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Desp', style: TextStyle(fontSize: 11, color: Colors.white54)),
                Text('Deep', style: TextStyle(fontSize: 11, color: Colors.white54)),
                Text('Pom', style: TextStyle(fontSize: 11, color: Colors.white54)),
                Text('Tum', style: TextStyle(fontSize: 11, color: Colors.white54)),
                Text('Light', style: TextStyle(fontSize: 11, color: Colors.white54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Neon Circular Gauge with centered labels matching reference mockup
class _NeonCircleGauge extends StatelessWidget {
  const _NeonCircleGauge({
    required this.title,
    required this.value,
    required this.progress,
    required this.gradientColors,
    required this.glowColor,
    this.hasHeadDot = false,
  });

  final String title;
  final String value;
  final double progress;
  final List<Color> gradientColors;
  final Color glowColor;
  final bool hasHeadDot;

  @override
  Widget build(BuildContext context) {
    const size = 112.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: _NeonArcPainter(
              progress: progress,
              gradientColors: gradientColors,
              glowColor: glowColor,
              hasHeadDot: hasHeadDot,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NeonArcPainter extends CustomPainter {
  const _NeonArcPainter({
    required this.progress,
    required this.gradientColors,
    required this.glowColor,
    this.hasHeadDot = false,
  });

  final double progress;
  final List<Color> gradientColors;
  final Color glowColor;
  final bool hasHeadDot;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = 7.5;
    final radius = (size.width - strokeWidth) / 2;

    // Dark Track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    final sweepAngle = 2 * math.pi * progress.clamp(0.01, 1.0);
    const startAngle = -math.pi / 2;

    // Glowing Neon Sweep
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: gradientColors,
      transform: const GradientRotation(startAngle),
    );

    // Glow pass
    final glowPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 3.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

    // Foreground crisp stroke
    final arcPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);

    // Optional glowing dot at arc head
    if (hasHeadDot && progress > 0.05) {
      final endAngle = startAngle + sweepAngle;
      final headX = center.dx + radius * math.cos(endAngle);
      final headY = center.dy + radius * math.sin(endAngle);
      final headOffset = Offset(headX, headY);

      final dotGlow = Paint()
        ..color = glowColor.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawCircle(headOffset, 4.5, dotGlow);

      final dotWhite = Paint()..color = Colors.white;
      canvas.drawCircle(headOffset, 2.8, dotWhite);
    }
  }

  @override
  bool shouldRepaint(covariant _NeonArcPainter old) =>
      old.progress != progress || old.glowColor != glowColor;
}

class _StageLegendDot extends StatelessWidget {
  const _StageLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

/// Stepped Sleep Architecture Graph with Pink Arousal Caps and Multi-level Fills
class _SleepStagesArchitectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Stage level heights (0 = Awake/Pink, 1 = Light/Cyan, 2 = REM/Indigo, 3 = Deep/Violet)
    final yAwake = h * 0.10;
    final yLight = h * 0.40;
    final yRem = h * 0.65;
    final yDeep = h * 0.90;

    // Faint horizontal guide lines
    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, yLight), Offset(w, yLight), guidePaint);
    canvas.drawLine(Offset(0, yRem), Offset(w, yRem), guidePaint);
    canvas.drawLine(Offset(0, yDeep), Offset(w, yDeep), guidePaint);

    // Stepped wave coordinates matching ref_crops/sleep_screen_ref.png:
    // (xRatio, y)
    // 1. Spikes up to awake with pink cap at start
    // 2. Steps down to Light, then Deep, stays Deep, steps to REM, etc.
    final steps = [
      (0.08, yAwake, true),    // Awake spike 1
      (0.09, yLight, false),
      (0.18, yLight, false),
      (0.19, yDeep, false),    // Deep sleep phase 1
      (0.30, yDeep, false),
      (0.31, yRem, false),     // Transition to REM
      (0.40, yRem, false),
      (0.41, yLight, false),   // Light sleep
      (0.53, yLight, false),
      (0.535, yAwake, true),   // Micro-awakening spike 2
      (0.54, yRem, false),
      (0.65, yRem, false),
      (0.66, yLight, false),   // Light sleep phase 2
      (0.78, yLight, false),
      (0.785, yAwake, true),   // Micro-awakening spike 3
      (0.79, yRem, false),
      (0.85, yRem, false),
      (0.855, yAwake, true),   // Awake/Alarm wake cap 4
      (0.89, yAwake, false),
    ];

    // Build stroke paths for each tier with appropriate neon colors
    // Light segments (Cyan)
    final cyanPath = Path();
    cyanPath.moveTo(w * 0.09, yLight);
    cyanPath.lineTo(w * 0.18, yLight);
    cyanPath.moveTo(w * 0.41, yLight);
    cyanPath.lineTo(w * 0.53, yLight);
    cyanPath.moveTo(w * 0.66, yLight);
    cyanPath.lineTo(w * 0.78, yLight);

    final cyanStroke = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(cyanPath, cyanStroke);

    // REM segments (Indigo)
    final indigoPath = Path();
    indigoPath.moveTo(w * 0.31, yRem);
    indigoPath.lineTo(w * 0.40, yRem);
    indigoPath.moveTo(w * 0.54, yRem);
    indigoPath.lineTo(w * 0.65, yRem);
    indigoPath.moveTo(w * 0.79, yRem);
    indigoPath.lineTo(w * 0.85, yRem);

    final indigoStroke = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(indigoPath, indigoStroke);

    // Deep segments (Violet/Purple)
    final violetPath = Path();
    violetPath.moveTo(w * 0.19, yDeep);
    violetPath.lineTo(w * 0.30, yDeep);

    final violetStroke = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(violetPath, violetStroke);

    // Vertical step connectors
    final connectorPath = Path();
    // 0.08 awake down to light
    connectorPath.moveTo(w * 0.08, yAwake);
    connectorPath.lineTo(w * 0.08, yLight);
    // 0.18 light down to deep
    connectorPath.moveTo(w * 0.18, yLight);
    connectorPath.lineTo(w * 0.18, yDeep);
    // 0.30 deep up to rem
    connectorPath.moveTo(w * 0.30, yDeep);
    connectorPath.lineTo(w * 0.30, yRem);
    // 0.40 rem up to light
    connectorPath.moveTo(w * 0.40, yRem);
    connectorPath.lineTo(w * 0.40, yLight);
    // 0.53 light up to awake then down to rem
    connectorPath.moveTo(w * 0.53, yLight);
    connectorPath.lineTo(w * 0.53, yAwake);
    connectorPath.lineTo(w * 0.54, yRem);
    // 0.65 rem up to light
    connectorPath.moveTo(w * 0.65, yRem);
    connectorPath.lineTo(w * 0.65, yLight);
    // 0.78 light up to awake then rem
    connectorPath.moveTo(w * 0.78, yLight);
    connectorPath.lineTo(w * 0.78, yAwake);
    connectorPath.lineTo(w * 0.79, yRem);
    // 0.85 rem up to awake
    connectorPath.moveTo(w * 0.85, yRem);
    connectorPath.lineTo(w * 0.85, yAwake);

    final connectorStroke = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawPath(connectorPath, connectorStroke);

    // Soft gradient fill beneath deep and rem blocks
    final deepFillRect = Rect.fromLTRB(w * 0.19, yDeep, w * 0.30, h);
    final deepFill = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF8B5CF6).withValues(alpha: 0.35),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(deepFillRect);
    canvas.drawRRect(RRect.fromRectAndRadius(deepFillRect, const Radius.circular(3)), deepFill);

    final remFillRect = Rect.fromLTRB(w * 0.31, yRem, w * 0.40, h);
    final remFill = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF6366F1).withValues(alpha: 0.30),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(remFillRect);
    canvas.drawRRect(RRect.fromRectAndRadius(remFillRect, const Radius.circular(3)), remFill);

    final lightFillRect = Rect.fromLTRB(w * 0.66, yLight, w * 0.78, h);
    final lightFill = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF38BDF8).withValues(alpha: 0.22),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(lightFillRect);
    canvas.drawRRect(RRect.fromRectAndRadius(lightFillRect, const Radius.circular(3)), lightFill);

    // Pink / Magenta Awakening Transition Caps on peaks
    final pinkCapPaint = Paint()
      ..color = const Color(0xFFFB7185)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.065, yAwake), Offset(w * 0.09, yAwake), pinkCapPaint);
    canvas.drawLine(Offset(w * 0.525, yAwake), Offset(w * 0.54, yAwake), pinkCapPaint);
    canvas.drawLine(Offset(w * 0.775, yAwake), Offset(w * 0.79, yAwake), pinkCapPaint);
    canvas.drawLine(Offset(w * 0.845, yAwake), Offset(w * 0.88, yAwake), pinkCapPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Interactive Smart Alarm Card matching reference mockup
class _InteractiveSmartAlarmCard extends StatelessWidget {
  const _InteractiveSmartAlarmCard({
    required this.formattedTime,
    required this.wakeWindowMinutes,
    required this.onMinus,
    required this.onPlus,
    required this.onWindowChanged,
    required this.onSave,
  });

  final String formattedTime;
  final double wakeWindowMinutes;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<double> onWindowChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2A).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          // Header: Title with right chevron
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Interactive Smart Alarm',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              GestureDetector(
                onTap: onSave,
                child: Row(
                  children: const [
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // "Set for" label
          const Text(
            'Set for',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 6),

          // Digital Time adjustment with circular "-" and "+" buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minus circular button
              GestureDetector(
                onTap: onMinus,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.remove_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 22),

              // Time text
              Text(
                formattedTime,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 22),

              // Plus circular button
              GestureDetector(
                onTap: onPlus,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Custom Slider with emerald active track, glowing white knob, and right ticks
          _SmartWakeWindowSlider(
            value: wakeWindowMinutes,
            min: 10,
            max: 45,
            onChanged: onWindowChanged,
          ),
          const SizedBox(height: 6),

          // Subtitle: "Smart wake window"
          const Text(
            'Smart wake window',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom wake window slider with emerald bar and tick marks matching reference
class _SmartWakeWindowSlider extends StatelessWidget {
  const _SmartWakeWindowSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final ratio = ((value - min) / (max - min)).clamp(0.0, 1.0);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) {
            final localX = details.localPosition.dx.clamp(0.0, totalWidth);
            final newRatio = localX / totalWidth;
            final newValue = min + (max - min) * newRatio;
            onChanged(newValue);
          },
          onTapDown: (details) {
            final localX = details.localPosition.dx.clamp(0.0, totalWidth);
            final newRatio = localX / totalWidth;
            final newValue = min + (max - min) * newRatio;
            onChanged(newValue);
          },
          child: SizedBox(
            height: 30,
            width: totalWidth,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Inactive Track with tick marks on right side
                CustomPaint(
                  size: Size(totalWidth, 30),
                  painter: _SliderTicksPainter(thumbRatio: ratio),
                ),

                // Emerald Active Track
                Container(
                  height: 4.5,
                  width: totalWidth * ratio,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),

                // Glowing White Thumb
                Positioned(
                  left: (totalWidth * ratio - 9).clamp(0.0, totalWidth - 18),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.8),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SliderTicksPainter extends CustomPainter {
  const _SliderTicksPainter({required this.thumbRatio});

  final double thumbRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final cy = size.height / 2;

    // Inactive baseline track
    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, cy), Offset(w, cy), basePaint);

    // Draw vertical tick marks in inactive region
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1.2;

    const tickSpacing = 8.0;
    final startX = (w * thumbRatio) + 12.0;

    for (double x = startX; x < w - 6; x += tickSpacing) {
      canvas.drawLine(Offset(x, cy - 3.5), Offset(x, cy + 3.5), tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SliderTicksPainter old) =>
      old.thumbRatio != thumbRatio;
}

/// Snooze Log Analysis Card with Behavioral Prompts & Habits
class _SnoozeLogAnalysisCard extends StatelessWidget {
  const _SnoozeLogAnalysisCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2A).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Snooze Log Analysis',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),

          // Row 1: Behavioral Routine Habits
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                child: const Center(
                  child: Icon(
                    Icons.access_time_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Behavioral Routine Habits',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '04:31',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _EmeraldProgressBar(progress: 0.45),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: Behavioral Snooze Habits
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                child: const Center(
                  child: Icon(
                    Icons.bedtime_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Behavioral Snooze Habits',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    _EmeraldProgressBar(progress: 0.28),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmeraldProgressBar extends StatelessWidget {
  const _EmeraldProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        return Container(
          height: 4.5,
          width: totalWidth,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(2.5),
          ),
          alignment: Alignment.centerLeft,
          child: Container(
            height: 4.5,
            width: totalWidth * progress.clamp(0.0, 1.0),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        );
      },
    );
  }
}
