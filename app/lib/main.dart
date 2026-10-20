import 'package:app/app/app.dart';
import 'package:app/app/log_store.dart';
import 'package:app/data/preferences/goal_kind_controller.dart';
import 'package:app/data/preferences/sleep_controller.dart';
import 'package:app/data/preferences/theme_mode_controller.dart';
import 'package:app/data/preferences/water_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap();
}

/// Ordered initialisation. Never puts heavy work on the UI isolate
/// before first frame; blocking steps (DB warm-up, model checks) will
/// be async and gated on a minimal splash once the data layer exists.
Future<void> bootstrap() async {
  final initialThemeMode = await loadSavedThemeMode();
  final initialGoalKind = await loadSavedGoalKind();
  final initialWater = await loadSavedWater();
  final initialSleep = await loadSavedSleep();
  final initialDayLog = await loadSavedDayLog();
  runApp(
    ProviderScope(
      overrides: [
        initialThemeModeProvider.overrideWithValue(initialThemeMode),
        initialGoalKindProvider.overrideWithValue(initialGoalKind),
        initialWaterProvider.overrideWithValue(initialWater),
        initialSleepProvider.overrideWithValue(initialSleep),
        dayLogProvider.overrideWith((ref) => initialDayLog),
      ],
      child: const App(),
    ),
  );
}
