import 'package:flutter/material.dart';

/// Section header row: bold title left, optional trailing action
/// ("Today's meals", "Nutrition breakdown", "Meal log", ...).
class GroupHeader extends StatelessWidget {
  const GroupHeader({required this.title, this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: text.titleMedium,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
