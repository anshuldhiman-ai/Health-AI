import 'dart:async';
import 'dart:math' as math;

import 'package:app/domain/entities/plate_geometry.dart';

/// Raw 3-axis accelerometer reading in m/s².
class AccelerometerReading {
  const AccelerometerReading({
    required this.x,
    required this.y,
    required this.z,
    this.timestamp,
  });

  final double x;
  final double y;
  final double z;
  final DateTime? timestamp;

  @override
  String toString() => 'AccelerometerReading(x: $x, y: $y, z: $z)';
}

/// Result of fusing optical ellipse tilt with IMU accelerometer tilt (AGENTS.md §6.1).
class TiltFusionResult {
  const TiltFusionResult({
    required this.finalTiltDeg,
    required this.source,
    required this.conflict,
    required this.isTiltWarning,
  });

  final double finalTiltDeg;
  final TiltSource source;
  final bool conflict;
  final bool isTiltWarning;

  @override
  String toString() =>
      'TiltFusionResult(tilt: ${finalTiltDeg.toStringAsFixed(1)}°, source: $source, conflict: $conflict, warning: $isTiltWarning)';
}

/// Abstract stream source for accelerometer events (allowing fake injection for offline tests).
abstract class AccelerometerStreamSource {
  Stream<AccelerometerReading> get accelerometerEvents;
}

/// Test double implementing [AccelerometerStreamSource] with an arbitrary stream.
class FakeAccelerometerSource implements AccelerometerStreamSource {
  FakeAccelerometerSource(this._stream);

  final Stream<AccelerometerReading> _stream;

  @override
  Stream<AccelerometerReading> get accelerometerEvents => _stream;
}

/// Service providing real-time device tilt measurement from accelerometer and
/// fusing it with visual plate ellipse geometry (AGENTS.md §5.3, §6.1).
class CaptureTiltService {
  CaptureTiltService({required AccelerometerStreamSource source})
    : _source = source {
    _subscription = _source.accelerometerEvents.listen(_handleReading);
  }

  final AccelerometerStreamSource _source;
  StreamSubscription<AccelerometerReading>? _subscription;

  double _currentTiltDeg = 0.0;
  final _tiltController = StreamController<double>.broadcast();

  /// Latest calculated tilt angle in degrees from the optical axis to gravity (0° = vertical).
  double get currentTiltDeg => _currentTiltDeg;

  /// Whether current tilt exceeds the recommended 25° threshold (AGENTS.md §6.1).
  bool get hasWarning => isTiltWarning(_currentTiltDeg);

  /// Broadcast stream of updated tilt degrees.
  Stream<double> get tiltStream => _tiltController.stream;

  /// Calculates the camera tilt angle relative to gravity from an accelerometer reading.
  ///
  /// Back camera optical axis points along -Z. When pointed straight down at a table,
  /// gravity acceleration vector opposes camera normal (z ≈ -9.8 m/s²).
  static double calculateTiltFromReading(AccelerometerReading reading) {
    final norm = math.sqrt(
      (reading.x * reading.x) +
          (reading.y * reading.y) +
          (reading.z * reading.z),
    );

    if (norm < 1e-4) {
      return 0.0;
    }

    // cos(theta) = (-z) / norm
    final cosTheta = (-reading.z / norm).clamp(-1.0, 1.0);
    return math.acos(cosTheta) * (180.0 / math.pi);
  }

  /// Evaluates whether camera tilt exceeds HUD guidance limit (25° per AGENTS.md §6.1).
  static bool isTiltWarning(double tiltDeg) => tiltDeg > 25.0;

  /// Fuses IMU tilt with contour ellipse tilt using the locked decision rule (AGENTS.md §6.1):
  /// - If |theta_imu - theta_ell| <= 8°: theta = 0.5*theta_imu + 0.5*theta_ell, conflict = false.
  /// - Else: theta = theta_imu, conflict = true.
  static TiltFusionResult fuse({
    required double imuTiltDeg,
    required double ellipseTiltDeg,
  }) {
    final diff = (imuTiltDeg - ellipseTiltDeg).abs();
    final warning = isTiltWarning(imuTiltDeg);

    if (diff <= 8.0) {
      return TiltFusionResult(
        finalTiltDeg: (0.5 * imuTiltDeg) + (0.5 * ellipseTiltDeg),
        source: TiltSource.fused,
        conflict: false,
        isTiltWarning: warning,
      );
    } else {
      return TiltFusionResult(
        finalTiltDeg: imuTiltDeg,
        source: TiltSource.imu,
        conflict: true,
        isTiltWarning: warning,
      );
    }
  }

  void _handleReading(AccelerometerReading reading) {
    _currentTiltDeg = calculateTiltFromReading(reading);
    if (!_tiltController.isClosed) {
      _tiltController.add(_currentTiltDeg);
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _tiltController.close();
  }
}
