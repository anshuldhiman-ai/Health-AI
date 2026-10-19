import 'package:flutter/material.dart';

/// Circular progress ring — the calorie-remaining hero and the
/// nutrition-breakdown donut (generic component; owns nothing about
/// food). Only gradient allowed in the design system is inside this
/// ring's "scan highlight" mode (Section 10.2) — not used by default.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.progress,
    required this.child,
    this.size = 132,
    this.strokeWidth = 10,
    this.trackColor,
    this.progressColor,
    this.semanticLabel,
    super.key,
  }) : assert(progress >= 0 && progress <= 1);

  /// 0..1 completion of the ring.
  final double progress;

  /// Center content (the big number + unit).
  final Widget child;

  final double size;
  final double strokeWidth;

  /// Defaults: track = [ColorScheme.outlineVariant], arc = primary.
  final Color? trackColor;
  final Color? progressColor;

  /// Whole-component semantics (charts get text summaries, R14).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticLabel,
      value: '${(progress * 100).round()}%',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: progress,
            trackColor: trackColor ?? scheme.outlineVariant,
            progressColor: progressColor ?? scheme.primary,
            strokeWidth: strokeWidth,
            textDirectionOf: Directionality.of(context),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
    required this.textDirectionOf,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;
  final TextDirection textDirectionOf;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track: full circle, hairline look via reduced opacity of line.
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawArc(rect, 0, 2 * 3.141592653589793, false, track);

    // Progress arc: starts at 12 o'clock, sweeps clockwise. In RTL the
    // sweep mirrors so "more logged" always grows from the start.
    final sweep = 2 * 3.141592653589793 * progress;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = progressColor;
    if (sweep <= 0.0001) return;
    canvas.drawArc(rect, -3.141592653589793 / 2, sweep, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}
