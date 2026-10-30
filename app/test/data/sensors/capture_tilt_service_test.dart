import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/sensors/capture_tilt_service.dart';
import 'package:app/domain/entities/plate_geometry.dart';

void main() {
  group('CaptureTiltService - IMU Tilt Math', () {
    test('pointing straight down (0, 0, -9.81) yields 0.0° tilt', () {
      const reading = AccelerometerReading(x: 0.0, y: 0.0, z: -9.81);
      final tilt = CaptureTiltService.calculateTiltFromReading(reading);
      expect(tilt, closeTo(0.0, 1e-3));
    });

    test('horizontal device (0, -9.81, 0) yields 90.0° tilt', () {
      const reading = AccelerometerReading(x: 0.0, y: -9.81, z: 0.0);
      final tilt = CaptureTiltService.calculateTiltFromReading(reading);
      expect(tilt, closeTo(90.0, 1e-3));
    });

    test('slight 15° pitch from vertical calculates correctly', () {
      // For a 15° tilt around x:
      // z = -9.81 * cos(15°), y = 9.81 * sin(15°)
      final reading = AccelerometerReading(
        x: 0.0,
        y: 9.81 * 0.2588190451, // sin(15°)
        z: -9.81 * 0.9659258263, // -cos(15°)
      );
      final tilt = CaptureTiltService.calculateTiltFromReading(reading);
      expect(tilt, closeTo(15.0, 0.1));
    });

    test(
      'warns when tilt exceeds 25° (AGENTS.md §6.1 HUD warning requirement)',
      () {
        expect(CaptureTiltService.isTiltWarning(24.9), isFalse);
        expect(CaptureTiltService.isTiltWarning(25.1), isTrue);
        expect(CaptureTiltService.isTiltWarning(35.0), isTrue);
      },
    );

    test('handles zero/freefall magnitude without throwing', () {
      const freefall = AccelerometerReading(x: 0.0, y: 0.0, z: 0.0);
      final tilt = CaptureTiltService.calculateTiltFromReading(freefall);
      expect(tilt, equals(0.0));
    });
  });

  group('CaptureTiltService - Ellipse Fusion Rule (AGENTS.md §6.1)', () {
    test('fuses when |IMU - Ellipse| <= 8° (0.5 * IMU + 0.5 * Ellipse, conflict = false)', () {
      final fusion = CaptureTiltService.fuse(
        imuTiltDeg: 10.0,
        ellipseTiltDeg: 14.0, // diff = 4° <= 8°
      );

      expect(fusion.source, equals(TiltSource.fused));
      expect(fusion.conflict, isFalse);
      expect(fusion.finalTiltDeg, closeTo(12.0, 1e-4));
      expect(fusion.isTiltWarning, isFalse);
    });

    test('prefers IMU and flags conflict when |IMU - Ellipse| > 8°', () {
      final fusion = CaptureTiltService.fuse(
        imuTiltDeg: 12.0,
        ellipseTiltDeg: 25.0, // diff = 13° > 8°
      );

      expect(fusion.source, equals(TiltSource.imu));
      expect(fusion.conflict, isTrue);
      expect(fusion.finalTiltDeg, closeTo(12.0, 1e-4));
      expect(fusion.isTiltWarning, isFalse);
    });

    test('flags tilt warning when IMU tilt > 25°', () {
      final fusion = CaptureTiltService.fuse(
        imuTiltDeg: 28.0,
        ellipseTiltDeg: 29.0, // diff = 1° <= 8°
      );

      expect(fusion.source, equals(TiltSource.fused));
      expect(fusion.isTiltWarning, isTrue);
      expect(fusion.finalTiltDeg, closeTo(28.5, 1e-4));
    });
  });

  group('CaptureTiltService - Stream Integration with Fake Source', () {
    late StreamController<AccelerometerReading> controller;
    late FakeAccelerometerSource fakeSource;
    late CaptureTiltService service;

    setUp(() {
      controller = StreamController<AccelerometerReading>.broadcast();
      fakeSource = FakeAccelerometerSource(controller.stream);
      service = CaptureTiltService(source: fakeSource);
    });

    tearDown(() async {
      await service.dispose();
      await controller.close();
    });

    test('tracks current tilt from live sensor stream', () async {
      expect(service.currentTiltDeg, equals(0.0));

      controller.add(const AccelerometerReading(x: 0.0, y: 0.0, z: -9.81));
      await pumpEventQueue();
      expect(service.currentTiltDeg, closeTo(0.0, 1e-3));
      expect(service.hasWarning, isFalse);

      // Simulate phone tilting to 30°
      controller.add(
        const AccelerometerReading(
          x: 0.0,
          y: 4.905, // 9.81 * sin(30°)
          z: -8.4957, // -9.81 * cos(30°)
        ),
      );
      await pumpEventQueue();
      expect(service.currentTiltDeg, closeTo(30.0, 0.1));
      expect(service.hasWarning, isTrue);
    });
  });
}
