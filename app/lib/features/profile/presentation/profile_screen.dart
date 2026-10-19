import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/features/profile/application/profile_state.dart';
import 'package:app/l10n/app_localizations.dart';

/// Profile per ref_ui.png: identity block (device only — no cloud
/// account exists, R3), goal card, link rows.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sampleProfileProvider);
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.x4,
            AppSpacing.screenPadding,
            AppSpacing.x6,
          ),
          children: [
            Text(l10n.profileTitle, style: text.titleLarge),
            const SizedBox(height: AppSpacing.x4),
            Row(
              spacing: AppSpacing.x3,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    state.displayName.isEmpty
                        ? '·'
                        : state.displayName[0].toUpperCase(),
                    style: text.titleLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        state.displayName,
                        style: text.titleMedium,
                      ),
                      Text(
                        l10n.deviceOnly,
                        style: text.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x4),
            _GoalCard(subtitle: state.goalSubtitle),
            const SizedBox(height: AppSpacing.x6),
            _LinkRow(
              icon: Icons.settings_outlined,
              label: l10n.settingsRow,
              // TODO(M1): settings page (theme/locale overrides live here).
              onTap: null,
            ),
            _LinkRow(
              icon: Icons.help_outline,
              label: l10n.helpRow,
              onTap: null, // TODO(M2): support sheet
            ),
            _LinkRow(
              icon: Icons.info_outline,
              label: l10n.aboutRow,
              onTap: null, // TODO(M1): about + licences page
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.card.x),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        spacing: AppSpacing.x3,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.flag_outlined,
              color: scheme.primary,
              size: 22,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(l10n.myGoals, style: text.titleSmall),
                Text(
                  subtitle,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.card.x),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        spacing: AppSpacing.x3,
        children: [
          Icon(icon, color: scheme.primary, size: 22),
          Expanded(child: Text(label, style: text.titleSmall)),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card.x),
          ),
          child: row,
        ),
      ),
    );
  }
}
