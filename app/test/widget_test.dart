import 'package:app/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke test for the app shell (the M0 published surface).
void main() {
  testWidgets('App builds and homes to the localised placeholder',
      (tester) async {
    await tester.pumpWidget(const App());

    expect(find.byType(MaterialApp), findsOneWidget);
    // The placeholder home message from app_en.arb — proves R13 l10n
    // wiring works end to end (no hard-coded string in the widget).
    expect(
      find.text('Foundation ready. Screens arrive in M1.'),
      findsOneWidget,
    );
  });
}
