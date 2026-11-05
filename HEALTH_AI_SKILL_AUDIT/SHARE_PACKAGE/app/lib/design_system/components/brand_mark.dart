import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The Health AI leaf mark: three leaves fanning from a single point —
/// two greens and one turmeric leaf (matches the approved reference).
///
/// Brand identity belongs to the design system; features only compose
/// it. The wordmark itself is text ([AppTypography.hero]).
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 96, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _BrandMarkPainter()),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final origin = Offset(s * 0.5, s * 0.78);

    // (angle in radians from vertical, length, halfWidth, colour)
    final leaves = [
      (-0.85, s * 0.52, s * 0.20, const Color(0xFF0F6D49)),
      (0.10, s * 0.60, s * 0.22, const Color(0xFF3E9B70)),
      (0.85, s * 0.46, s * 0.17, const Color(0xFFEAAF34)),
    ];

    for (final (angle, length, halfWidth, color) in leaves) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.rotate(angle);
      final path = Path()
        ..moveTo(0, 0)
        ..cubicTo(
          -halfWidth,
          -length * 0.30,
          -halfWidth * 0.85,
          -length * 0.78,
          0,
          -length,
        )
        ..cubicTo(
          halfWidth * 0.85,
          -length * 0.78,
          halfWidth,
          -length * 0.30,
          0,
          0,
        )
        ..close();
      canvas.drawPath(path, Paint()..color = color);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BrandMarkPainter oldDelegate) => false;
}

/// A single white leaf used inside the centre scan button.
class LeafGlyph extends StatelessWidget {
  const LeafGlyph({this.size = 16, this.color = Colors.white, super.key});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LeafGlyphPainter(color)),
    );
  }
}

class _LeafGlyphPainter extends CustomPainter {
  _LeafGlyphPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.save();
    canvas.translate(s / 2, s / 2);
    canvas.rotate(math.pi / 4);
    final path = Path()
      ..moveTo(0, s * 0.42)
      ..cubicTo(-s * 0.46, s * 0.05, -s * 0.30, -s * 0.38, 0, -s * 0.46)
      ..cubicTo(s * 0.30, -s * 0.38, s * 0.46, s * 0.05, 0, s * 0.42)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LeafGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}
