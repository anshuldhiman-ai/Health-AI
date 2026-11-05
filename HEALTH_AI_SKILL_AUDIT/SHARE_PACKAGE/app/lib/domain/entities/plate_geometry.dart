import 'dart:math' as math;

// Domain entity for plate geometry and scale (AGENTS.md §5.3, §6.1).

enum PlateKind { round, rectangular }

enum TiltSource { ellipse, imu, fused, homography }

/// Projective transform (row-major 3x3) mapping image pixels into the metric
/// rectified plane of a rectangular tray, in centimetres (AGENTS.md §6.1).
class TrayHomography {
  const TrayHomography(this.m) : assert(m.length == 9, '3x3 matrix');

  /// Row-major coefficients h11..h33.
  final List<double> m;

  /// Maps an image-space [point] into rectified centimetre coordinates.
  Point2D transform(Point2D point) {
    final denominator = m[6] * point.x + m[7] * point.y + m[8];
    final x = (m[0] * point.x + m[1] * point.y + m[2]) / denominator;
    final y = (m[3] * point.x + m[4] * point.y + m[5]) / denominator;
    return Point2D(x, y);
  }
}

class Point2D {
  const Point2D(this.x, this.y);

  final double x;
  final double y;

  @override
  String toString() => 'Point2D($x, $y)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point2D &&
          runtimeType == other.runtimeType &&
          (x - other.x).abs() < 1e-9 &&
          (y - other.y).abs() < 1e-9;

  @override
  int get hashCode => Object.hash(x, y);
}

class FittedEllipse {
  const FittedEllipse({
    required this.cx,
    required this.cy,
    required this.a,
    required this.b,
    required this.phi,
    required this.inlierRatio,
  });

  /// Center x coordinate in pixels.
  final double cx;

  /// Center y coordinate in pixels.
  final double cy;

  /// Semi-major axis in pixels (a >= b).
  final double a;

  /// Semi-minor axis in pixels.
  final double b;

  /// Rotation angle in radians.
  final double phi;

  /// Fraction of contour points that fit this ellipse.
  final double inlierRatio;

  /// Foreshortening ratio b / a (in [0, 1]).
  double get axisRatio => a > 0 ? (b / a).clamp(0.0, 1.0) : 1.0;
}

class PlateGeometry {
  const PlateGeometry({
    required this.kind,
    required this.cmPerPx,
    required this.tiltDeg,
    required this.source,
    required this.conflict,
    this.plateDiameterCm,
    this.ellipse,
    this.homography,
    this.trayWidthCm,
    this.trayHeightCm,
  });

  final PlateKind kind;

  /// Real-world centimeters per pixel along the un-foreshortened axis.
  final double cmPerPx;

  /// Camera tilt in degrees (0° = top-down vertical).
  final double tiltDeg;

  /// Source of the tilt calculation.
  final TiltSource source;

  /// True if ellipse tilt and IMU tilt differed by > 8°.
  final bool conflict;

  /// Reference diameter of the plate in cm (null for rectangular trays).
  final double? plateDiameterCm;

  /// Fitted ellipse parameters (null if rectangular).
  final FittedEllipse? ellipse;

  /// Image → metric rectified plane transform (null if round).
  final TrayHomography? homography;

  /// Known tray width in cm (null if round).
  final double? trayWidthCm;

  /// Known tray height in cm (null if round).
  final double? trayHeightCm;

  /// Real-world surface area in cm² for a region with [pixelCount] pixels lying in the plate plane.
  /// Formula from AGENTS.md §6.1: A_cm² = N_pixels * s² / cos(theta)
  double areaCm2FromPixels(int pixelCount) {
    final tiltRad = tiltDeg * (math.pi / 180.0);
    final cosTilt = math.cos(tiltRad);
    final safeCos = cosTilt > 0.05 ? cosTilt : 0.05;
    return (pixelCount * cmPerPx * cmPerPx) / safeCos;
  }

  /// Real-world surface area in cm2 for a region given as an image-space
  /// [polygon] (the form produced by mask post-processing, AGENTS.md §6.5).
  ///
  /// Round plate: shoelace area in px2, scaled by `cmPerPx^2 / cos(tilt)`.
  /// Rectangular tray: vertices are mapped through [homography] into the
  /// rectified metric plane, then shoelace gives cm2 directly (AGENTS.md §6.1).
  double areaCm2FromPolygon(List<Point2D> polygon) {
    if (polygon.length < 3) return 0.0;

    final transform = homography;
    if (transform != null) {
      final rectified = polygon.map(transform.transform).toList();
      return shoelaceArea(rectified).abs();
    }

    final tiltRad = tiltDeg * (math.pi / 180.0);
    final cosTilt = math.cos(tiltRad);
    final safeCos = cosTilt > 0.05 ? cosTilt : 0.05;
    return shoelaceArea(polygon).abs() * cmPerPx * cmPerPx / safeCos;
  }

  /// Signed shoelace area of a closed polygon (px2, or cm2 if the points are metric).
  static double shoelaceArea(List<Point2D> polygon) {
    if (polygon.length < 3) return 0.0;
    var sum = 0.0;
    for (var i = 0; i < polygon.length; i++) {
      final current = polygon[i];
      final next = polygon[(i + 1) % polygon.length];
      sum += current.x * next.y - next.x * current.y;
    }
    return 0.5 * sum;
  }

  @override
  String toString() =>
      'PlateGeometry(kind: $kind, cmPerPx: $cmPerPx, tiltDeg: $tiltDeg°, source: $source, conflict: $conflict)';
}
