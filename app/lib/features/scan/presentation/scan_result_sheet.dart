import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/app/log_store.dart';
import 'package:app/design_system/components/app_toast.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/domain/entities/log_entry.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/features/scan/application/scan_state.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/extensions.dart';

/// Result sheet matching:
/// - Health AI Wellness App Showcase (1).png Screen 3
/// - Health AI Nutrition App UI Showcase (2).png Screen 3
class ScanResultSheet extends ConsumerStatefulWidget {
  const ScanResultSheet({
    required this.mealKind,
    this.dayOffset = 0,
    super.key,
  });

  final MealKind mealKind;
  final int dayOffset;

  @override
  ConsumerState<ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends ConsumerState<ScanResultSheet> {
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(scanSessionProvider);
    if (session == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final serving = session.chosenServing;
    final chosen = session.chosenPrediction;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top Header: < Scan Result ❤️
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Scan Result',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.favorite_border_rounded, color: colors.primary),
                  ),
                ],
              ),
            ),

            // Subtitle Pills: ✨ AI Identified | 98% Confidence
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: scheme.onPrimary, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          'AI Identified',
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: colors.washOf(colors.primary),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${chosen.percent}% Confidence',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Food Info Card (Dish photo, Name, Serving description)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
                  boxShadow: colors.shadow(blur: 10, y: 3, alpha: 0.05),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: session.photo.isNotEmpty
                          ? Image.memory(
                              session.photo,
                              width: 68,
                              height: 68,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 68,
                              height: 68,
                              color: colors.washOf(colors.primary),
                              child: Icon(Icons.restaurant, color: colors.primary),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chosen.dish.name,
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '~ ${serving.label} (${serving.grams}g)',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.washOf(colors.primary),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Healthy Choice',
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (session.topMatches.length > 1) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alternative Dishes (tap to switch):',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var i = 0; i < session.topMatches.length; i++) ...[
                            ChoiceChip(
                              label: Text('${session.topMatches[i].dish.name} (${session.topMatches[i].percent}%)'),
                              selected: i == session.selectedMatch,
                              onSelected: (_) {
                                ref.read(scanSessionProvider.notifier).update((s) => s?.selectMatch(i));
                              },
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Nutrition Facts Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Nutrition Facts',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 4 Circular Colored Metric Rings matching Showcase 1 & 2 Screen 3
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _MacroRingWidget(
                      value: '${serving.midKcal}',
                      unit: 'kcal',
                      label: 'Calories',
                      color: colors.primary,
                      progress: (serving.midKcal / 700).clamp(0.1, 1.0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MacroRingWidget(
                      value: '${serving.proteinGrams}',
                      unit: 'g',
                      label: 'Protein',
                      color: colors.macroProtein,
                      progress: (serving.proteinGrams / 50).clamp(0.1, 1.0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MacroRingWidget(
                      value: '${serving.carbsGrams}',
                      unit: 'g',
                      label: 'Carbs',
                      color: colors.macroCarbs,
                      progress: (serving.carbsGrams / 80).clamp(0.1, 1.0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MacroRingWidget(
                      value: '${serving.fatGrams}',
                      unit: 'g',
                      label: 'Fat',
                      color: colors.warning,
                      progress: (serving.fatGrams / 35).clamp(0.1, 1.0),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Serving Size Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Serving Size',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var i = 0; i < session.servings.length && i < 3; i++) ...[
                        Expanded(
                          child: _ServingCard(
                            label: session.servings[i].label,
                            icon: i == 0
                                ? Icons.rice_bowl_outlined
                                : i == 1
                                    ? Icons.soup_kitchen_outlined
                                    : Icons.dinner_dining_outlined,
                            selected: i == session.selectedServing,
                            onTap: () => ref
                                .read(scanSessionProvider.notifier)
                                .state = session.selectServing(i),
                          ),
                        ),
                        if (i < session.servings.length - 1 && i < 2)
                          const SizedBox(width: 10),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Approximate Calories Pill
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Approx. Calories',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.washOf(colors.primary),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${serving.lowKcal} – ${serving.highKcal} kcal',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Big Emerald CTA button: "Add to My Meal Plan"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  gradient: colors.emeraldGradient,
                  borderRadius: BorderRadius.circular(18),
                  // A brand-coloured bloom, not a black shadow: `primary`
                  // is already the dark-mode bright green, so this reads
                  // in both themes.
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: _isAdding ? 0.5 : 0.3),
                      blurRadius: _isAdding ? 22 : 16,
                      spreadRadius: _isAdding ? 2 : 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: _isAdding ? null : () => _confirm(context, session),
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _isAdding
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: scheme.onPrimary,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Adding to Meal Plan...',
                                      style: TextStyle(
                                        color: scheme.onPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: scheme.onPrimary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Add to My Meal Plan',
                                      style: TextStyle(
                                        color: scheme.onPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    ScanSession session,
  ) async {
    if (_isAdding) return;
    setState(() => _isAdding = true);

    final l10n = AppLocalizations.of(context)!;
    final serving = session.chosenServing;
    final store = ref.read(dayLogProvider.notifier);

    await store.addAndSave(
      LogEntry(
        mealKind: widget.mealKind,
        dish: session.chosenPrediction.dish.name,
        kcal: serving.midKcal,
        proteinGrams: serving.proteinGrams,
        carbsGrams: serving.carbsGrams,
        fatGrams: serving.fatGrams,
        timeLabel: _timeLabel(DateTime.now()),
      ),
      dayOffset: widget.dayOffset,
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    ref.read(scanSessionProvider.notifier).state = null;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(true);
    AppToast.show(
      messenger,
      message: l10n.addedToast(l10n.mealLabel(widget.mealKind)),
    );
  }

  static String _timeLabel(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

/// Circular colored macro ring widget matching Showcase 1 & 2 Screen 3
class _MacroRingWidget extends StatelessWidget {
  const _MacroRingWidget({
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
    required this.progress,
  });

  final String value;
  final String unit;
  final String label;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServingCard extends StatelessWidget {
  const _ServingCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return Material(
      color: selected ? colors.washOf(colors.primary) : scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? colors.primary : scheme.outlineVariant,
              width: selected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? colors.primary : scheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? colors.primary : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
