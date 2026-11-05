import 'dart:math' as math;

import 'package:app/core/error/result.dart';
import 'package:app/domain/entities/plate_geometry.dart';

/// Pure Dart, deterministic service for plate geometry and scale calculation (AGENTS.md §5.3, §6.1).
///
/// Implements:
/// - Round plate: Ellipse fitting (RANSAC + algebraic least-squares refit).
/// - Scale calculation: cm/px = D / (2a).
/// - Tilt calculation: theta = arccos(b / a).
/// - IMU tilt fusion with 8° conflict threshold.
class PlateGeometryCalculator {
  const PlateGeometryCalculator._();

  /// Calculates plate geometry for a round plate from its outer contour points.
  ///
  /// Rejects contour if fewer than 5 points or if inlier ratio < 0.6.
  static Result<PlateGeometry> calculateRoundPlate({
    required List<Point2D> contour,
    required double plateDiameterCm,
    double? imuTiltDeg,
    int ransacIterations = 100,
    double inlierThreshold = 0.18,
  }) {
    if (contour.length < 5) {
      return const Err(
        Failure(
          FailureKind.invalidInput,
          'Contour requires at least 5 points for ellipse fitting',
        ),
      );
    }
    if (plateDiameterCm <= 0) {
      return const Err(
        Failure(
          FailureKind.invalidInput,
          'Plate diameter must be strictly positive',
        ),
      );
    }

    final ellipse = _fitEllipseRansac(
      contour: contour,
      iterations: ransacIterations,
      threshold: inlierThreshold,
    );

    if (ellipse == null || ellipse.inlierRatio < 0.60) {
      return Err(
        Failure(
          FailureKind.invalidInput,
          'Insufficient contour inliers for reliable plate ellipse fit '
          '(inliers: ${(ellipse?.inlierRatio ?? 0.0) * 100}%, required >= 60%)',
        ),
      );
    }

    final a = ellipse.a;
    final b = ellipse.b;
    if (a <= 0 || b <= 0) {
      return const Err(
        Failure(
          FailureKind.invalidInput,
          'Fitted ellipse axes must be strictly positive',
        ),
      );
    }

    // Metric scale s (cm/px) along un-foreshortened semi-major axis (AGENTS.md §6.1)
    final cmPerPx = plateDiameterCm / (2.0 * a);

    // Ellipse tilt from vertical: theta_ell = arccos(b / a)
    final ratio = (b / a).clamp(0.0, 1.0);
    final ellipseTiltDeg = math.acos(ratio) * (180.0 / math.pi);

    // IMU Sensor Fusion (§6.1)
    double finalTiltDeg;
    TiltSource source;
    bool conflict = false;

    if (imuTiltDeg != null) {
      final diff = (imuTiltDeg - ellipseTiltDeg).abs();
      if (diff <= 8.0) {
        // Fused: 0.5 * theta_imu + 0.5 * theta_ell
        finalTiltDeg = 0.5 * imuTiltDeg + 0.5 * ellipseTiltDeg;
        source = TiltSource.fused;
        conflict = false;
      } else {
        // Discrepancy > 8°: Prefer IMU, flag geometry conflict
        finalTiltDeg = imuTiltDeg;
        source = TiltSource.imu;
        conflict = true;
      }
    } else {
      finalTiltDeg = ellipseTiltDeg;
      source = TiltSource.ellipse;
      conflict = false;
    }

    return Ok(
      PlateGeometry(
        kind: PlateKind.round,
        cmPerPx: cmPerPx,
        tiltDeg: finalTiltDeg,
        source: source,
        conflict: conflict,
        plateDiameterCm: plateDiameterCm,
        ellipse: ellipse,
      ),
    );
  }

