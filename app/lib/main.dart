import 'package:app/app/app.dart';
import 'package:flutter/material.dart';

/// Entry point. Init order per Section 4:
/// keystore → DB → model integrity check → runApp.
///
/// The full bootstrap lands with the M1 data layer (ADR 0003);
/// [bootstrap] is kept as the single, ordered init path so those
/// steps slot in front of [runApp] without touching [main] again.
///
/// TODO(M1): top-level error guards (Section 5.3): `runZonedGuarded`
/// + `FlutterError.onError` writing ONLY to the local ring-buffer
/// logger (no remote reporting, R2). Requires core/logging.
void main() {
  bootstrap();
}

/// Ordered initialisation. Never puts heavy work on the UI isolate
/// before first frame; blocking steps (DB warm-up, model checks) will
/// be async and gated on a minimal splash once the data layer exists.
void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}
