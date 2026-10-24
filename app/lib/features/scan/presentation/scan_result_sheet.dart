import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/app/log_store.dart';
import 'package:app/design_system/components/app_toast.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/log_entry.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/features/scan/application/scan_state.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/extensions.dart';

/// Result sheet matching ui_design.jpg & ui_design2.jpg:
/// - Header: "Scan Result" with High Confidence / High-accurate labels badges
/// - Main Prediction Card with dish photo, name & confidence
/// - Serving Size selector (Katori, Bowl, Plate in gold active state) + Stepper
/// - Approximate Calories pill
/// - Nutritionist insights card
/// - Substitute suggestions card
/// - Large Emerald button "Confirm & Add to Diary"
class ScanResultSheet extends ConsumerWidget {
  const ScanResultSheet({
    required this.mealKind,
    this.dayOffset = 0,
    super.key,
  });

  final MealKind mealKind;
  final int dayOffset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.x4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header: < scan Result
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
                    'scan Result',
                    style: AppTypography.itemTitle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            // Confidence badges row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D5C3A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'High Confidence',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5B25D).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'High-accurate labels',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Main Prediction Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: scheme.outlineVariant),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        session.photo,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${chosen.dish.name} - ${chosen.percent}%',
                            style: AppTypography.itemTitle.copyWith(
                              color: scheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${chosen.percent}% Confidence',
                            style: AppTypography.caption.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            chosen.dish.ingredients.take(3).join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Top matches selection if multiple or user wants to switch
            if (session.topMatches.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < session.topMatches.length; i++) ...[
                        _MatchRow(
                          prediction: session.topMatches[i],
                          selected: i == session.selectedMatch,
                          onTap: () => ref.read(scanSessionProvider.notifier).state =
                              session.selectMatch(i),
                        ),
                        if (i != session.topMatches.length - 1)
                          Divider(height: 1, color: scheme.outlineVariant),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Serving Size Section per ui_design2.jpg Screen 3
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Serving Size',
                    style: AppTypography.itemTitle.copyWith(
                      color: scheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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
                            onTap: () => ref.read(scanSessionProvider.notifier).state =
                                session.selectServing(i),
                          ),
                        ),
                        if (i < session.servings.length - 1 && i < 2)
                          const SizedBox(width: 10),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Stepper controls: - ... +
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: session.selectedServing > 0
                            ? () => ref.read(scanSessionProvider.notifier).state =
                                session.selectServing(session.selectedServing - 1)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 22),
                      ),
                      const SizedBox(width: 8),
                      for (var i = 0; i < session.servings.length && i < 4; i++) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == session.selectedServing
                                ? colors.gold
                                : scheme.outlineVariant,
                          ),
                        ),
                        if (i < 3) const SizedBox(width: 6),
                      ],
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: session.selectedServing < session.servings.length - 1
                            ? () => ref.read(scanSessionProvider.notifier).state =
                                session.selectServing(session.selectedServing + 1)
                            : null,
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Approx. Calories Pill
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.accentWash,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: colors.accent,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Approx. Calories',
                          style: AppTypography.caption.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                          ),
                        ),
                        Text(
                          '${serving.lowKcal} – ${serving.highKcal} kcal',
                          style: AppTypography.value20.copyWith(
                            color: scheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'P:${serving.proteinGrams}g · C:${serving.carbsGrams}g · F:${serving.fatGrams}g',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Nutritionist insights card from ui_design.jpg Screen 5
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.eco_rounded, size: 18, color: colors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Nutritionist insights',
                          style: AppTypography.itemTitle.copyWith(
                            color: scheme.onSurface,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Balanced protein and healthy fats for steady energy. Contains key dietary minerals, calcium, and micronutrients.',
                      style: AppTypography.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Substitute suggestions card from ui_design.jpg Screen 5
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.swap_horiz_rounded, size: 18, color: colors.accent),
                        const SizedBox(width: 6),
                        Text(
                          'Substitute suggestions',
                          style: AppTypography.itemTitle.copyWith(
                            color: scheme.onSurface,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.primaryWash,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Healthier swap: 420 kcal',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Opt for whole-wheat roti or brown rice',
                            style: AppTypography.caption.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontSize: 11.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Big Emerald CTA button "Confirm & Add to Diary"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: colors.emeraldGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => _confirm(context, ref, session),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Confirm & Add to Diary',
                          style: AppTypography.label.copyWith(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
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

  void _confirm(BuildContext context, WidgetRef ref, ScanSession session) {
    final l10n = AppLocalizations.of(context)!;
    final serving = session.chosenServing;
    final store = ref.read(dayLogProvider.notifier);

    store.add(
      LogEntry(
        mealKind: mealKind,
        dish: session.chosenPrediction.dish.name,
        kcal: serving.midKcal,
        proteinGrams: serving.proteinGrams,
        carbsGrams: serving.carbsGrams,
        fatGrams: serving.fatGrams,
        timeLabel: _timeLabel(DateTime.now()),
      ),
      dayOffset: dayOffset,
    );
    ref.read(scanSessionProvider.notifier).state = null;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(true);
    AppToast.show(
      messenger,
      message: l10n.addedToast(l10n.mealLabel(mealKind)),
      actionLabel: l10n.undo,
      onAction: () => store.removeNewest(dayOffset),
    );
  }

  static String _timeLabel(DateTime now) {
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
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
      color: selected ? const Color(0xFFFBF4E4) : scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? colors.gold : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? colors.gold : scheme.onSurfaceVariant,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({
    required this.prediction,
    required this.selected,
    required this.onTap,
  });

  final ScanPrediction prediction;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.primaryWash.withValues(alpha: 0.3) : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? scheme.primary : scheme.outline,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    prediction.label,
                    style: AppTypography.itemS.copyWith(
                      color: scheme.onSurface,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primaryWash,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${prediction.percent}%',
                    style: AppTypography.caption.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
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