  /// Calculates plate geometry for a rectangular tray from its four outer
  /// corners (AGENTS.md §6.1).
  ///
  /// [corners] must be ordered clockwise around the tray starting at the
  /// top-left corner (TL, TR, BR, BL) as seen in the image. The resulting
  /// [PlateGeometry.homography] maps image pixels into a rectified metric
  /// plane where the tray spans `[0, trayWidthCm] x [0, trayHeightCm]`, so
  /// region areas are read directly with [PlateGeometry.areaCm2FromPolygon].
  static Result<PlateGeometry> calculateRectangularTray({
    required List<Point2D> corners,
    required double trayWidthCm,
    required double trayHeightCm,
  }) {
    if (corners.length != 4) {
      return const Err(
        Failure(
          FailureKind.invalidInput,
          'Tray geometry requires exactly 4 corners (TL, TR, BR, BL)',
        ),
      );
    }
    if (trayWidthCm <= 0 || trayHeightCm <= 0) {
      return const Err(
        Failure(
          FailureKind.invalidInput,
          'Tray width and height must be strictly positive',
        ),
      );
    }

    final quadAreaPx = PlateGeometry.shoelaceArea(corners).abs();
    if (quadAreaPx < 1e-6) {
      return const Err(
        Failure(
          FailureKind.invalidInput,
          'Tray corners are coincident or collinear; no area to rectify',
        ),
      );
    }
    if (!_isConvexQuad(corners)) {
      return const Err(
        Failure(
          FailureKind.invalidInput,
          'Tray corners must be convex and ordered TL, TR, BR, BL',
        ),
      );
    }

    final rectified = [
      const Point2D(0.0, 0.0),
      Point2D(trayWidthCm, 0.0),
      Point2D(trayWidthCm, trayHeightCm),
      Point2D(0.0, trayHeightCm),
    ];

    final matrix = _solveHomography(corners, rectified);
    if (matrix == null) {
      return const Err(
        Failure(
          FailureKind.invalidInput,
          'Could not solve the tray homography; corners are degenerate',
        ),
      );
    }

    // Summary scale across the tray (exact per-point scale varies under
    // perspective, which the homography absorbs).
    final cmPerPx = math.sqrt((trayWidthCm * trayHeightCm) / quadAreaPx);

    return Ok(
      PlateGeometry(
        kind: PlateKind.rectangular,
        cmPerPx: cmPerPx,
        tiltDeg: 0.0,
        source: TiltSource.homography,
        conflict: false,
        homography: TrayHomography(matrix),
        trayWidthCm: trayWidthCm,
        trayHeightCm: trayHeightCm,
      ),
    );
  }

  /// Solves the 8-parameter projective transform mapping [src] (image px)
  /// onto [dst] (metric cm), with h33 fixed to 1 (DLT, AGENTS.md §6.1).
  static List<double>? _solveHomography(List<Point2D> src, List<Point2D> dst) {
    final ata = List.generate(8, (_) => List<double>.filled(8, 0.0));
    final atb = List<double>.filled(8, 0.0);

    for (var i = 0; i < 4; i++) {
      final x = src[i].x;
      final y = src[i].y;
      final u = dst[i].x;
      final v = dst[i].y;

      ata[2 * i] = [x, y, 1.0, 0.0, 0.0, 0.0, -u * x, -u * y];
      atb[2 * i] = u;

      ata[2 * i + 1] = [0.0, 0.0, 0.0, x, y, 1.0, -v * x, -v * y];
      atb[2 * i + 1] = v;
    }

    final solution = _solveLinear(ata, atb);
    if (solution == null) return null;
    return [...solution, 1.0];
  }

  /// True when the four [corners] are convex and ordered around the tray.
  static bool _isConvexQuad(List<Point2D> corners) {
    var orientation = 0;
    for (var i = 0; i < 4; i++) {
      final p0 = corners[i];
      final p1 = corners[(i + 1) % 4];
      final p2 = corners[(i + 2) % 4];
      final cross =
          (p1.x - p0.x) * (p2.y - p1.y) - (p1.y - p0.y) * (p2.x - p1.x);
      if (cross.abs() < 1e-9) return false; // collinear edge
      final sign = cross > 0 ? 1 : -1;
      if (orientation == 0) {
        orientation = sign;
      } else if (sign != orientation) {
        return false; // reflex vertex: bow-tie or wrong corner order
      }
    }
    return true;
  }

