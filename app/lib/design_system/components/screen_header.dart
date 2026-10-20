import 'package:flutter/material.dart';

import 'package:app/design_system/tokens/tokens.dart';

/// Screen header with a tinted icon tile and a bold title (Insights,
/// Profile). Optional trailing action (settings gear).
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    required this.icon,
    required this.title,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: scheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: AppTypography.titleL.copyWith(color: scheme.onSurface),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
