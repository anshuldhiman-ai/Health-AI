import 'package:flutter/material.dart';

import 'package:app/design_system/tokens/tokens.dart';

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
    final ratio = (value / target).clamp(0.0, 1.0);

    return Semantics(
      label: '$label: $value of $target $unit',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '$value / $target $unit',
                style: AppTypography.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: AppMotion.normal,
            curve: AppMotion.standard,
            builder: (context, animated, _) => ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill.x),
              child: LinearProgressIndicator(
                value: animated,
                minHeight: 7,
                backgroundColor: scheme.outlineVariant,
                valueColor: AlwaysStoppedAnimation(barColor ?? scheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
