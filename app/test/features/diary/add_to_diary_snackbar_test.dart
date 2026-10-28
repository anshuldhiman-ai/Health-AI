import 'dart:async';
import 'dart:convert';

import 'package:app/app/app.dart';
import 'package:app/app/log_store.dart';
import 'package:app/app/router.dart';
import 'package:app/data/nutrition/dish_catalog.dart';
import 'package:app/domain/entities/dish_info.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Added to dinner." is a transient confirmation with an Undo. Users
/// reported it staying on screen, which is worse than not showing it:
/// it covers the diary and reads as a stuck UI.
///
/// These tests pin the two ways it must go away - on its own after its
/// duration, and immediately when Undo is tapped - on the real screen,
/// not on a toy replica of it.
void main() {
  /// The shipped catalog, read once outside the fake-async zone.
  ///
  /// A widget test runs in `FakeAsync`, where `rootBundle`'s real file
  /// read never completes, so the dish screen would sit on its loading
  /// spinner forever. Loading here and overriding the provider keeps
  /// the test on the real screen with real numbers, without the I/O.
  late DishCatalog catalog;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final raw = await rootBundle.loadString(
      'assets/nutrition/khana_catalog.json',
    );
    catalog = DishCatalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    markWelcomeSeen();
  });

  /// Advances a fixed number of frames.
  ///
  /// NOT `pumpAndSettle`: some screens animate indefinitely while they
  /// load, so settling never returns. `appRouter` is a global that
  /// keeps its location between tests, so a later test can otherwise
  /// start mid-spinner.
  Future<void> pumpFrames(WidgetTester tester, {int frames = 10}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  /// Lands on the dish detail screen for a real catalog dish, opened
  /// for dinner today.
  ///
  /// `/today` first, then `push`: the dish screen pops itself on save,
  /// and popping the only page on the stack trips a go_router assert.
  /// In the app it is always pushed on top of a screen.
  Future<void> openDishDetail(WidgetTester tester, String dishId) async {
    appRouter.go('/today');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dishCatalogProvider.overrideWith((_) async => catalog)],
        child: const App(),
      ),
    );
    await pumpFrames(tester);

    // Not awaited: go_router's push future completes when the pushed
    // route is POPPED, which happens later in each test body.
    unawaited(appRouter.push('/dish/$dishId?meal=dinner&day=0'));
    await pumpFrames(tester);
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

  testWidgets('confirming a dish shows the toast, then it goes by itself', (
    tester,
  ) async {
    await openDishDetail(tester, 'samosa');
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final expected = l10n.addedToast(l10n.mealLabel(MealKind.dinner));

    // The label carries the calorie count, so match on the prefix.
    final addButton = find.textContaining(l10n.addToDiary);
    expect(
      addButton,
      findsOneWidget,
      reason: 'the add button must be reachable on the dish screen',
    );
    await tester.tap(addButton);
    await pumpFrames(tester, frames: 4);

    expect(find.text(expected), findsOneWidget, reason: 'toast should appear');
    expect(find.text(l10n.undo), findsOneWidget);

    // Past its duration plus the exit animation: it must be gone.
    await tester.pump(const Duration(seconds: 4));
    await pumpFrames(tester, frames: 6);

    expect(
      find.byType(SnackBar),
      findsNothing,
      reason: 'the toast must dismiss on its own (no stuck overlay)',
    );

    // And the entry it announced is still logged.
    expect(
      containerOf(tester).read(dayLogProvider.notifier).entriesFor(0),
      hasLength(1),
    );
  });

  testWidgets('Undo removes the entry and clears the toast at once', (
    tester,
  ) async {
    await openDishDetail(tester, 'samosa');
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.textContaining(l10n.addToDiary));
    await pumpFrames(tester);

    // A tap on a widget still mid-entrance misses: the toast only starts
    // rising once the pop transition it was queued behind has finished,
    // which is past 480 ms. A real finger waits far longer than this.
    await tester.tap(find.text(l10n.undo));
    await pumpFrames(tester, frames: 6);

    expect(
      find.byType(SnackBar),
      findsNothing,
      reason: 'tapping Undo must dismiss the toast, not leave it up',
    );
    expect(
      containerOf(tester).read(dayLogProvider.notifier).entriesFor(0),
      isEmpty,
      reason: 'Undo must remove the entry it just logged',
    );
  });

  test('the dish the flow logs is a real catalog row', () {
    expect(catalog.dishes['samosa'], isA<DishInfo>());
  });
}
