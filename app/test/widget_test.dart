import 'package:app/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Smoke test: welcome gates the shell, onboarding profile setup lands on
/// Today dashboard, and navigation destinations are reachable.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Welcome gates the shell; Get Started lands on Today', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);

    // Welcome first
    expect(find.text('Get Started'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Profile Setup step
    expect(find.text('Personalize Your Profile'), findsOneWidget);
    final continueButton = find.widgetWithText(FilledButton, 'Continue to Dashboard');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();



    // Nav destinations
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Diary'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);

    // The dashboard renders the calorie ring hero
    expect(find.text('Remaining'), findsOneWidget);
  });
}
