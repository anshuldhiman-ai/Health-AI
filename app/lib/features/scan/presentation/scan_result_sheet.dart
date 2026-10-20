import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/app/log_store.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/food_portion.dart';
import 'package:app/domain/entities/log_entry.dart';
import 'package:app/domain/entities/macro.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/features/scan/application/scan_state.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/extensions.dart';

/// Result sheet per ref_ui.png: photo + top-3 radio list with
/// confidence pills, ingredient hints when the model is unsure,
/// serving chips, a cream energy card with the macro split, and the
/// add-to-meal action.
///
/// Calories are ALWAYS a range (Section 8.1: portion error dominates
/// class error). Macros come from the selected serving's per-100 g
/// catalog row, so the diary categorises protein/carbs/fat instead of
/// applying a blanket 20/55/25 split.
class ScanResultSheet extends ConsumerWidget {
  const ScanResultSheet({
    required this.mealKind,
    this.dayOffset = 0,
    super.key,
  });

  /// Which meal slot the user is logging into.
  final MealKind mealKind;

  /// 0 = today, 1 = yesterday, ... Target selected in Diary.
  final int dayOffset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(scanSessionProvider);
    if (session == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final serving = session.chosenServing;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.x2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero photo flush with the sheet edge, as in ref_ui.png.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Image.memory(
                    session.photo,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, right: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.scanResultTitle,
                          style: AppTypography.value20.copyWith(
                            color: scheme.onSurface,
                            fontSize: 19,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.scanResultSubtitle,
                          style: AppTypography.caption.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 14,
                children: [
                  if (session.uncertain)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colors.accentWash,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        spacing: 8,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: colors.accent,
                          ),
                          Expanded(
                            child: Text(
                              l10n.scanUncertainHint,
                              style: AppTypography.caption.copyWith(
                                color: scheme.onSurface,
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < session.topMatches.length; i++) ...[
                          _MatchRow(
                            prediction: session.topMatches[i],
                            selected: i == session.selectedMatch,
                            onTap: () =>
                                ref.read(scanSessionProvider.notifier).state =
                                    session.selectMatch(i),
                          ),
                          if (i != session.topMatches.length - 1)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: scheme.outlineVariant,
                            ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      Text(
                        l10n.servingSizeLabel,
                        style: AppTypography.itemS.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13.5,
                        ),
                      ),
                      Row(
                        spacing: 8,
                        children: [
                          for (var i = 0; i < session.servings.length; i++)
                            Expanded(
                              child: _ServingChip(
                                label: session.servings[i].label,
                                selected: i == session.selectedServing,
                                onTap: () =>
                                    ref
                                        .read(scanSessionProvider.notifier)
                                        .state = session.selectServing(
                                      i,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 13),
                    decoration: BoxDecoration(
                      color: colors.accentWash,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.estimatedCalories,
                          style: AppTypography.caption.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 21,
                              color: colors.accent,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${serving.lowKcal} – ${serving.highKcal} '
                              '${l10n.kcalUnit}',
                              style: AppTypography.value20.copyWith(
                                color: scheme.onSurface,
                                fontSize: 19,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _macroLine(l10n, serving),
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () => _confirm(context, ref, session),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(l10n.addToMeal(l10n.mealLabel(mealKind))),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _macroLine(AppLocalizations l10n, FoodPortion serving) {
    final p = l10n.macroLabel(MacroKind.protein);
    final c = l10n.macroLabel(MacroKind.carbs);
    final f = l10n.macroLabel(MacroKind.fat);
    return '$p ${serving.proteinGrams} g · $c ${serving.carbsGrams} g '
        '· $f ${serving.fatGrams} g';
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
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.addedToast(l10n.mealLabel(mealKind))),
        action: SnackBarAction(
          label: l10n.undo,
          // Latest-added entry for the selected day is this write.
          onPressed: () => store.removeNewest(dayOffset),
        ),
      ),
    );
  }

  static String _timeLabel(DateTime now) {
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
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
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Container(
                    width: 20,
                    height: 20,
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
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction.label,
                        style: AppTypography.itemS.copyWith(
                          color: scheme.onSurface,
                          fontSize: 14.5,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(height: 2),
                        Text(
                          prediction.dish.ingredients.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryWash,
                    borderRadius: BorderRadius.circular(AppRadii.pill.x),
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

class _ServingChip extends StatelessWidget {
  const _ServingChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(
        color: selected ? scheme.primary : scheme.outlineVariant,
      ),
    );

    return Material(
      color: selected ? scheme.primary : scheme.surface,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: selected ? scheme.onPrimary : scheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
