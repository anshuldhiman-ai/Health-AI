import 'package:app/data/preferences/sleep_controller.dart';
import 'package:app/domain/entities/sleep_record.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/features/sleep/presentation/sleep_screen.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('SleepScreen renders week history chart without layout crashes', (
    tester,
  ) async {
    final sampleSleep = SleepState(
      records: {
        const SleepRecord(
          date: '2026-10-18',
          bedMinutes: 23 * 60,
          wakeMinutes: 7 * 60,
        ).date: const SleepRecord(
          date: '2026-10-18',
          bedMinutes: 23 * 60,
          wakeMinutes: 7 * 60,
        ),
        const SleepRecord(
          date: '2026-10-19',
          bedMinutes: 22 * 60 + 30,
          wakeMinutes: 6 * 60 + 30,
        ).date: const SleepRecord(
          date: '2026-10-19',
          bedMinutes: 22 * 60 + 30,
          wakeMinutes: 6 * 60 + 30,
        ),
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialSleepProvider.overrideWithValue(sampleSleep)],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SleepScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SleepScreen), findsOneWidget);
  });

  testWidgets(
    'SleepScreen opens Log Sleep bottom sheet and displays time options',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SleepScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Log Sleep"
      final logSleepBtn = find.text('Log Sleep');
      expect(logSleepBtn, findsOneWidget);
      await tester.tap(logSleepBtn);
      await tester.pumpAndSettle();

      // Verify Log Sleep Bottom Sheet contents
      expect(find.text("Log Today's Sleep"), findsOneWidget);
      expect(find.text('Bedtime'), findsOneWidget);
      expect(find.text('Wake-up'), findsOneWidget);
      expect(find.text('Calculated Duration'), findsOneWidget);
      expect(find.text('Save Sleep Record'), findsOneWidget);

      // Tap Save Sleep Record
      final saveBtn = find.text('Save Sleep Record');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));

      // Bottom sheet is dismissed and SleepScreen is visible with updated status
      expect(find.text("Log Today's Sleep"), findsNothing);
      expect(find.byType(SleepScreen), findsOneWidget);
    },
  );
}