  /// Fits an ellipse using RANSAC with algebraic least squares on inliers.
  static FittedEllipse? _fitEllipseRansac({
    required List<Point2D> contour,
    required int iterations,
    required double threshold,
  }) {
    final n = contour.length;
    if (n < 5) return null;

    // Normalization: shift by center of mass to prevent numerical instability
    double sumX = 0;
    double sumY = 0;
    for (final p in contour) {
      sumX += p.x;
      sumY += p.y;
    }
    final mx = sumX / n;
    final my = sumY / n;

    final u = List<double>.filled(n, 0);
    final v = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      u[i] = contour[i].x - mx;
      v[i] = contour[i].y - my;
    }

    List<int> bestInliers = [];
    final rng = math.Random(1337);

    // If contour is clean and small, a direct fit on all points is often already optimal
    final directFitCoeffs = _fitConic(u, v, List.generate(n, (i) => i));
    if (directFitCoeffs != null) {
      final directInliers = _findInliers(u, v, directFitCoeffs, threshold);
      if (directInliers.length >= (0.6 * n)) {
        bestInliers = directInliers;
      }
    }

    if (bestInliers.length < (0.6 * n)) {
      for (var iter = 0; iter < iterations; iter++) {
        // Pick 5 distinct points
        final sample = <int>{};
        while (sample.length < 5) {
          sample.add(rng.nextInt(n));
        }

        final coeffs = _fitConic(u, v, sample.toList());
        if (coeffs == null) continue;

        final inliers = _findInliers(u, v, coeffs, threshold);
        if (inliers.length > bestInliers.length) {
          bestInliers = inliers;
          if (bestInliers.length >= (0.95 * n)) break;
        }
      }
    }

    if (bestInliers.length < 5) return null;

    // Refit using all inliers
    final refitCoeffs = _fitConic(u, v, bestInliers);
    if (refitCoeffs == null) return null;

    final geom = _extractEllipseParameters(refitCoeffs, mx, my);
    if (geom == null) return null;

