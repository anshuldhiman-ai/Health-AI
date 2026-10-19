import 'package:app/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke test for the app shell (M1 UI v0): router shells into the
/// Today dashboard, localisation resolves (R13), nav destinations.
void main() {
  testWidgets('App builds into the Today dashboard shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    // Nav destinations from the ARBs — proves R13 l10n wiring end to
    // end (no hard-coded string in the widgets).
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Diary'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);

    // The dashboard renders the calorie ring hero.
    expect(find.text('Remaining'), findsOneWidget);
  });
}
