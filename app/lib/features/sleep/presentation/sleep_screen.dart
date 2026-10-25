import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/data/preferences/sleep_controller.dart';
import 'package:app/design_system/components/app_toast.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/sleep_record.dart';

/// Screen 9: Sleep Tracker & Smart Alarm matching ref_ui_updated.png
///
/// Features:
/// - Standout dark midnight blue / dark purple gradient theme
/// - Dual circular metric cards: Sleep Quality (92%) & Sleep Duration (7h 20m)
/// - Interactive sleep stages stepped bar/wave graph: Deep, REM, Light
/// - Interactive Smart Alarm: "Set for 06:45 AM" with +/- increment buttons
///   and Smart wake window slider
/// - Snooze Log Analysis: Behavioral Training Prompts & Behavioral Snooze Habits
class SleepScreen extends ConsumerStatefulWidget {
  const SleepScreen({super.key});

  @override
  ConsumerState<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends ConsumerState<SleepScreen> {
  // Time picker state for bedtime & alarm
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
                      backgroundColor: const Color(0xFF1E885F),
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
    final durationMinutes = hasRealRecord ? sleepRecord.durationMinutes : 0;
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    final goalMinutes = sleepState.targetMinutes;
    final qualityScore = hasRealRecord
        ? ((durationMinutes / goalMinutes) * 100).round().clamp(10, 100)
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF070B14),
              Color(0xFF0F172A),
              Color(0xFF090D1A),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              12,
              AppSpacing.screenPadding,
              40,
            ),
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    tooltip: 'Back',
                    color: Colors.white,
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Sleep Tracker & Smart Alarm',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
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
              const SizedBox(height: 12),

              // Goal Quick Chip
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ActionChip(
                    backgroundColor: Colors.white12,
                    avatar: const Icon(Icons.flag_outlined, size: 16, color: Color(0xFF38BDF8)),
                    label: Text(
                      'Goal: ${(goalMinutes / 60).toStringAsFixed(1)}h',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => _showSetSleepGoalSheet(context),
                  ),
                  if (hasRealRecord) ...[
                    const SizedBox(width: 10),
                    ActionChip(
                      backgroundColor: Colors.red.withValues(alpha: 0.15),
                      avatar: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                      label: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
                      onPressed: () => _confirmDeleteSleep(context),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // Dual Cards: Sleep Quality & Sleep Duration
              _DualQualityCards(
                qualityPercent: qualityScore,
                durationText: hasRealRecord ? '${hours}h ${minutes}m' : 'No log',
              ),
              const SizedBox(height: 22),

              // Sleep Stages Legend & Graph
              _SleepStagesGraphCard(),
              const SizedBox(height: 20),

              // Interactive Smart Alarm Card
              _SmartAlarmCard(
                formattedTime: _formattedAlarmTime(),
                wakeWindowMinutes: _wakeWindowMinutes,
                onMinus: () => _adjustAlarm(-15),
                onPlus: () => _adjustAlarm(15),
                onWindowChanged: (val) => setState(() => _wakeWindowMinutes = val),
                onSave: _saveAlarm,
              ),
              const SizedBox(height: 20),

              // Snooze Log Analysis
              const _SnoozeLogAnalysisSection(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dual Quality & Duration Cards: "Sleep Quality 92%" & "Sleep 7h 20m"
class _DualQualityCards extends StatelessWidget {
  const _DualQualityCards({
    required this.qualityPercent,
    required this.durationText,
  });

  final int qualityPercent;
  final String durationText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Left: Sleep Quality Gauge
          Row(
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(60, 60),
                      painter: _NeonRingPainter(
                        progress: qualityPercent / 100,
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                    Text(
                      qualityPercent > 0 ? '$qualityPercent%' : '--',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sleep Quality',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    qualityPercent >= 80
                        ? 'Optimal'
                        : (qualityPercent > 0 ? 'Good' : 'Not logged'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: qualityPercent > 0 ? const Color(0xFF38BDF8) : Colors.white54,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Center separator
          const Text(
            '&',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w300,
              color: Colors.white38,
            ),
          ),

          // Right: Sleep Duration
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.nightlight_round,
                  color: Color(0xFF818CF8),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sleep',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    durationText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NeonRingPainter extends CustomPainter {
  const _NeonRingPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 6) / 2;

    // Track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;
    canvas.drawCircle(center, radius, trackPaint);

    // Glow progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _NeonRingPainter old) =>
      old.progress != progress || old.color != color;
}

/// Sleep Stages Graph matching ref_ui_updated.png
class _SleepStagesGraphCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend row: Deep (cyan), REM (blue), Light (purple)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StageLegend(color: const Color(0xFF38BDF8), label: 'Deep'),
              const SizedBox(width: 18),
              _StageLegend(color: const Color(0xFF6366F1), label: 'REM'),
              const SizedBox(width: 18),
              _StageLegend(color: const Color(0xFFC084FC), label: 'Light'),
            ],
          ),
          const SizedBox(height: 18),

          // Stepped wave block graph
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: _SleepStagesPainter(),
            ),
          ),
          const SizedBox(height: 12),

          // Stage labels along bottom
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Deep', style: TextStyle(fontSize: 10.5, color: Colors.white60)),
              Text('Deep', style: TextStyle(fontSize: 10.5, color: Colors.white60)),
              Text('Pom', style: TextStyle(fontSize: 10.5, color: Colors.white60)),
              Text('Turn', style: TextStyle(fontSize: 10.5, color: Colors.white60)),
              Text('Light', style: TextStyle(fontSize: 10.5, color: Colors.white60)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageLegend extends StatelessWidget {
  const _StageLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
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

class _SleepStagesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid baseline
    final baselinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, h * 0.25), Offset(w, h * 0.25), baselinePaint);
    canvas.drawLine(Offset(0, h * 0.50), Offset(w, h * 0.50), baselinePaint);
    canvas.drawLine(Offset(0, h * 0.75), Offset(w, h * 0.75), baselinePaint);

    // Stepped line path showing sleep stage cycles
    final path = Path();
    path.moveTo(0, h * 0.75); // Start Light/Deep
    path.lineTo(w * 0.12, h * 0.75);
    path.lineTo(w * 0.12, h * 0.90); // Deep
    path.lineTo(w * 0.28, h * 0.90);
    path.lineTo(w * 0.28, h * 0.50); // REM
    path.lineTo(w * 0.44, h * 0.50);
    path.lineTo(w * 0.44, h * 0.75); // Light
    path.lineTo(w * 0.60, h * 0.75);
    path.lineTo(w * 0.60, h * 0.90); // Deep cycle 2
    path.lineTo(w * 0.76, h * 0.90);
    path.lineTo(w * 0.76, h * 0.35); // REM cycle 2
    path.lineTo(w * 0.88, h * 0.35);
    path.lineTo(w * 0.88, h * 0.15); // Wake up
    path.lineTo(w, h * 0.15);

    // Glowing cyan/indigo stroke
    final strokePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // Semi-transparent fill under the steps
    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF38BDF8).withValues(alpha: 0.25),
          const Color(0xFF6366F1).withValues(alpha: 0.02),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Interactive Smart Alarm Card matching ref_ui_updated.png
class _SmartAlarmCard extends StatelessWidget {
  const _SmartAlarmCard({
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Interactive Smart Alarm',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: onSave,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E885F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Set for',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 12),

          // Digital Time Display with +/- buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minus button
              IconButton(
                onPressed: onMinus,
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 30),
                color: Colors.white70,
              ),
              const SizedBox(width: 16),
              Text(
                formattedTime,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              // Plus button
              IconButton(
                onPressed: onPlus,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 30),
                color: Colors.white70,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Smart wake window slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Smart wake window',
                style: TextStyle(fontSize: 11.5, color: Colors.white60),
              ),
              Text(
                '±${wakeWindowMinutes.toInt()} mins',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF38BDF8),
                ),
              ),
            ],
          ),
          Slider(
            value: wakeWindowMinutes,
            min: 10,
            max: 45,
            divisions: 7,
            activeColor: const Color(0xFF38BDF8),
            inactiveColor: Colors.white12,
            onChanged: onWindowChanged,
          ),
        ],
      ),
    );
  }
}

/// Snooze Log Analysis Section matching ref_ui_updated.png
class _SnoozeLogAnalysisSection extends StatelessWidget {
  const _SnoozeLogAnalysisSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Snooze Log Analysis',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        // Behavioral Training Prompts
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131B2E).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Color(0xFF818CF8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Behavioral Training Prompts',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Wake consistency improves REM efficiency by 18%',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Behavioral Snooze Habits
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131B2E).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.snooze_rounded,
                  color: Color(0xFFD4AF37),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Behavioral Snooze Habits',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '0 snoozes logged this week • Perfect Streak',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
