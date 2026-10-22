import 'package:flutter/material.dart';

import 'package:app/design_system/tokens/tokens.dart';

/// The reference card: white surface, 20 radius, a hairline edge and
/// barely-there depth. Use for every content section.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.x4),
    this.onTap,
    this.radius = 20,
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
        color: scheme.surface,
        borderRadius: borderRadius,
        // A hairline edge defines the surface on the mist canvas
        // without the "floating blob" look a strong shadow gives.
        border: Border.all(color: scheme.outlineVariant),
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
