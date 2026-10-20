import 'package:app/data/sensors/step_tracker.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/domain/entities/activity_snapshot.dart';
import 'package:app/features/activity/presentation/activity_screen.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    expect(find.byType(GroupHeader), findsNWidgets(2));
  });
}
