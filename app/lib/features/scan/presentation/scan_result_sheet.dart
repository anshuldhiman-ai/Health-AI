import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/app/log_store.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/log_entry.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/features/scan/application/scan_state.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/extensions.dart';

/// Result sheet per ref_ui.png: top-3 candidate radio list, serving
/// chips, calories-range card, add-to-meal action.
///
/// Predictions come from [sampleScanSessionProvider]; the real
/// recogniser feeds this same shape in M2 (Section 8.7). Calories are
/// ALWAYS a range — portion error dominates class error, so a single
/// confident number would be dishonest (Section 8.1, R11).
///
/// Confirming writes a [LogEntry.estimated] into the shared
/// [dayLogProvider] store; the sheet pops `true` so the camera
/// screen can close back to the caller.
class ScanResultSheet extends ConsumerStatefulWidget {
  const ScanResultSheet({required this.mealKind, super.key});

  /// Which meal slot the user is logging into.
  final MealKind mealKind;

  @override
  ConsumerState<ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends ConsumerState<ScanResultSheet> {
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sampleScanSessionProvider);
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final serving = session.chosenServing;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.x4,
        right: AppSpacing.x4,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.x4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.x4,
        children: [
          Text(l10n.scanResultTitle, style: text.titleLarge),
          Text(
            l10n.scanResultSubtitle,
            style: text.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          for (var i = 0; i < session.topMatches.length; i++)
            _MatchTile(
              index: i,
              selected: i == session.selectedMatch,
            ),
          Text(
            l10n.servingSizeLabel,
            style: text.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Wrap(
            spacing: AppSpacing.x2,
            children: [
              for (var i = 0; i < session.servings.length; i++)
                _ServingChip(
                  label: session.servings[i].label,
                  selected: i == session.selectedServing,
                  onSelected: (_) => ref.read(
                    sampleScanSessionProvider.notifier,
                  ).update((s) => _withServing(s, i)),
                ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x4,
              vertical: AppSpacing.x3,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadii.card.x),
            ),
            child: Row(
              spacing: AppSpacing.x3,
              children: [
                Icon(Icons.local_fire_department, color: scheme.tertiary),
                Expanded(
                  child: Text(
                    l10n.estimatedCalories,
                    style: text.labelLarge,
                  ),
                ),
                Text(
                  '${serving.lowKcal} – ${serving.highKcal} ${l10n.kcalUnit}',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => _confirm(context),
            child: Text(
              l10n.addToMeal(l10n.mealLabel(widget.mealKind)),
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
        ],
      ),
    );
  }

  void _confirm(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.read(sampleScanSessionProvider);
    final serving = session.chosenServing;
    final store = ref.read(dayLogProvider.notifier);

    store.add(
      LogEntry.estimated(
        mealKind: widget.mealKind,
        dish: session.chosenPrediction.label,
        kcal: ((serving.lowKcal + serving.highKcal) / 2).round(),
      ),
    );
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.addedToast(l10n.mealLabel(widget.mealKind))),
        action: SnackBarAction(
          label: l10n.undo,
          // Latest-added entry of today is exactly this write.
          onPressed: () => store.removeNewest(0),
        ),
      ),
    );
  }

  ScanSession _withServing(ScanSession s, int serving) =>
      ScanSession(
        topMatches: s.topMatches,
        servings: s.servings,
        selectedMatch: s.selectedMatch,
        selectedServing: serving,
      );
}

class _MatchTile extends ConsumerWidget {
  const _MatchTile({required this.index, required this.selected});

  final int index;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session =
        ref.watch(sampleScanSessionProvider.select((s) => s.topMatches[index]));
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => ref
          .read(sampleScanSessionProvider.notifier)
          .update((s) => ScanSession(
                topMatches: s.topMatches,
                servings: s.servings,
                selectedMatch: index,
                selectedServing: s.selectedServing,
              )),
      borderRadius: BorderRadius.circular(AppRadii.card.x),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.card.x),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          spacing: AppSpacing.x3,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadii.input.x),
              ),
              child: Icon(
                Icons.restaurant,
                color: scheme.primary,
                size: 20,
              ),
            ),
            Expanded(
              child: Text(session.label, style: text.titleSmall),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadii.pill.x),
              ),
              // Confidence is shown as text + tint: never colour alone.
              child: Text(
                '${session.percent}%',
                style: text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? scheme.primary : scheme.outline,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServingChip extends StatelessWidget {
  const _ServingChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return FilterChip.elevated(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      labelStyle: text.labelLarge?.copyWith(
        color: selected ? scheme.onPrimary : scheme.onSurface,
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      selectedShadowColor: Colors.transparent,
      backgroundColor: scheme.surface,
      selectedColor: scheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill.x),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outline,
        ),
      ),
    );
  }
}
