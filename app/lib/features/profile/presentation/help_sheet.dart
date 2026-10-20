import 'package:flutter/material.dart';

import 'package:app/design_system/components/app_sheet.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/l10n/app_localizations.dart';

/// Offline help: the four things users ask about first.
Future<void> showHelpSheet(BuildContext context) {
  return showAppSheet<void>(context, child: const HelpSheet());
}

class HelpSheet extends StatelessWidget {
  const HelpSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    final faqs = [
      (l10n.helpScanQ, l10n.helpScanA),
      (l10n.helpCaloriesQ, l10n.helpCaloriesA),
      (l10n.helpStepsQ, l10n.helpStepsA),
      (l10n.helpOfflineQ, l10n.helpOfflineA),
    ];

    return AppSheet(
      icon: Icons.help_outline_rounded,
      title: l10n.helpTitle,
      subtitle: l10n.helpSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < faqs.length; i++) ...[
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: i == 0,
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 3,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  iconColor: scheme.primary,
                  collapsedIconColor: scheme.onSurfaceVariant,
                  backgroundColor: Colors.transparent,
                  collapsedBackgroundColor: Colors.transparent,
                  title: Text(
                    faqs[i].$1,
                    style: AppTypography.itemS.copyWith(
                      color: scheme.onSurface,
                      fontSize: 13.5,
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        faqs[i].$2,
                        style: AppTypography.bodyM.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.doneLabel),
          ),
        ],
      ),
    );
  }
}
