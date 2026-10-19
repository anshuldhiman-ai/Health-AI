import 'package:flutter/material.dart';

import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Welcome/onboarding per ref_ui.png page 1: leaf mark, tagline,
/// Get Started. There is NO cloud account in this app (R1/R3) — the
/// "Sign in" affordance exists in the reference layout, so it renders
/// but explains the device-only model instead of asking for a login.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Leaf mark: moss circle + leaf. Replaced by the brand
              // logo asset when the identity is decided (Section 0).
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.eco_outlined,
                  color: scheme.onPrimary,
                  size: 56,
                ),
              ),
              const SizedBox(height: AppSpacing.x6),
              Text(
                l10n.appTitle,
                style: text.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                l10n.welcomeTagline,
                style: text.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/today'),
                  child: Text(l10n.getStarted),
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              TextButton(
                onPressed: () => _deviceOnlyNote(context),
                child: Text(
                  l10n.signIn,
                  style: text.labelLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.x6),
            ],
          ),
        ),
      ),
    );
  }

  void _deviceOnlyNote(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sheet.x),
        ),
        icon: Icon(Icons.shield_outlined, color: scheme.primary),
        title: Text(l10n.deviceOnlyTitle),
        content: Text(l10n.signInNote),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.okGotIt),
          ),
        ],
      ),
    );
  }
}
