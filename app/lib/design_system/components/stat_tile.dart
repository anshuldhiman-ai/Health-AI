import 'package:flutter/material.dart';

/// Small square-ish tile with an icon chip, a prominent value and a
/// caption — the dashboard's steps / water / sleep quiet tiles.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.icon,
    required this.value,
    required this.caption,
    this.expanded = false,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String value;
  final String caption;

  /// When true the tile expands to fill remaining row space.
  final bool expanded;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final inner = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: scheme.primary, size: 20),
        ),
        Text(value, style: text.titleMedium),
        Text(
          caption,
          style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );

    final tile = Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outline),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: inner,
        ),
      ),
    );

    if (expanded) return Expanded(child: tile);
    return tile;
  }
}
