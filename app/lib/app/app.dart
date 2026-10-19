import 'package:app/app/router.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The app's MaterialApp shell (Section 4: app/app.dart).
///
/// Locale overrides and theme switching land through the profile
/// settings page (M1); system defaults for now.
///
/// TODO(M1): wire the onboarding redirect guard into [appRouter].
/// TODO(M1): manual theme/locale override from settings (system default now).
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
