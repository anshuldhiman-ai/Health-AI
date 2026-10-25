import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/app/log_store.dart';
import 'package:app/data/preferences/goal_kind_controller.dart';
import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/log_entry.dart';
import 'package:app/domain/entities/macro.dart';
import 'package:app/domain/entities/meal.dart';

/// Screen showing exact macro contributions per dish eaten today.
/// Has 3 options on top (Protein, Carbs, Fats) to easily switch between them.
class MacroBreakdownScreen extends ConsumerStatefulWidget {
  const MacroBreakdownScreen({super.key, this.initialKind = MacroKind.protein});

  final MacroKind initialKind;

  @override
  ConsumerState<MacroBreakdownScreen> createState() =>
      _MacroBreakdownScreenState();
}

class _MacroBreakdownScreenState extends ConsumerState<MacroBreakdownScreen> {
  late MacroKind _selectedKind;

  @override
  void initState() {
    super.initState();
    _selectedKind = widget.initialKind;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final log = ref.watch(dayLogProvider);
    final entries = log[0] ?? const <LogEntry>[];
    final targets = ref.watch(nutritionTargetsProvider);

    final (targetGrams, macroColor, macroName, unit) = switch (_selectedKind) {
      MacroKind.protein => (
        targets.protein,
        colors.macroProtein,
        'Protein',
        'g',
      ),
      MacroKind.carbs => (
        targets.carbs,
        colors.macroCarbs,
        'Carbohydrates',
        'g',
      ),
      MacroKind.fat => (targets.fat, colors.macroFat, 'Fats', 'g'),
    };

    // Calculate total consumed for selected macro
    final totalConsumed = entries.fold<int>(0, (sum, e) {
      return sum +
          switch (_selectedKind) {
            MacroKind.protein => e.proteinGrams,
            MacroKind.carbs => e.carbsGrams,
            MacroKind.fat => e.fatGrams,
          };
    });

    final percentOfTarget = targetGrams > 0
        ? ((totalConsumed / targetGrams) * 100).round()
        : 0;

    // Filter and sort entries by contribution descending
    final contributingEntries = entries.map((e) {
      final grams = switch (_selectedKind) {
        MacroKind.protein => e.proteinGrams,
        MacroKind.carbs => e.carbsGrams,
        MacroKind.fat => e.fatGrams,
      };
      return (entry: e, grams: grams);
    }).toList()..sort((a, b) => b.grams.compareTo(a.grams));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Macronutrients',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            // 3 Switchable Options on Top: [Protein] [Carbs] [Fats]
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _MacroTabButton(
                    label: 'Protein',
                    selected: _selectedKind == MacroKind.protein,
                    color: colors.macroProtein,
                    onTap: () =>
                        setState(() => _selectedKind = MacroKind.protein),
                  ),
                  _MacroTabButton(
                    label: 'Carbs',
                    selected: _selectedKind == MacroKind.carbs,
                    color: colors.macroCarbs,
                    onTap: () =>
                        setState(() => _selectedKind = MacroKind.carbs),
                  ),
                  _MacroTabButton(
                    label: 'Fats',
                    selected: _selectedKind == MacroKind.fat,
                    color: colors.macroFat,
                    onTap: () => setState(() => _selectedKind = MacroKind.fat),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Hero Metric Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total $macroName',
                        style: AppTypography.itemTitle.copyWith(
                          fontSize: 16,
                          color: scheme.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.washOf(macroColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$percentOfTarget% of daily goal',
                          style: TextStyle(
                            color: macroColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$totalConsumed',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: macroColor,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'g',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: macroColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '/ $targetGrams g target',
                        style: AppTypography.caption.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: targetGrams > 0
                          ? (totalConsumed / targetGrams).clamp(0.0, 1.0)
                          : 0,
                      minHeight: 8,
                      backgroundColor: scheme.outlineVariant.withValues(
                        alpha: 0.4,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(macroColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Dishes breakdown section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dishes Eaten Today',
                  style: AppTypography.titleM.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${contributingEntries.length} items',
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (contributingEntries.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 36,
                ),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colors.washOf(macroColor),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: macroColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No $macroName logged today',
                      style: AppTypography.itemTitle.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Scan a meal photo or search dishes from the diary '
                      'to see your breakdown.',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.push('/scan'),
                          icon: const Icon(Icons.camera_alt_rounded, size: 18),
                          label: const Text('Scan Meal'),
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/search'),
                          icon: const Icon(Icons.search_rounded, size: 18),
                          label: const Text('Search Food'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              ...contributingEntries.map((item) {
                final e = item.entry;
                final grams = item.grams;
                final share = totalConsumed > 0
                    ? ((grams / totalConsumed) * 100).round()
                    : 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colors.washOf(macroColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              _mealIcon(e.mealKind),
                              color: macroColor,
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
                                e.dish,
                                style: AppTypography.itemTitle.copyWith(
                                  color: scheme.onSurface,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Text(
                                    _mealName(e.mealKind),
                                    style: AppTypography.caption.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${e.kcal} kcal',
                                    style: AppTypography.caption.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  if (e.timeLabel != null &&
                                      e.timeLabel!.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '•',
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      e.timeLabel!,
                                      style: AppTypography.caption.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+$grams $unit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: macroColor,
                              ),
                            ),
                            Text(
                              '$share% of today',
                              style: AppTypography.caption.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  static IconData _mealIcon(MealKind kind) => switch (kind) {
    MealKind.breakfast => Icons.wb_sunny_outlined,
    MealKind.lunch => Icons.lunch_dining_outlined,
    MealKind.dinner => Icons.nightlight_outlined,
    MealKind.snacks => Icons.cookie_outlined,
  };

  static String _mealName(MealKind kind) => switch (kind) {
    MealKind.breakfast => 'Breakfast',
    MealKind.lunch => 'Lunch',
    MealKind.dinner => 'Dinner',
    MealKind.snacks => 'Snacks',
  };
}

class _MacroTabButton extends StatelessWidget {
  const _MacroTabButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? scheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? context.appColors.shadow(blur: 4, y: 2, alpha: 0.06)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
