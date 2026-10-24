import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/design_system/components/brand_mark.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Welcome/onboarding aligned to ui_design.jpg and ui_design2.jpg:
/// leaf mark, wordmark,
/// tagline, soft organic background, Get Started. There is NO cloud
/// account in this app (R1/R3) — the "Sign in" affordance explains the
/// device-only model instead of asking for a login.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  static const _seenKey = 'welcome.seen.v1';
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  Timer? _launchTimer;
  bool _returning = false;

  @override
  void initState() {
    super.initState();
    _resolveReturningSession();
  }

  Future<void> _resolveReturningSession() async {
    var seen = false;
    try {
      seen = (await SharedPreferences.getInstance()).getBool(_seenKey) ?? false;
    } catch (_) {
      // Keep onboarding available if local preferences cannot be read.
    }
    if (!mounted || !seen) return;
    setState(() => _returning = true);
    _entrance.forward();
    _launchTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) context.go('/today');
    });
  }

  @override
  void dispose() {
    _launchTimer?.cancel();
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_seenKey, true);
    } catch (_) {
      // Opening the app should still work when persistence is unavailable.
    }
    if (mounted) context.go('/today');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _WelcomeBlobsPainter(
                sage: colors.primaryWash,
                cream: colors.accentWash,
                gold: colors.accentSoft.withValues(alpha: 0.22),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  FadeTransition(
                    opacity: _returning
                        ? _entrance
                        : const AlwaysStoppedAnimation(1),
                    child: const BrandMark(size: 108),
                  ),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, .08),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Text(
                      _returning ? 'Welcome back' : l10n.appTitle,
                      key: ValueKey(_returning),
                      style: AppTypography.hero.copyWith(
                        color: scheme.onSurface,
                        fontSize: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _returning
                        ? 'Your daily wellness, beautifully in sync.'
                        : l10n.welcomeTagline,
                    style: AppTypography.bodyM.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 3),
                  if (!_returning)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _start,
                        child: Text(l10n.getStarted),
                      ),
                    ),
                  if (!_returning) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => _deviceOnlyNote(context),
                      child: Text(
                        l10n.signIn,
                        style: AppTypography.label.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 22),
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
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

/// Soft organic washes behind the welcome content (flat fills, no
/// decorative gradients): a large sage bloom bottom-left, cream at the
/// top-right, and a gold glow bottom-right.
class _WelcomeBlobsPainter extends CustomPainter {
  _WelcomeBlobsPainter({
    required this.sage,
    required this.cream,
    required this.gold,
  });

  final Color sage;
  final Color cream;
  final Color gold;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void blob(Offset center, double rx, double ry, double angle, Color color) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: rx * 2,
        height: ry * 2,
      );
      canvas.drawOval(rect, Paint()..color = color);
      canvas.restore();
    }

    blob(
      Offset(w * 0.04, h * 0.82),
      w * 0.62,
      w * 0.52,
      -0.35,
      sage.withValues(alpha: 0.55),
    );
    blob(
      Offset(w * 1.02, h * 0.16),
      w * 0.48,
      w * 0.40,
      0.5,
      cream.withValues(alpha: 0.85),
    );
    blob(Offset(w * 0.92, h * 0.99), w * 0.34, w * 0.28, math.pi / 7, gold);
  }

  @override
  bool shouldRepaint(_WelcomeBlobsPainter oldDelegate) =>
      oldDelegate.sage != sage ||
      oldDelegate.cream != cream ||
      oldDelegate.gold != gold;
}
