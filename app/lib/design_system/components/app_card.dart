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

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.95),
        borderRadius: borderRadius,
        // Glassmorphic cards: White surfaces with a very subtle 1px border
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? scheme.outlineVariant
              : Colors.white.withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: AppShadows.card,
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
