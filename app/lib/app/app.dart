import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The app's MaterialApp shell (Section 4: app/app.dart).
///
/// Navigation (go_router), locale overrides and further wiring live
/// under lib/app/ as features arrive.
///
/// TODO(M1): wire go_router with the onboarding redirect guard.
/// TODO(M1): manual theme/locale override from settings (system default now).
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _PlaceholderHome(),
    );
  }
}

/// Temporary placeholder until M1 screens exist.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(AppLocalizations.of(context)!.homePlaceholderMessage),
      ),
    );
  }
}