    return FittedEllipse(
      cx: geom.cx,
      cy: geom.cy,
      a: geom.a,
      b: geom.b,
      phi: geom.phi,
      inlierRatio: bestInliers.length / n,
    );
  }

  /// Solves A u^2 + B uv + C v^2 + D u + E v = 1 via 5x5 linear least squares.
  static List<double>? _fitConic(
    List<double> u,
    List<double> v,
    List<int> indices,
  ) {
    if (indices.length < 5) return null;

    // Normal equations: (M^T M) * coeffs = M^T * 1
    // Matrix M row: [u^2, u*v, v^2, u, v]
    final ata = List.generate(5, (_) => List<double>.filled(5, 0.0));
    final atb = List<double>.filled(5, 0.0);

    for (final idx in indices) {
      final ui = u[idx];
      final vi = v[idx];
      final row = [ui * ui, ui * vi, vi * vi, ui, vi];

      for (var r = 0; r < 5; r++) {
        atb[r] += row[r];
        for (var c = 0; c < 5; c++) {
          ata[r][c] += row[r] * row[c];
        }
      }
    }

    final coeffs = _solveLinear(ata, atb);
    if (coeffs == null) return null;

    final A = coeffs[0];
    final B = coeffs[1];
    final C = coeffs[2];

    // Conic must be an ellipse: discriminant B^2 - 4AC < 0
    if ((B * B - 4.0 * A * C) >= 0.0) return null;

    return coeffs;
  }

  /// Calculates points with residual |A u^2 + B uv + C v^2 + D u + E v - 1| < threshold.
  static List<int> _findInliers(
    List<double> u,
    List<double> v,
    List<double> coeffs,
    double threshold,
  ) {
    final A = coeffs[0];
    final B = coeffs[1];
    final C = coeffs[2];
    final D = coeffs[3];
    final E = coeffs[4];

    final inliers = <int>[];
    for (var i = 0; i < u.length; i++) {
      final ui = u[i];
      final vi = v[i];
      final val = A * ui * ui + B * ui * vi + C * vi * vi + D * ui + E * vi;
      if ((val - 1.0).abs() <= threshold) {
        inliers.add(i);
      }
    }
    return inliers;
  }

  /// Extracts center (cx, cy), semi-axes (a, b) and rotation (phi) from conic coefficients.
  static ({double cx, double cy, double a, double b, double phi})?
  _extractEllipseParameters(List<double> coeffs, double mx, double my) {
    final A = coeffs[0];
    final B = coeffs[1];
    final C = coeffs[2];
    final D = coeffs[3];
    final E = coeffs[4];

    // Derivative: [2A B; B 2C] [uc; vc] = [-D; -E]
    final det = 4.0 * A * C - B * B;
    if (det <= 0.0) return null;

    final uc = (-2.0 * C * D + B * E) / det;
    final vc = (-2.0 * A * E + B * D) / det;

    final cx = mx + uc;
    final cy = my + vc;

    // Shift conic to centered coordinate system:
    // A(x-uc)^2 + B(x-uc)(y-vc) + C(y-vc)^2 = F
    final F = 1.0 + A * uc * uc + B * uc * vc + C * vc * vc + D * uc + E * vc;
    if (F <= 0.0) return null;

    // 2x2 quadratic form [A/F, B/(2F); B/(2F), C/F]
    final qA = A / F;
    final qB = B / (2.0 * F);
    final qC = C / F;

    // Eigenvalues of 2x2 symmetric matrix
    final trace = qA + qC;
    final disc = math.sqrt((qA - qC) * (qA - qC) + 4.0 * qB * qB);
    final lambda1 = 0.5 * (trace - disc);
    final lambda2 = 0.5 * (trace + disc);

    if (lambda1 <= 0.0 || lambda2 <= 0.0) return null;

    final axis1 = 1.0 / math.sqrt(lambda1);
    final axis2 = 1.0 / math.sqrt(lambda2);

    // Semi-major axis a is the larger of the two
    final a = math.max(axis1, axis2);
    final b = math.min(axis1, axis2);

    // Orientation angle phi
    double phi;
    if (qB.abs() < 1e-9) {
      phi = (qA <= qC) ? 0.0 : math.pi / 2.0;
    } else {
      phi = 0.5 * math.atan2(2.0 * qB, qA - qC);
    }

    return (cx: cx, cy: cy, a: a, b: b, phi: phi);
  }

  /// Solves the n x n linear system A x = b via Gaussian elimination with
  /// partial pivoting; returns null if A is singular.
  static List<double>? _solveLinear(List<List<double>> A, List<double> b) {
    final n = b.length;
    final M = List.generate(
      n,
      (r) => List<double>.generate(n + 1, (c) => c < n ? A[r][c] : b[r]),
    );

    for (var i = 0; i < n; i++) {
      // Find pivot
      var maxRow = i;
      var maxVal = M[i][i].abs();
      for (var r = i + 1; r < n; r++) {
        if (M[r][i].abs() > maxVal) {
          maxVal = M[r][i].abs();
          maxRow = r;
        }
      }

      if (maxVal < 1e-12) return null; // Singular matrix

      if (maxRow != i) {
        final tmp = M[i];
        M[i] = M[maxRow];
        M[maxRow] = tmp;
      }

      // Eliminate below
      for (var r = i + 1; r < n; r++) {
        final factor = M[r][i] / M[i][i];
        for (var c = i; c <= n; c++) {
          M[r][c] -= factor * M[i][c];
        }
      }
    }

    // Back substitution
    final x = List<double>.filled(n, 0.0);
    for (var i = n - 1; i >= 0; i--) {
      var sum = M[i][n];
      for (var c = i + 1; c < n; c++) {
        sum -= M[i][c] * x[c];
      }
      x[i] = sum / M[i][i];
    }

    return x;
  }
}
