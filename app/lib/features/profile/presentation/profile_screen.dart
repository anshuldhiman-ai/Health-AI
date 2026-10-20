import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/components/screen_header.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/nutrition_targets.dart';
import 'package:app/data/preferences/goal_kind_controller.dart';
import 'package:app/features/profile/presentation/goal_sheet.dart';
import 'package:app/features/profile/application/profile_state.dart';
import 'package:app/features/profile/presentation/about_dialog.dart';
import 'package:app/features/profile/presentation/help_sheet.dart';
import 'package:app/features/profile/presentation/settings_sheet.dart';
import 'package:app/l10n/app_localizations.dart';

/// Profile per ref_ui.png: identity block (device only — no cloud
/// account exists, R3), goal card, link rows.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sampleProfileProvider);
    final goal = ref.watch(goalKindProvider);
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.x3,
            AppSpacing.screenPadding,
            88,
          ),
          children: [
            ScreenHeader(
              icon: Icons.person_rounded,
              title: l10n.profileTitle,
              trailing: IconButton(
                onPressed: () => showSettingsSheet(context),
                tooltip: l10n.settingsRow,
                icon: Icon(
                  Icons.settings_outlined,
                  size: 21,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/brand/avatar.png',
                    fit: BoxFit.cover,
                    semanticLabel: state.displayName,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              state.displayName,
              textAlign: TextAlign.center,
              style: AppTypography.value20.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.deviceOnly,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            _GoalCard(
              subtitle: _goalSubtitle(l10n, goal),
              onTap: () => showGoalSheet(context),
            ),
            const SizedBox(height: 14),
            _LinkRow(
              icon: Icons.settings_outlined,
              label: l10n.settingsRow,
              onTap: () => showSettingsSheet(context),
            ),
            _LinkRow(
              icon: Icons.help_outline_rounded,
              label: l10n.helpRow,
              onTap: () => showHelpSheet(context),
            ),
            _LinkRow(
              icon: Icons.info_outline_rounded,
              label: l10n.aboutRow,
              onTap: () => showAppAbout(context),
            ),
          ],
        ),
      ),
    );
  }
}

String _goalSubtitle(AppLocalizations l10n, GoalKind kind) => switch (kind) {
  GoalKind.lose => l10n.goalLoseSubtitle,
  GoalKind.maintain => l10n.goalMaintainSubtitle,
  GoalKind.gain => l10n.goalGainSubtitle,
};

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.subtitle, required this.onTap});

  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryWash,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.flag_rounded, color: scheme.primary, size: 21),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.myGoals,
                  style: AppTypography.itemS.copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        child: Row(
          spacing: 12,
          children: [
            Icon(icon, color: scheme.onSurface, size: 21),
            Expanded(
              child: Text(
                label,
                style: AppTypography.itemS.copyWith(color: scheme.onSurface),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
