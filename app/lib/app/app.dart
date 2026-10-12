import 'package:flutter/material.dart';

/// The app's MaterialApp shell (Section 4: app/app.dart).
///
/// Navigation (go_router), locale and theme live here. The router
/// itself is under lib/app/router/ and the shell under lib/app/shell/.
///
/// TODO(M1): wire go_router with the onboarding redirect guard.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '{{APP_NAME}}',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // Follow the system by default; manual override in settings (M1).
      themeMode: ThemeMode.system,
      // TODO(M1): localizationsDelegates + supportedLocales (en, hi, pa)
      // TODO(M1): routerConfig: appRouter
      home: const _PlaceholderHome(),
    );
  }
}

/// Temporary placeholder until M1 screens exist.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('{{APP_NAME}} — M0 foundation'),
      ),
    );
  }
}
