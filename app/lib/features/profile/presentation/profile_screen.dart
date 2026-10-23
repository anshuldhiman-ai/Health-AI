import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/nutrition_targets.dart';
import 'package:app/data/preferences/goal_kind_controller.dart';
import 'package:app/features/profile/presentation/goal_sheet.dart';
import 'package:app/features/profile/presentation/help_sheet.dart';
import 'package:app/features/profile/presentation/settings_sheet.dart';
import 'package:app/l10n/app_localizations.dart';

/// Profile matching ui_design.jpg Screen 10:
/// - Golden top arc banner
/// - Sleek Avatar with "Premium" gold badge
/// - "Personal Details" (Age, Height, Weight, Activity Level)
/// - "Integrations" (Apple Health, Garmin, Fitbit)
/// - "Goal History" and "Subscriptions" rows
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(goalKindProvider);
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return Scaffold(
      body: Stack(
        children: [
          // Golden gradient banner at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 180,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE5B25D),
                    Color(0xFFD4AF37),
                    Color(0xFFC59A3F),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                10,
                AppSpacing.screenPadding,
                96,
              ),
              children: [
                // Top Nav Bar: Back and Settings
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => showSettingsSheet(context),
                      icon: const Icon(Icons.settings_outlined, color: Colors.black87),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Avatar + Premium Badge
                Center(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/brand/avatar.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: scheme.surface,
                              child: Icon(Icons.person, size: 50, color: scheme.primary),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3.5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE5B25D), Color(0xFFC59A3F)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Sleek Avatar',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleL.copyWith(
                    color: scheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Account dashboard',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 22),
                // Personal Details Section
                Text(
                  'Personal Details',
                  style: AppTypography.titleM.copyWith(
                    color: scheme.onSurface,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Row(
                    children: [
                      _DetailItem(label: 'Age', value: '28', subtitle: 'Ag'),
                      _DetailDivider(),
                      _DetailItem(label: 'Height', value: '178 cm', subtitle: 'Height'),
                      _DetailDivider(),
                      _DetailItem(label: 'Weight', value: '78 kg', subtitle: 'Weight'),
                      _DetailDivider(),
                      _DetailItem(label: 'Activity Level', value: 'High', subtitle: 'Active'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Integrations Section (Apple Health, Garmin, Fitbit)
                Text(
                  'Integrations',
                  style: AppTypography.titleM.copyWith(
                    color: scheme.onSurface,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _IntegrationButton(
                        name: 'Apple\nHealth',
                        icon: Icons.favorite_rounded,
                        color: const Color(0xFFFF2D55),
                        onTap: () {},
                      ),
                      _IntegrationButton(
                        name: 'Garmin',
                        icon: Icons.navigation_rounded,
                        color: const Color(0xFF007CC3),
                        onTap: () {},
                      ),
                      _IntegrationButton(
                        name: 'Fitbit',
                        icon: Icons.grain_rounded,
                        color: const Color(0xFF00B0B9),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Goal History Card
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  onTap: () => showGoalSheet(context),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.primaryWash,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.track_changes_rounded, color: colors.primary, size: 21),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Goal History',
                              style: AppTypography.itemTitle.copyWith(
                                color: scheme.onSurface,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              _goalSubtitle(l10n, goal),
                              style: AppTypography.caption.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Subscriptions Card
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  onTap: () => showHelpSheet(context),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.card_membership_rounded, color: Color(0xFFD4AF37), size: 21),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Subscriptions',
                              style: AppTypography.itemTitle.copyWith(
                                color: scheme.onSurface,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Premium lifetime access active',
                              style: AppTypography.caption.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        children: [
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTypography.itemTitle.copyWith(
              color: scheme.onSurface,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _IntegrationButton extends StatelessWidget {
  const _IntegrationButton({
    required this.name,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
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
