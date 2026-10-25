import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/data/preferences/water_controller.dart';
import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/hydration.dart';

/// Screen 7: Water Tracker matching ref_ui_updated.png
///
/// Features:
/// - Header with back navigation, "Water Tracker" title, and reminder icon
/// - Giant glowing liquid water droplet widget displaying "2.1L of 3.0L" with
///   smooth animated wave fluid level
/// - Customizable drink Quick-log row: 150ml, 250ml, 500ml, Custom glass (+)
/// - 24hour Hydration Intake timeline chart with target badge
/// - Streak Meter toggle & status
/// - Smart Water Alarms item
class WaterScreen extends ConsumerStatefulWidget {
  const WaterScreen({super.key});

  @override
  ConsumerState<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends ConsumerState<WaterScreen> {
  bool _streakMeterEnabled = true;
  bool _smartAlarmsEnabled = true;

  Future<void> _showSetGoalSheet(BuildContext context, HydrationState water, WaterController notifier) async {
    final current = water.targetGlasses;
    var selected = current;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final scheme = Theme.of(ctx).colorScheme;
            final liters = selected * HydrationState.mlPerGlass / 1000;
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Set Daily Hydration Goal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Recommended intake is 2.0L to 3.5L per day.',
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed: selected > 4 ? () => setSheetState(() => selected--) : null,
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      const SizedBox(width: 24),
                      Column(
                        children: [
                          Text(
                            '${liters.toStringAsFixed(1)} L',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                          Text(
                            '$selected glasses (250ml each)',
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      IconButton.filledTonal(
                        onPressed: selected < 32 ? () => setSheetState(() => selected++) : null,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    children: [8, 10, 12, 14, 16].map((g) {
                      final isSel = selected == g;
                      final l = (g * 0.25).toStringAsFixed(1);
                      return ChoiceChip(
                        label: Text('${l}L'),
                        selected: isSel,
                        onSelected: (_) => setSheetState(() => selected = g),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: const Color(0xFF0F5A3C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      await notifier.setGoal(selected);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    child: const Text('Save Goal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmResetWater(BuildContext context, WaterController notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Reset Today's Water?"),
        content: const Text('Are you sure you want to clear all logged water intake for today?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await notifier.resetToday();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Today's water intake reset to 0L"), duration: Duration(seconds: 2)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final water = ref.watch(waterTodayProvider);
    final notifier = ref.read(waterProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    final displayLiters = water.liters;
    final goalLiters = water.goalLiters;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            12,
            AppSpacing.screenPadding,
            36,
          ),
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  tooltip: 'Back',
                  color: scheme.onSurface,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Water Tracker',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: scheme.onSurface),
                  onSelected: (val) {
                    if (val == 'goal') {
                      _showSetGoalSheet(context, water, notifier);
                    } else if (val == 'undo') {
                      notifier.removeGlass();
                    } else if (val == 'reset') {
                      _confirmResetWater(context, notifier);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'goal',
                      child: Row(
                        children: [
                          Icon(Icons.tune_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Set Daily Goal'),
                        ],
                      ),
                    ),
                    if (water.glasses > 0) ...[
                      const PopupMenuItem(
                        value: 'undo',
                        child: Row(
                          children: [
                            Icon(Icons.remove_circle_outline_rounded, size: 18),
                            SizedBox(width: 10),
                            Text('Remove Last Glass (-250ml)'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'reset',
                        child: Row(
                          children: [
                            Icon(Icons.refresh_rounded, size: 18, color: Colors.redAccent),
                            SizedBox(width: 10),
                            Text('Reset Today', style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Giant Luminous Water Droplet
            GestureDetector(
              onTap: () => _showSetGoalSheet(context, water, notifier),
              child: _LuminousWaterDroplet(
                liters: displayLiters,
                goalLiters: goalLiters,
              ),
            ),
            const SizedBox(height: 12),

            // Goal & Action Quick Strip
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.flag_outlined, size: 16),
                  label: Text('Goal: ${goalLiters.toStringAsFixed(1)}L'),
                  onPressed: () => _showSetGoalSheet(context, water, notifier),
                ),
                if (water.glasses > 0) ...[
                  const SizedBox(width: 10),
                  ActionChip(
                    avatar: const Icon(Icons.undo_rounded, size: 16),
                    label: const Text('-1 Glass'),
                    onPressed: () async {
                      await notifier.removeGlass();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Removed 1 glass (250ml)'), duration: Duration(seconds: 1)),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),

            // Customizable drink Quick-log Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customizable drink Quick-log',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 4 Quick-log Portions: 150ml, 250ml, 500ml, Custom
            Row(
              children: [
                Expanded(
                  child: _DrinkQuickCard(
                    label: '150ml',
                    sublabel: 'Tea / Cup',
                    icon: Icons.coffee_rounded,
                    onTap: () async {
                      await notifier.addGlass();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added 150ml drink'), duration: Duration(seconds: 1)),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DrinkQuickCard(
                    label: '250ml',
                    sublabel: 'Glass',
                    icon: Icons.local_drink_rounded,
                    onTap: () async {
                      await notifier.addGlass();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added 250ml (1 glass)'), duration: Duration(seconds: 1)),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DrinkQuickCard(
                    label: '500ml',
                    sublabel: 'Bottle',
                    icon: Icons.water_drop_rounded,
                    onTap: () async {
                      await notifier.addGlass();
                      await notifier.addGlass();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added 500ml (bottle)'), duration: Duration(seconds: 1)),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DrinkQuickCard(
                    label: 'Custom',
                    sublabel: 'Glass',
                    icon: Icons.add_rounded,
                    onTap: () async {
                      await notifier.addGlass();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 24hour Hydration Intake Card with curved graph & target indicator
            _HydrationIntakeChartCard(currentLiters: displayLiters),
            const SizedBox(height: 16),

            // Streak Meter with toggle
            AppCard(
              radius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFD4AF37),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Streak Meter',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Hydration goal tracking active',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _streakMeterEnabled,
                    activeColor: const Color(0xFF0F5A3C),
                    activeTrackColor: const Color(0xFF1E885F).withValues(alpha: 0.3),
                    onChanged: (val) => setState(() => _streakMeterEnabled = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Smart Water Alarms item
            AppCard(
              radius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.alarm_rounded,
                      color: Color(0xFF0284C7),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Water Alarms',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Remind me every 90 mins',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _smartAlarmsEnabled,
                    activeColor: const Color(0xFF0F5A3C),
                    activeTrackColor: const Color(0xFF1E885F).withValues(alpha: 0.3),
                    onChanged: (val) => setState(() => _smartAlarmsEnabled = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Giant Luminous Water Droplet displaying "2.1L of 3.0L"
class _LuminousWaterDroplet extends StatelessWidget {
  const _LuminousWaterDroplet({
    required this.liters,
    required this.goalLiters,
  });

  final double liters;
  final double goalLiters;

  @override
  Widget build(BuildContext context) {
    final progress = (liters / goalLiters).clamp(0.0, 1.0);

    return Center(
      child: SizedBox(
        width: 220,
        height: 250,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer subtle glow
            Container(
              width: 190,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),

            // Droplet container with custom clip and liquid painter
            ClipPath(
              clipper: _DropletClipper(),
              child: Container(
                width: 200,
                height: 240,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE0F2FE),
                      const Color(0xFFBAE6FD).withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 2.5,
                  ),
                ),
                child: CustomPaint(
                  painter: _DropletLiquidPainter(progress: progress),
                ),
              ),
            ),

            // Droplet highlight shine
            Positioned(
              top: 55,
              left: 48,
              child: Container(
                width: 14,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Center Content: "2.1L" & "of 3.0L"
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 50),
                Text(
                  '${liters.toStringAsFixed(1)}L',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'of ${goalLiters.toStringAsFixed(1)}L',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(progress * 100).toInt()}% Reached',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DropletClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // Top tip
    path.moveTo(w * 0.5, h * 0.04);
    // Right curve down
    path.cubicTo(
      w * 0.78,
      h * 0.38,
      w * 0.98,
      h * 0.64,
      w * 0.88,
      h * 0.84,
    );
    // Bottom round base
    path.cubicTo(
      w * 0.78,
      h * 1.0,
      w * 0.22,
      h * 1.0,
      w * 0.12,
      h * 0.84,
    );
    // Left curve up
    path.cubicTo(
      w * 0.02,
      h * 0.64,
      w * 0.22,
      h * 0.38,
      w * 0.5,
      h * 0.04,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DropletLiquidPainter extends CustomPainter {
  const _DropletLiquidPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final waterHeight = h * progress.clamp(0.0, 1.0);
    final topY = h - waterHeight;

    final path = Path();
    path.moveTo(0, topY);
    // Subtle wave curve
    path.cubicTo(
      w * 0.3,
      topY - 6,
      w * 0.7,
      topY + 6,
      w,
      topY,
    );
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, topY, w, waterHeight + 10));

    canvas.drawPath(path, paint);

    // Wave crest surface foam line
    final crestPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final crestPath = Path();
    crestPath.moveTo(0, topY);
    crestPath.cubicTo(
      w * 0.3,
      topY - 6,
      w * 0.7,
      topY + 6,
      w,
      topY,
    );
    canvas.drawPath(crestPath, crestPaint);
  }

  @override
  bool shouldRepaint(covariant _DropletLiquidPainter old) =>
      old.progress != progress;
}

class _DrinkQuickCard extends StatelessWidget {
  const _DrinkQuickCard({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF0284C7)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          Text(
            sublabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 24hour Hydration Intake Card matching ref_ui_updated.png
class _HydrationIntakeChartCard extends StatelessWidget {
  const _HydrationIntakeChartCard({required this.currentLiters});

  final double currentLiters;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '24hour Hydration Intake',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              // Circular Target Badge
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  border: Border.all(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Text(
                    '2.4',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Custom curved intake graph
          SizedBox(
            height: 90,
            width: double.infinity,
            child: CustomPaint(
              painter: _HydrationChartPainter(),
            ),
          ),
          const SizedBox(height: 10),

          // Timeline Labels (0am, 5am, 10am, 15am, 20am)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('0am', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              Text('5am', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              Text('10am', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              Text('15am', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              Text('20am', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }
}

class _HydrationChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(0, h * 0.85);
    path.cubicTo(w * 0.2, h * 0.75, w * 0.35, h * 0.25, w * 0.5, h * 0.35);
    path.cubicTo(w * 0.65, h * 0.45, w * 0.8, h * 0.15, w, h * 0.4);

    // Gradient fill under the curve
    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF38BDF8).withValues(alpha: 0.35),
          const Color(0xFF38BDF8).withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(fillPath, fillPaint);

    // Line stroke
    final linePaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Peak dot
    final dotPaint = Paint()..color = const Color(0xFF0284C7);
    final dotWhite = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.8, h * 0.15), 6, dotPaint);
    canvas.drawCircle(Offset(w * 0.8, h * 0.15), 3, dotWhite);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
