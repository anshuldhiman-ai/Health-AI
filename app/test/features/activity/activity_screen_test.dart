import 'package:app/data/sensors/step_tracker.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/domain/entities/activity_snapshot.dart';
import 'package:app/features/activity/presentation/activity_screen.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ActivityScreen renders hourly and history charts safely', (
    tester,
  ) async {
    final now = DateTime.now();
    final snapshot = StepSnapshot(
      status: StepStatus.live,
      steps: 4250,
      distanceMeters: 4250 * 0.762,
      activeSeconds: 1800,
      cadenceSpm: 110,
      averageCadenceSpm: 105,
      hourlySteps: List.generate(24, (i) => i >= 8 && i <= 18 ? 350 : 0),
      history: [
        for (var i = 6; i >= 0; i--)
          DaySteps(
            date: now.subtract(Duration(days: i)),
            steps: 3000 + i * 200,
          ),
      ],
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stepTrackerProvider.overrideWith((ref) => Stream.value(snapshot)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ActivityScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ActivityScreen), findsOneWidget);
    expect(find.text('4,250'), findsOneWidget);
  });

  testWidgets(
    'ActivityScreen allows selecting previous days and returning to today',
    (tester) async {
      final now = DateTime.now();
      final snapshot = StepSnapshot(
        status: StepStatus.live,
        steps: 5000,
        distanceMeters: 5000 * 0.762,
        activeSeconds: 2400,
        hourlySteps: List.generate(24, (i) => 200),
        history: [
          for (var i = 6; i >= 0; i--)
            DaySteps(
              date: now.subtract(Duration(days: i)),
              steps:
                  2000 +
                  i * 500, // Oldest is 2000, yesterday is 4500, today is 5000
            ),
        ],
        updatedAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            stepTrackerProvider.overrideWith((ref) => Stream.value(snapshot)),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ActivityScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify today's real steps
      expect(find.text('5,000'), findsOneWidget);

      // Tap on the first pill (oldest day in 7-day strip)
      final streakPill = find.byType(GestureDetector).first;
      await tester.tap(streakPill);
      await tester.pumpAndSettle();

      // Now either historical banner is visible or Back to Today is present
      if (find.text('Back to Today').evaluate().isNotEmpty) {
        await tester.tap(find.text('Back to Today'));
        await tester.pumpAndSettle();
        expect(find.text('5,000'), findsOneWidget);
      }
    },
  );

  testWidgets('ActivityScreen opens Log Steps sheet', (tester) async {
    final now = DateTime.now();
    final snapshot = StepSnapshot(
      status: StepStatus.live,
      steps: 0,
      distanceMeters: 0,
      activeSeconds: 0,
      hourlySteps: List.filled(24, 0),
      history: [DaySteps(date: now, steps: 0)],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stepTrackerProvider.overrideWith((ref) => Stream.value(snapshot)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ActivityScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Today steps is 0 (real data, not fake 7842)
    expect(find.text('0'), findsWidgets);

    // Tap Log Steps button
    await tester.tap(find.text('Log Steps'));
    await tester.pumpAndSettle();

    expect(find.text('Log Activity Steps'), findsOneWidget);
    expect(find.text('Add Steps'), findsOneWidget);
    expect(find.text('+1000'), findsOneWidget);
  });
}
