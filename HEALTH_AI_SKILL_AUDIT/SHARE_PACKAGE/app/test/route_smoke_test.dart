import 'package:app/app/app.dart';
import 'package:app/app/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression guard for the release "black screen" bug (Oct 2026).
///
/// The release APK showed nothing at all. Root cause: the app never
/// painted a first frame, so the OS kept the launch background up.
///
/// This test walks every route in the shell and asserts that no
/// exception is raised while building any of them. In release a failed
/// widget renders as an empty grey box, so a build error is the thing
/// that turns into "nothing on screen".
void main() {
  testWidgets('every route builds without raising an exception', (
    tester,
  ) async {
    final errors = <Object>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.exception);
    };

    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    const routes = <String>[
      '/today',
      '/diary',
      '/insights',
      '/profile',
      '/activity',
      '/water',
      '/sleep',
      '/weekly',
    ];

    for (final route in routes) {
      debugPrint('>>> Testing route: $route (errors so far: ${errors.length})');
      appRouter.go(route);
      // Fixed pumps, not pumpAndSettle: the search screen's TextField
      // cursor blinks forever, so pumpAndSettle never returns.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    FlutterError.onError = previousOnError;
    expect(errors, isEmpty, reason: 'route build raised: $errors');
  });
}
