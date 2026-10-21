import 'package:app/app/router.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/data/preferences/theme_mode_controller.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
