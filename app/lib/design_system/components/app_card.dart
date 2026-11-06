import 'package:flutter/material.dart';

import 'package:app/design_system/tokens/tokens.dart';

/// The reference card: white surface, 20 radius, a hairline edge and
/// barely-there depth. Use for every content section.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.x4),
    this.onTap,
    this.radius = 24,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(radius);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = DecoratedBox(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A2621),
                  Color(0xFF051B17),
                ],
              )
            : null,
        color: isDark ? null : scheme.surface.withValues(alpha: 0.95),
        borderRadius: borderRadius,
        // Glassmorphic cards: Subtle emerald outline in dark mode, white highlight in light mode
        border: Border.all(
          color: isDark
              ? const Color(0xFF00E5A3).withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFF00E5A3).withValues(alpha: 0.04),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, -2),
                ),
              ]
            : AppShadows.card,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: borderRadius, child: card),
    );
  }
}
