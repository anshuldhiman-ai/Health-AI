import 'package:flutter/material.dart';

import 'package:app/design_system/tokens/tokens.dart';

/// Dashboard quiet tile: a free-standing coloured glyph, a prominent
/// value and a caption (ref_ui.png). Soft-shadow card, no border.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.icon,
    required this.value,
    required this.caption,
    this.iconColor,
    this.expanded = false,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String value;
  final String caption;

  /// Data-viz glyph colour (primary / water / sleep). The caption
  /// always carries the meaning as text (R14).
  final Color? iconColor;

  /// When true the tile expands to fill remaining row space.
  final bool expanded;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final inner = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor ?? scheme.primary, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.value18.copyWith(color: scheme.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: AppTypography.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    final tile = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: inner,
        ),
      ),
    );

    if (expanded) return Expanded(child: tile);
    return tile;
  }
}
