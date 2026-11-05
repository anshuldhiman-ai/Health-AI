import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/format/count_format.dart';
import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/nutrition_targets.dart';
import 'package:app/data/preferences/goal_kind_controller.dart';

/// Goal card entry point. Choosing a plan updates the calorie ring,
/// macro meters, diary and insights immediately.
Future<void> showGoalSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const GoalSettingsScreen(isModal: true),
  );
}

class GoalSheet extends StatelessWidget {
  const GoalSheet({super.key});

  @override
  Widget build(BuildContext context) => const GoalSettingsScreen(isModal: true);
}

/// Target Goals / Goal Settings screen from ui_design2.jpg Screen 6 & ui_design.jpg Screen 8
class GoalSettingsScreen extends ConsumerStatefulWidget {
  const GoalSettingsScreen({super.key, this.isModal = false});

  final bool isModal;

  @override
  ConsumerState<GoalSettingsScreen> createState() => _GoalSettingsScreenState();
}

class _GoalSettingsScreenState extends ConsumerState<GoalSettingsScreen> {
  bool _caloriesOn = true;
  bool _proteinOn = true;
  bool _carbsOn = true;
  bool _fatOn = false;

  bool _targetWeightOn = true;
  bool _dailyActiveCalOn = true;
  bool _proteinTargetOn = true;
  bool _waterIntakeOn = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final selectedKind = ref.watch(goalKindProvider);
    final targets = targetsForGoal(selectedKind);

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.x2,
        AppSpacing.screenPadding,
        32,
      ),
      children: [
        _Header(isModal: widget.isModal),
        const SizedBox(height: 16),
        // Archery Target Hero Graphic
        Center(
          child: SizedBox(
            width: 130,
            height: 130,
            child: CustomPaint(
              // Colours are injected rather than painted from literals:
              // the graphic has to re-tone when the theme flips.
              painter: _ArcheryTargetPainter(
                outerFill: colors.washOf(colors.primary),
                midFill: colors.washOf(colors.primary, strength: 2),
                coreFill: colors.primary,
                stroke: colors.primary,
                bullseye: colors.gold,
                arrow: colors.ink,
                fletching: colors.success,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Goal Category Section
        Text(
          'Goal category',
          style: AppTypography.titleM.copyWith(
            color: scheme.onSurface,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        _GoalToggleTile(
          icon: Icons.local_fire_department_outlined,
          iconColor: colors.gold,
          title: 'Calories',
          subtitle: 'Elegant subtle accents',
          value: _caloriesOn,
          onChanged: (v) => setState(() => _caloriesOn = v),
          trailingValue: '${formatCount(targets.kcal)} kcal',
        ),
        const SizedBox(height: 10),
        _GoalToggleTile(
          icon: Icons.fitness_center_rounded,
          iconColor: colors.macroProtein,
          title: 'Protein',
          subtitle: 'Elegant subtle accents',
          value: _proteinOn,
          onChanged: (v) => setState(() => _proteinOn = v),
          trailingValue: '${targets.protein}g',
        ),
        const SizedBox(height: 10),
        _GoalToggleTile(
          icon: Icons.bakery_dining_outlined,
          iconColor: colors.macroCarbs,
          title: 'Carbs',
          subtitle: 'Elegant subtle accents',
          value: _carbsOn,
          onChanged: (v) => setState(() => _carbsOn = v),
          trailingValue: '${targets.carbs}g',
        ),
        const SizedBox(height: 10),
        _GoalToggleTile(
          icon: Icons.water_drop_outlined,
          iconColor: colors.macroFat,
          title: 'Fat',
          subtitle: 'Elegant subtle accents',
          value: _fatOn,
          onChanged: (v) => setState(() => _fatOn = v),
          trailingValue: '${targets.fat}g',
        ),
        const SizedBox(height: 22),
        // Plan Preset Selector
        Text(
          'Active Plan',
          style: AppTypography.titleM.copyWith(
            color: scheme.onSurface,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final kind in GoalKind.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: kind == selectedKind
                        ? colors.primary
                        : scheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () =>
                          ref.read(goalKindProvider.notifier).select(kind),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: kind == selectedKind
                                ? colors.primary
                                : scheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              switch (kind) {
                                GoalKind.lose => 'Weight Loss',
                                GoalKind.maintain => 'Maintain',
                                GoalKind.gain => 'Muscle Gain',
                              },
                              style: TextStyle(
                                color: kind == selectedKind
                                    ? scheme.onPrimary
                                    : scheme.onSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${formatCount(targetsForGoal(kind).kcal)} kcal',
                              style: TextStyle(
                                color: kind == selectedKind
                                    ? scheme.onPrimary.withValues(alpha: 0.7)
                                    : scheme.onSurfaceVariant,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),
        // Customization Section from ui_design.jpg Screen 8
        Text(
          'Customization',
          style: AppTypography.titleM.copyWith(
            color: scheme.onSurface,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        _GoalToggleTile(
          icon: Icons.monitor_weight_outlined,
          iconColor: scheme.primary,
          title: 'Target Weight',
          subtitle: 'Track toward desired weight goal',
          value: _targetWeightOn,
          onChanged: (v) => setState(() => _targetWeightOn = v),
        ),
        const SizedBox(height: 10),
        _GoalToggleTile(
          icon: Icons.directions_run_rounded,
          iconColor: colors.accent,
          title: 'Daily Active Calories',
          subtitle: 'Active energy burn objective',
          value: _dailyActiveCalOn,
          onChanged: (v) => setState(() => _dailyActiveCalOn = v),
        ),
        const SizedBox(height: 10),
        _GoalToggleTile(
          icon: Icons.egg_alt_outlined,
          iconColor: colors.macroProtein,
          title: 'Protein Target',
          subtitle: 'Sufficient daily intake',
          value: _proteinTargetOn,
          onChanged: (v) => setState(() => _proteinTargetOn = v),
        ),
        const SizedBox(height: 10),
        _GoalToggleTile(
          icon: Icons.water_drop_rounded,
          iconColor: colors.water,
          title: 'Water intake',
          subtitle: 'Stay hydrated consistently',
          value: _waterIntakeOn,
          onChanged: (v) => setState(() => _waterIntakeOn = v),
        ),
        const SizedBox(height: 24),
        // Bottom Emerald Button "Motivational Icons" / "Confirm Target Goals"
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: colors.emeraldGradient,
            borderRadius: BorderRadius.circular(16),
            // Drops out in dark mode, where a dark shadow would be invisible.
            boxShadow: colors.shadow(alpha: 0.3, blur: 10),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).maybePop();
              },
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Text(
                  'Motivational Icons',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.isModal) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: content,
      );
    }

    return Scaffold(body: SafeArea(child: content));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isModal});

  final bool isModal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(
            isModal ? Icons.close_rounded : Icons.arrow_back_rounded,
            color: scheme.onSurface,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        const SizedBox(width: 4),
        Text(
          'Target Goals',
          style: AppTypography.titleL.copyWith(
            color: scheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.settings_outlined, color: scheme.onSurface),
        ),
      ],
    );
  }
}

class _GoalToggleTile extends StatelessWidget {
  const _GoalToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.trailingValue,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? trailingValue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            // washOf, not a flat alpha: the tint is stronger in dark mode,
            // where a 12% overlay all but disappears on the card.
            decoration: BoxDecoration(
              color: colors.washOf(iconColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppTypography.itemTitle.copyWith(
                        color: scheme.onSurface,
                        fontSize: 14.5,
                      ),
                    ),
                    if (trailingValue != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '($trailingValue)',
                        style: AppTypography.caption.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            // activeThumbColor is the non-deprecated spelling of the old
            // activeColor on Android (the track derives from the thumb).
            activeThumbColor: scheme.primary,
            onChanged: onChanged,
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: scheme.onSurfaceVariant,
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Custom Painter for the Archery Target from ui_design2.jpg Screen 6.
///
/// Takes its colours from the caller so the rings, bullseye and arrow
/// follow the active theme instead of assuming a light background.
class _ArcheryTargetPainter extends CustomPainter {
  const _ArcheryTargetPainter({
    required this.outerFill,
    required this.midFill,
    required this.coreFill,
    required this.stroke,
    required this.bullseye,
    required this.arrow,
    required this.fletching,
  });

  final Color outerFill;
  final Color midFill;
  final Color coreFill;
  final Color stroke;
  final Color bullseye;
  final Color arrow;
  final Color fletching;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    // Rings
    final paint1 = Paint()
      ..color = outerFill
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxR, paint1);

    final stroke1 = Paint()
      ..color = stroke.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, maxR, stroke1);

    final paint2 = Paint()
      ..color = midFill
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxR * 0.75, paint2);

    final stroke2 = Paint()
      ..color = stroke.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, maxR * 0.75, stroke2);

    final paint3 = Paint()
      ..color = coreFill
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxR * 0.5, paint3);

    // Bullseye
    final bullseyePaint = Paint()
      ..color = bullseye
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxR * 0.22, bullseyePaint);

    // Arrow hitting bullseye from top-right
    final arrowPaint = Paint()
      ..color = arrow
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final start = Offset(center.dx + maxR * 0.85, center.dy - maxR * 0.85);
    final end = Offset(center.dx + 2, center.dy - 2);
    canvas.drawLine(start, end, arrowPaint);

    // Arrow fletching
    final fletchPaint = Paint()
      ..color = fletching
      ..style = PaintingStyle.fill;
    final fletchPath = Path();
    fletchPath.moveTo(start.dx, start.dy);
    fletchPath.lineTo(start.dx + 12, start.dy - 6);
    fletchPath.lineTo(start.dx + 6, start.dy + 12);
    fletchPath.close();
    canvas.drawPath(fletchPath, fletchPaint);
  }

  @override
  bool shouldRepaint(covariant _ArcheryTargetPainter oldDelegate) =>
      oldDelegate.outerFill != outerFill ||
      oldDelegate.midFill != midFill ||
      oldDelegate.coreFill != coreFill ||
      oldDelegate.stroke != stroke ||
      oldDelegate.bullseye != bullseye ||
      oldDelegate.arrow != arrow ||
      oldDelegate.fletching != fletching;
}
