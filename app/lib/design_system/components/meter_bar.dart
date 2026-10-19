import 'package:flutter/material.dart';

/// Horizontal meter bar with a label row (generic; no nutrition
/// knowledge). The reference dashboard uses it for protein / carbs /
/// fat against targets.
class MeterBar extends StatelessWidget {
  const MeterBar({
    required this.label,
    required this.value,
    required this.target,
    this.barColor,
    this.unit = 'g',
    super.key,
  }) : assert(value >= 0 && target > 0);

  final String label;

  /// Current value in grams (int-friendly numbers only, for now).
  final int value;

  /// Target in grams.
  final int target;

  /// Defaults: protein-like fill uses primary, carbs use tertiary
  /// (turmeric) — the caller decides; only colour + text here (R14).
  final Color? barColor;

  final String unit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final ratio = (value / target).clamp(0.0, 1.0);

    return Semantics(
      label: '$label: $value of $target $unit',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$value / $target $unit',
                style: text.labelMedium,
              ),
            ],
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            builder: (context, animated, _) => ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: animated,
                minHeight: 8,
                backgroundColor: scheme.outlineVariant,
                valueColor: AlwaysStoppedAnimation(
                  barColor ?? scheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
