import 'dart:async';

import 'package:app/app/app.dart';
import 'package:app/app/log_store.dart';
import 'package:app/core/error/app_log.dart';
import 'package:app/data/local_storage.dart';
import 'package:app/data/preferences/goal_kind_controller.dart';
import 'package:app/data/preferences/body_metrics_controller.dart';
import 'package:app/data/preferences/sleep_controller.dart';
import 'package:app/data/preferences/theme_mode_controller.dart';
import 'package:app/data/preferences/water_controller.dart';
import 'package:app/domain/entities/hydration.dart';
import 'package:app/domain/entities/nutrition_targets.dart';
import 'package:app/app/router.dart';
import 'package:app/domain/entities/sleep_record.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Entry point. Init order per Section 4:
/// keystore -> DB -> model integrity check -> runApp.
///
/// The full bootstrap lands with the M1 data layer (ADR 0003);
/// [bootstrap] is kept as the single, ordered init path so those
/// steps slot in front of [runApp] without touching [main] again.
///
/// Every step is individually guarded and the whole bootstrap is
/// wrapped: a storage failure must never stop the app from painting a
/// first frame. Without a frame the OS keeps showing the launch
/// background, which is what a "black screen" is.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installErrorWidgetBuilder();
  await runAppGuarded(() async {
    runApp(const StartupSplashApp());
    unawaited(bootstrap());
  });
}

/// Ordered initialisation. Never puts heavy work on the UI isolate
/// before first frame; blocking steps (DB warm-up, model checks) will
/// be async and gated on a minimal splash once the data layer exists.
Future<void> bootstrap() async {
  try {
    final loaded = await Future.wait<Object>([
      _guard(loadSavedThemeMode, ThemeMode.system, 'theme'),
      _guard(loadSavedGoalKind, GoalKind.lose, 'goal'),
      _guard(loadSavedWater, HydrationState.empty(DateTime.now()), 'water'),
      _guard(loadSavedBodyMetrics, const BodyMetrics(), 'bodyMetrics'),
      _guard(loadSavedSleep, SleepState.empty(), 'sleep'),
      _guard(loadSavedDayLog, DayLog(), 'dayLog'),
    ]);
    final water = loaded[2] as HydrationState;
    final metrics = loaded[3] as BodyMetrics;
    final sleep = loaded[4] as SleepState;
    final dayLog = loaded[5] as DayLog;
    try {
      final welcomeSeen = await AppLocalStorage.readBool('welcome.seen.v1') ?? false;
      if (metrics.onboardingCompleted ||
          welcomeSeen ||
          metrics.heightCm != null ||
          metrics.weightKg != null ||
          dayLog.state.isNotEmpty ||
          water.glasses > 0 ||
          sleep.records.isNotEmpty) {
        markWelcomeSeen();
      }
    } catch (_) {}
    _runApp(
      overrides: [
        initialThemeModeProvider.overrideWithValue(loaded[0] as ThemeMode),
        initialGoalKindProvider.overrideWithValue(loaded[1] as GoalKind),
        initialWaterProvider.overrideWithValue(loaded[2] as HydrationState),
        initialBodyMetricsProvider.overrideWithValue(loaded[3] as BodyMetrics),
        initialSleepProvider.overrideWithValue(loaded[4] as SleepState),
        dayLogProvider.overrideWith((ref) => loaded[5] as DayLog),
      ],
    );
  } catch (error, stack) {
    // Last resort: show the failure on screen rather than leaving the
    // launch background up forever.
    AppLog.record(error, stack);
    runApp(const StartupErrorScreen());
  }
}

void _runApp({required List<Override> overrides}) {
  runApp(ProviderScope(overrides: overrides, child: const App()));
}

/// Run one startup load, falling back to [fallback] if it throws or
/// takes too long.
///
/// A broken preferences file or an unavailable keystore must not stop
/// the first frame: without this the app stays on the launch
/// background, which reads as a black screen. The timeout covers the
/// other failure mode — a plugin call that never returns, which would
/// hang the bootstrap just as effectively as a throw.
Future<T> _guard<T>(Future<T> Function() load, T fallback, String label) async {
  try {
    return await load().timeout(const Duration(seconds: 15));
  } catch (error, stack) {
    AppLog.record(error, stack);
    debugPrint('[bootstrap] "$label" failed, using fallback');
    return fallback;
  }
}
