import 'package:app/app/log_store.dart';
import 'package:app/app/router.dart';
import 'package:app/core/error/app_log.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/components/brand_mark.dart';
import 'package:app/data/preferences/theme_mode_controller.dart';
import 'package:app/data/preferences/water_controller.dart';
import 'package:app/data/preferences/sleep_controller.dart';
import 'package:app/data/preferences/body_metrics_controller.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Painted immediately while local stores are read in parallel.
///
/// The saved appearance choice is not known yet (reading it is what this
/// splash is covering for), so it follows the system brightness. It must
/// not be hard-wired to light: a dark-mode user would get a full white
/// flash on every cold start.
class StartupSplashApp extends StatelessWidget {
  const StartupSplashApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ThemeMode.system,
    home: const _StartupSplash(),
  );
}

class _StartupSplash extends StatefulWidget {
  const _StartupSplash();

  @override
  State<_StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<_StartupSplash>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..forward();

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColors = isDark
        ? const [Color(0xFF06140D), Color(0xFF0D281C), Color(0xFF06140D)]
        : const [Color(0xFFF2F8F4), Color(0xFFE4F2E9), Color(0xFFF7FBF8)];

    final mintGlow = isDark ? const Color(0xFF4CC18F) : const Color(0xFF0D5C3A);
    final accentMint = isDark
        ? const Color(0xFF6FE2AE)
        : const Color(0xFF10B981);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bgColors,
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _entranceController,
              _pulseController,
            ]),
            builder: (context, _) {
              final pulse = _pulseController.value;
              final glowAlpha = 0.25 + 0.20 * pulse;
              final glowSpread = 2.0 + 4.0 * pulse;

              return Center(
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _entranceController,
                    curve: Curves.easeOut,
                  ),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.90, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _entranceController,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 3),
                          // Hero Brand Disc with Neon Aura
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer pulsing neon aura ring
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentMint.withValues(
                                        alpha: glowAlpha,
                                      ),
                                      blurRadius: 38,
                                      spreadRadius: glowSpread,
                                    ),
                                  ],
                                ),
                              ),
                              // Glassmorphic disc
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.surface,
                                  border: Border.all(
                                    color: accentMint.withValues(
                                      alpha: 0.45 + 0.3 * pulse,
                                    ),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.35 : 0.08,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Center(child: BrandMark(size: 72)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // App Title
                          Text(
                            'Health AI',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Tagline pill with neon border
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: mintGlow.withValues(
                                alpha: isDark ? 0.20 : 0.10,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: accentMint.withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 14,
                                  color: accentMint,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Smarter Nutrition • Healthier You',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: mintGlow,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(flex: 2),

                          // Neon Loading Indicator
                          SizedBox(
                            width: 140,
                            height: 4,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                backgroundColor: accentMint.withValues(
                                  alpha: 0.18,
                                ),
                                valueColor: AlwaysStoppedAnimation(accentMint),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Loading on-device intelligence...',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),

                          const Spacer(flex: 1),

                          // Offline privacy guarantee badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surface.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_rounded,
                                  size: 13,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '100% Offline • Private & Secure',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The app's MaterialApp shell (Section 4: app/app.dart).
///
/// The appearance choice (system/light/dark) comes from the profile
/// settings sheet and animates through [MaterialApp.themeAnimationDuration].
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onInactive: _onBackground,
      onPause: _onBackground,
      onHide: _onBackground,
      onDetach: _onBackground,
    );
  }

  void _onBackground() {
    try {
      ref.read(dayLogProvider.notifier).flush();
    } catch (_) {}
    try {
      ref.read(waterProvider.notifier).flush();
    } catch (_) {}
    try {
      ref.read(sleepProvider.notifier).flush();
    } catch (_) {}
    try {
      ref.read(bodyMetricsProvider.notifier).flush();
    } catch (_) {}
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 420),
      themeAnimationCurve: Curves.easeInOutCubic,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

/// Install the readable error widget for release builds.
///
/// A release build renders a failed widget as a featureless grey box
/// (the message is debug-only), which is indistinguishable from a
/// black screen. Call this from `main()` — NOT from a widget build:
/// the test framework forbids mutating [ErrorWidget.builder] while a
/// test body runs.
void installErrorWidgetBuilder() {
  ErrorWidget.builder = _buildErrorWidget;
}

/// Replace the default grey error box with a readable panel.
Widget _buildErrorWidget(FlutterErrorDetails details) {
  final theme = AppTheme.light();
  final scheme = theme.colorScheme;
  return ColoredBox(
    color: scheme.surface,
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: scheme.error, size: 40),
            const SizedBox(height: 12),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${details.exception}',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

/// A screen that shows the startup failure instead of a blank window.
///
/// Reached only when the whole bootstrap threw. It lists the recorded
/// errors so the failure is diagnosable on-device (a release APK has no
/// debug overlay).
class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.light();
    final scheme = theme.colorScheme;
    final error = lastAppError;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: scheme.error, size: 44),
                  const SizedBox(height: 14),
                  Text(
                    'Health AI could not start',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    error == null
                        ? 'An unknown error occurred during startup.'
                        : '$error',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Details are in the device log (adb logcat). '
                    'Restarting the app usually clears it.',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
