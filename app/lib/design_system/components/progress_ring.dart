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
        height: size,
        child: CustomPaint(
          painter: _RingPainter(
            segments: effectiveSegments,
            trackColor: trackColor ?? scheme.outlineVariant,
            strokeWidth: strokeWidth,
          ),
          child: Center(child: child),
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
  });

  final List<RingSegment> segments;
  final Color trackColor;
  final double strokeWidth;

  static const _tau = 2 * math.pi;
  static const _gap = 0.10; // radians between segments (multi mode)

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawArc(rect, 0, _tau, false, track);

    final multi = segments.length > 1;
    final gap = multi ? _gap : 0.0;
    var start = -math.pi / 2; // 12 o'clock
    for (final seg in segments) {
      final sweep = _tau * seg.value.clamp(0.0, 1.0) - gap;
      if (sweep <= 0.001) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = seg.color;
      canvas.drawArc(rect, start + gap / 2, sweep, false, paint);
      start += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth ||
      old.segments.length != segments.length ||
      [
        for (var i = 0; i < segments.length; i++)
          old.segments[i].value != segments[i].value ||
              old.segments[i].color != segments[i].color,
      ].any((changed) => changed);
}
