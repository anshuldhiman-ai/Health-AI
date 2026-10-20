import 'package:app/data/preferences/sleep_controller.dart';
import 'package:app/domain/entities/sleep_record.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/features/sleep/presentation/sleep_screen.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SleepScreen renders week history chart without layout crashes', (
    tester,
  ) async {
    final now = DateTime.now();
    final sampleSleep = SleepState(
      records: {
        SleepRecord(
          date: '2026-10-18',
          bedMinutes: 23 * 60,
          wakeMinutes: 7 * 60,
        ).date: SleepRecord(
          date: '2026-10-18',
          bedMinutes: 23 * 60,
          wakeMinutes: 7 * 60,
        ),
        SleepRecord(
          date: '2026-10-19',
          bedMinutes: 22 * 60 + 30,
          wakeMinutes: 6 * 60 + 30,
        ).date: SleepRecord(
          date: '2026-10-19',
          bedMinutes: 22 * 60 + 30,
          wakeMinutes: 6 * 60 + 30,
        ),
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialSleepProvider.overrideWithValue(sampleSleep),
        ],
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
}
