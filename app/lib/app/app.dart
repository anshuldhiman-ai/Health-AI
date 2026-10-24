import 'package:app/app/router.dart';
import 'package:app/core/error/app_log.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/components/brand_mark.dart';
import 'package:app/data/preferences/theme_mode_controller.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Painted immediately while local stores are read in parallel.
class StartupSplashApp extends StatelessWidget {
  const StartupSplashApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    home: const _StartupSplash(),
  );
}

class _StartupSplash extends StatefulWidget {
  const _StartupSplash();

  @override
  State<_StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<_StartupSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: .92, end: 1).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(size: 82),
                const SizedBox(height: 14),
                Text(
                  'Health AI',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
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
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
