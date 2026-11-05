import 'dart:math' as math;

import 'package:app/domain/entities/plate_geometry.dart';
import 'package:app/domain/services/plate_geometry_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const double plateDiameterCm = 28.0;

  /// Helper: generates N points on an ellipse centered at (cx, cy)
  /// with semi-major axis `a` (pixels) and tilt angle `tiltDeg`.
  /// `b = a * cos(tiltDeg * pi / 180)`.
  List<Point2D> generateSyntheticContour({
    required double a,
    required double tiltDeg,
    double cx = 300.0,
    double cy = 300.0,
    double phi = 0.0,
    int count = 100,
    double noiseStd = 0.5,
    math.Random? rng,
  }) {
    final random = rng ?? math.Random(42);
    final tiltRad = tiltDeg * math.pi / 180.0;
    final b = a * math.cos(tiltRad);
    final points = <Point2D>[];

    for (var i = 0; i < count; i++) {
      final t = 2 * math.pi * i / count;
      // Ellipse standard coordinates
      final x0 = a * math.cos(t);
      final y0 = b * math.sin(t);

      // Rotate by phi
      final xRot = x0 * math.cos(phi) - y0 * math.sin(phi);
      final yRot = x0 * math.sin(phi) + y0 * math.cos(phi);

      // Add noise (Box-Muller)
      final u1 = random.nextDouble().clamp(1e-9, 1.0);
      final u2 = random.nextDouble();
      final z0 = math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
      final z1 = math.sqrt(-2.0 * math.log(u1)) * math.sin(2.0 * math.pi * u2);

      final x = cx + xRot + z0 * noiseStd;
      final y = cy + yRot + z1 * noiseStd;
      points.add(Point2D(x, y));
    }
    return points;
  }

  group('PlateGeometryCalculator - Round Plate Ellipse Fit', () {
    test(
      'Circular plate (tilt = 0°) yields near-zero tilt and accurate scale',
      () {
        final contour = generateSyntheticContour(
          a: 250.0,
          tiltDeg: 0.0,
          noiseStd: 0.5,
        );

        final result = PlateGeometryCalculator.calculateRoundPlate(
          contour: contour,
          plateDiameterCm: plateDiameterCm,
        );

        expect(result.isOk, isTrue);
        final geo = result.valueOrNull!;
        expect(geo.kind, equals(PlateKind.round));
        expect(geo.tiltDeg, lessThan(2.0)); // < 2° error

        // Expected cm/px: 28.0 / (2 * 250.0) = 0.056
        final expectedCmPerPx = plateDiameterCm / (2 * 250.0);
        final scaleError =
            (geo.cmPerPx - expectedCmPerPx).abs() / expectedCmPerPx;
        expect(scaleError, lessThan(0.015)); // <= 1.5% scale error
      },
    );

    test('Tilted plates (15°, 25°, 35°) satisfy scale error <= 1.5% and tilt error <= 2°', () {
      final testTilts = [15.0, 25.0, 35.0];

      for (final targetTilt in testTilts) {
        final contour = generateSyntheticContour(
          a: 260.0,
          tiltDeg: targetTilt,
          phi: 0.25, // rotated in plane
          noiseStd: 0.6,
        );

        final result = PlateGeometryCalculator.calculateRoundPlate(
          contour: contour,
          plateDiameterCm: plateDiameterCm,
        );

        expect(result.isOk, isTrue, reason: 'Failed for tilt $targetTilt°');
        final geo = result.valueOrNull!;

        // Tilt error <= 2°
        final tiltError = (geo.tiltDeg - targetTilt).abs();
        expect(
          tiltError,
          lessThan(2.0),
          reason: 'Tilt error for $targetTilt° was $tiltError°',
        );

        // Scale error <= 1.5%
        final expectedCmPerPx = plateDiameterCm / (2 * 260.0);
        final scaleError =
            (geo.cmPerPx - expectedCmPerPx).abs() / expectedCmPerPx;
        expect(
          scaleError,
          lessThan(0.015),
          reason:
              'Scale error for $targetTilt° was ${(scaleError * 100).toStringAsFixed(2)}%',
        );
      }
    });

    test('Partial contour (< 60% inliers) returns graceful Failure', () {
      // 30 valid points and 70 completely random noise points
      final random = math.Random(123);
      final valid = generateSyntheticContour(
        a: 200.0,
        tiltDeg: 15.0,
        count: 30,
        rng: random,
      );
      final noise = List.generate(
        70,
        (_) => Point2D(random.nextDouble() * 600, random.nextDouble() * 600),
      );
      final mixedContour = [...valid, ...noise]..shuffle(random);

      final result = PlateGeometryCalculator.calculateRoundPlate(
        contour: mixedContour,
        plateDiameterCm: plateDiameterCm,
      );

      expect(result.isErr, isTrue);
    });

    test('Contour with too few points returns graceful Failure', () {
      final fewPoints = [
        const Point2D(100, 100),
        const Point2D(150, 120),
        const Point2D(120, 150),
      ];

      final result = PlateGeometryCalculator.calculateRoundPlate(
        contour: fewPoints,
        plateDiameterCm: plateDiameterCm,
      );

      expect(result.isErr, isTrue);
    });
  });

  group('PlateGeometryCalculator - IMU Fusion Rule (§6.1)', () {
    test('Fuses tilt when |imu - ellipse| <= 8°', () {
      final contour = generateSyntheticContour(
        a: 250.0,
        tiltDeg: 20.0,
        noiseStd: 0.3,
      );

      final result = PlateGeometryCalculator.calculateRoundPlate(
        contour: contour,
        plateDiameterCm: plateDiameterCm,
        imuTiltDeg: 22.0, // difference is ~2°, <= 8°
      );

      expect(result.isOk, isTrue);
      final geo = result.valueOrNull!;
      expect(geo.conflict, isFalse);
      expect(geo.source, equals(TiltSource.fused));
      // fused = 0.5 * imu + 0.5 * ellipse
      expect(geo.tiltDeg, inInclusiveRange(20.0, 22.0));
    });

    test('Sets conflict = true and prefers IMU when |imu - ellipse| > 8°', () {
      final contour = generateSyntheticContour(
        a: 250.0,
        tiltDeg: 10.0,
        noiseStd: 0.3,
      );

      final result = PlateGeometryCalculator.calculateRoundPlate(
        contour: contour,
        plateDiameterCm: plateDiameterCm,
        imuTiltDeg: 25.0, // difference is ~15°, > 8°
      );

      expect(result.isOk, isTrue);
      final geo = result.valueOrNull!;
      expect(geo.conflict, isTrue);
      expect(geo.source, equals(TiltSource.imu));
      expect(geo.tiltDeg, equals(25.0));
    });
  });

  group('PlateGeometry - Area Calculation', () {
    test('Real area accounts for scale squared and 1 / cos(tilt)', () {
      const geo = PlateGeometry(
        kind: PlateKind.round,
        cmPerPx: 0.05, // 1 px = 0.05 cm => 1 px² = 0.0025 cm²
        tiltDeg: 30.0, // cos(30°) = sqrt(3)/2 ≈ 0.866
        source: TiltSource.fused,
        conflict: false,
        plateDiameterCm: 28.0,
      );

      const int pixelCount = 10000;
      final area = geo.areaCm2FromPixels(pixelCount);

      // Area = 10000 * (0.05)^2 / cos(30°) = 25 / 0.866025 ≈ 28.8675 cm²
      expect(area, closeTo(28.8675, 0.1));
    });

    test('Polygon area on a round plate uses shoelace x cm/px^2', () {
      const geo = PlateGeometry(
        kind: PlateKind.round,
        cmPerPx: 0.05,
        tiltDeg: 0.0,
        source: TiltSource.ellipse,
        conflict: false,
        plateDiameterCm: 28.0,
      );

      // 100 x 100 px square = 10000 px2 = 25 cm2 at 0.05 cm/px.
      final square = [
        const Point2D(0, 0),
        const Point2D(100, 0),
        const Point2D(100, 100),
        const Point2D(0, 100),
      ];

      expect(geo.areaCm2FromPolygon(square), closeTo(25.0, 1e-9));
    });
  });

  group('PlateGeometryCalculator - Rectangular Tray Homography (§6.1)', () {
    const double trayWidthCm = 32.0;
    const double trayHeightCm = 24.0;

    // Known camera mapping: metric cm -> image pixels (mild perspective).
    const cameraMatrix = <double>[
      2.0, 0.4, 150.0, //
      0.15, 1.9, 120.0, //
      0.002, 0.001, 1.0, //
    ];

    Point2D project(List<double> h, Point2D p) {
      final w = h[6] * p.x + h[7] * p.y + h[8];
      return Point2D(
        (h[0] * p.x + h[1] * p.y + h[2]) / w,
        (h[3] * p.x + h[4] * p.y + h[5]) / w,
      );
    }

    List<Point2D> trayCornersInImage(List<double> camera) => [
      project(camera, const Point2D(0, 0)),
      project(camera, const Point2D(trayWidthCm, 0)),
      project(camera, const Point2D(trayWidthCm, trayHeightCm)),
      project(camera, const Point2D(0, trayHeightCm)),
    ];

    test('Unwarped tray recovers scale and rectifies corners', () {
      // 10 px per cm, origin at (100, 100).
      final corners = [
        const Point2D(100, 100),
        const Point2D(420, 100),
        const Point2D(420, 340),
        const Point2D(100, 340),
      ];

      final result = PlateGeometryCalculator.calculateRectangularTray(
        corners: corners,
        trayWidthCm: trayWidthCm,
        trayHeightCm: trayHeightCm,
      );

      expect(result.isOk, isTrue);
      final geo = result.valueOrNull!;
      expect(geo.kind, equals(PlateKind.rectangular));
      expect(geo.source, equals(TiltSource.homography));
      expect(geo.cmPerPx, closeTo(0.1, 1e-9));

      final h = geo.homography!;
      expect(h.transform(corners[1]).x, closeTo(trayWidthCm, 1e-9));
      expect(h.transform(corners[1]).y, closeTo(0.0, 1e-9));
      expect(h.transform(corners[2]).x, closeTo(trayWidthCm, 1e-9));
      expect(h.transform(corners[2]).y, closeTo(trayHeightCm, 1e-9));
      expect(h.transform(corners[3]).x, closeTo(0.0, 1e-9));
      expect(h.transform(corners[3]).y, closeTo(trayHeightCm, 1e-9));
    });

    test('Perspective tray recovers interior points to <= 1e-6 cm', () {
      final result = PlateGeometryCalculator.calculateRectangularTray(
        corners: trayCornersInImage(cameraMatrix),
        trayWidthCm: trayWidthCm,
        trayHeightCm: trayHeightCm,
      );

      expect(result.isOk, isTrue);
      final h = result.valueOrNull!.homography!;

      const probes = [
        Point2D(16.0, 12.0),
        Point2D(4.0, 4.0),
        Point2D(28.0, 20.0),
      ];
      for (final probe in probes) {
        final rectified = h.transform(project(cameraMatrix, probe));
        expect(rectified.x, closeTo(probe.x, 1e-6));
        expect(rectified.y, closeTo(probe.y, 1e-6));
      }
    });

    test('Region area under perspective matches the rectified area', () {
      final result = PlateGeometryCalculator.calculateRectangularTray(
        corners: trayCornersInImage(cameraMatrix),
        trayWidthCm: trayWidthCm,
        trayHeightCm: trayHeightCm,
      );
      expect(result.isOk, isTrue);
      final geo = result.valueOrNull!;

      // 16 cm x 8 cm serving on the tray = 128 cm2 rectified.
      const region = [
        Point2D(4.0, 4.0),
        Point2D(20.0, 4.0),
        Point2D(20.0, 12.0),
        Point2D(4.0, 12.0),
      ];
      final imagePolygon = region.map((p) => project(cameraMatrix, p)).toList();

      expect(geo.areaCm2FromPolygon(imagePolygon), closeTo(128.0, 1e-6));
    });

    test('Degenerate corners return graceful Failure', () {
      final invalidDims = PlateGeometryCalculator.calculateRectangularTray(
        corners: [
          const Point2D(100, 100),
          const Point2D(420, 100),
          const Point2D(420, 340),
          const Point2D(100, 340),
        ],
        trayWidthCm: 0.0,
        trayHeightCm: 24.0,
      );
      expect(invalidDims.isErr, isTrue);

      final notFour = PlateGeometryCalculator.calculateRectangularTray(
        corners: [const Point2D(0, 0), const Point2D(10, 0)],
        trayWidthCm: 32.0,
        trayHeightCm: 24.0,
      );
      expect(notFour.isErr, isTrue);

      final collinear = PlateGeometryCalculator.calculateRectangularTray(
        corners: [
          const Point2D(0, 0),
          const Point2D(10, 0),
          const Point2D(20, 0),
          const Point2D(30, 0),
        ],
        trayWidthCm: 32.0,
        trayHeightCm: 24.0,
      );
      expect(collinear.isErr, isTrue);

      // Bow-tie ordering (TL, TR, BL, BR) is not a valid corner sequence.
      final bowTie = PlateGeometryCalculator.calculateRectangularTray(
        corners: [
          const Point2D(100, 100),
          const Point2D(420, 100),
          const Point2D(100, 340),
          const Point2D(420, 340),
        ],
        trayWidthCm: 32.0,
        trayHeightCm: 24.0,
      );
      expect(bowTie.isErr, isTrue);
    });
  });
}
