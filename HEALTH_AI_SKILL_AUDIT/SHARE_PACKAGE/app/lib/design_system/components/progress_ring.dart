import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One arc of a multi-segment ring (donut charts).
class RingSegment {
  const RingSegment({required this.value, required this.color});

  /// 0..1 share of the ring.
  final double value;
  final Color color;
}

/// Circular progress ring / donut (generic component; owns nothing
/// about food).
///
/// - Single mode: [progress] 0..1 draws one arc from 12 o'clock.
/// - Multi mode: [segments] draw consecutive arcs with small gaps —
///   used by the macro-split donuts.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.child,
    this.progress,
    this.segments,
    this.size = 132,
    this.strokeWidth = 12,
    this.trackColor,
    this.barColor,
    this.gradientColors,
    this.isArc = false,
    this.semanticLabel,
    super.key,
  }) : assert(
         progress != null || segments != null,
         'give either progress or segments',
       );

  /// 0..1 completion of the ring (single-arc mode).
  final double? progress;

  /// Multi-arc mode (each value 0..1, sum ≦ 1; remainder = track).
  final List<RingSegment>? segments;

  /// Center content (the big number + caption).
  final Widget child;

  final double size;
  final double strokeWidth;

  /// Defaults to [ColorScheme.outlineVariant].
  final Color? trackColor;

  /// Single-arc colour. Defaults to [ColorScheme.primary]; multi-mode
  /// uses each [RingSegment] colour instead.
  final Color? barColor;

  /// Multi-color gradient for the progress ring (e.g., rainbow/sunset/emerald).
  final List<Color>? gradientColors;

  /// Whether to render as a semi-circular / arc gauge (180 degrees).
  final bool isArc;

  /// Whole-component semantics (charts get text summaries, R14).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveSegments =
        segments ??
        [
          RingSegment(
            value: (progress ?? 0).clamp(0.0, 1.0),
            color: barColor ?? scheme.primary,
          ),
        ];

    final total = effectiveSegments.fold<double>(0, (s, e) => s + e.value);
    final percent = (total * 100).round();

    return Semantics(
      label: semanticLabel,
      value: '$percent%',
      child: SizedBox(
        width: size,
        height: isArc ? size * 0.65 : size,
        child: CustomPaint(
          painter: _RingPainter(
            segments: effectiveSegments,
            trackColor:
                trackColor ?? scheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: strokeWidth,
            gradientColors: gradientColors,
            isArc: isArc,
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(top: isArc ? size * 0.12 : 0),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.segments,
    required this.trackColor,
    required this.strokeWidth,
    this.gradientColors,
    this.isArc = false,
  });

  final List<RingSegment> segments;
  final Color trackColor;
  final double strokeWidth;
  final List<Color>? gradientColors;
  final bool isArc;

  static const _tau = 2 * math.pi;
  static const _gap = 0.10; // radians between segments (multi mode)

  @override
  void paint(Canvas canvas, Size size) {
    final center = isArc
        ? Offset(size.width / 2, size.width / 2)
        : Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final totalAngle = isArc ? math.pi : _tau;
    final startAngle = isArc ? math.pi : -math.pi / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    canvas.drawArc(rect, startAngle, totalAngle, false, track);

    final multi = segments.length > 1;
    final gap = multi ? _gap : 0.0;
    var start = startAngle;

    for (final seg in segments) {
      final sweep = totalAngle * seg.value.clamp(0.0, 1.0) - gap;
      if (sweep <= 0.001) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (gradientColors != null && gradientColors!.length >= 2) {
        paint.shader = SweepGradient(
          colors: gradientColors!,
          startAngle: 0.0,
          endAngle: _tau,
          transform: GradientRotation(startAngle),
        ).createShader(rect);
      } else {
        paint.color = seg.color;
      }

      canvas.drawArc(rect, start + gap / 2, sweep, false, paint);
      start += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth ||
      old.gradientColors != gradientColors ||
      old.isArc != isArc ||
      old.segments.length != segments.length ||
      [
        for (var i = 0; i < segments.length; i++)
          old.segments[i].value != segments[i].value ||
              old.segments[i].color != segments[i].color,
      ].any((changed) => changed);
}
