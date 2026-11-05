import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/app/log_store.dart';
import 'package:app/design_system/components/app_sheet.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/log_entry.dart';
import 'package:app/domain/entities/macro.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/extensions.dart';

/// Lists one meal's raw entries and lets the user delete an entry or
/// jump to manual search. Returns true when "Add another" is chosen.
Future<bool?> showMealDetailSheet(
  BuildContext context, {
  required int dayOffset,
  required MealKind meal,
}) {
  return showAppSheet<bool>(
    context,
    child: Consumer(
      builder: (context, ref, _) {
        final l10n = AppLocalizations.of(context)!;
        final entries = ref.watch(dayLogProvider)[dayOffset] ?? const [];
        final rows = <(int, LogEntry)>[
          for (var i = 0; i < entries.length; i++)
            if (entries[i].mealKind == meal) (i, entries[i]),
        ];

        return AppSheet(
          icon: mealIcon(meal),
          title: l10n.mealDetails,
          subtitle: l10n.mealLabel(meal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    l10n.noMealEntries,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyM.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                for (final (index, entry) in rows) ...[
                  _EntryRow(
                    entry: entry,
                    onDelete: () => ref
                        .read(dayLogProvider.notifier)
                        .removeAt(dayOffset, index),
                  ),
                  Divider(
                    height: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ],
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.add_rounded, size: 19),
                label: Text(l10n.addAnother),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.onDelete});

  final LogEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.primaryWash,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.restaurant_rounded,
              size: 18,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.dish,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.itemS.copyWith(
                    color: scheme.onSurface,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (entry.timeLabel != null) entry.timeLabel!,
                    '${entry.kcal} ${l10n.kcalUnit}',
                    '${l10n.macroLabel(MacroKind.protein)} '
                        '${entry.proteinGrams} ${l10n.gramUnit}',
                  ].join(' · '),
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
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: scheme.onSurfaceVariant,
            tooltip: l10n.delete,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

IconData mealIcon(MealKind kind) {
  switch (kind) {
    case MealKind.breakfast:
      return Icons.wb_sunny_outlined;
    case MealKind.lunch:
      return Icons.lunch_dining_outlined;
    case MealKind.dinner:
      return Icons.nightlight_outlined;
    case MealKind.snacks:
      return Icons.cookie_outlined;
  }
}
