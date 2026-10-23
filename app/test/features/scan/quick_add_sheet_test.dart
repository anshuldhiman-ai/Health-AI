import 'dart:convert';

import 'package:app/data/nutrition/dish_catalog.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/domain/entities/dish_info.dart';
import 'package:app/features/scan/presentation/quick_add_sheet.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The camera's manual exit: when the model says "not a food item", or
/// the user already knows the dish, this sheet is how the food gets
/// logged. It must search the same offline catalog the search screen
/// uses and hand the dish id back to its caller.
void main() {
  // Two of the three are quick picks, so "quick picks rendered" and
  // "search ran" cannot be confused for one another.
  const samosa = DishInfo(
    id: 'samosa',
    name: 'Samosa',
    family: 'snacks',
    ingredients: ['Potato', 'Flour'],
    per100g: DishMacros(kcal: 308, protein: 6, carbs: 32, fat: 17),
    servings: [ServingPreset(label: '1 Piece', grams: 60)],
  );
  const toast = DishInfo(
    id: 'toast',
    name: 'Toast',
    family: 'bread',
    ingredients: ['Bread'],
    per100g: DishMacros(kcal: 290, protein: 9, carbs: 52, fat: 4),
    servings: [ServingPreset(label: '1 Slice', grams: 30)],
  );
  const masalaDosa = DishInfo(
    id: 'masala dosa',
    name: 'Masala Dosa',
    family: 'south indian',
    ingredients: ['Rice', 'Potato'],
    per100g: DishMacros(kcal: 168, protein: 4, carbs: 28, fat: 5),
    servings: [ServingPreset(label: '1 Piece', grams: 180)],
  );

  final fakeCatalog = DishCatalog(
    classes: [samosa.id, toast.id, masalaDosa.id],
    dishes: {
      for (final dish in [samosa, toast, masalaDosa]) dish.id: dish,
    },
  );

  /// Opens the sheet through a real modal route, the way the camera
  /// does, and records what it pops.
  Future<List<String?>> openSheet(
    WidgetTester tester, {
    DishCatalog? catalog,
  }) async {
    final popped = <String?>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (catalog != null)
            dishCatalogProvider.overrideWith((_) async => catalog),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () async {
                    final id = await showModalBottomSheet<String>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => const QuickAddSheet(),
                    );
                    popped.add(id);
                  },
                  child: const Text('open sheet'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open sheet'));
    await tester.pumpAndSettle();
    return popped;
  }

  testWidgets('offers quick picks before anything is typed', (tester) async {
    await openSheet(tester, catalog: fakeCatalog);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.quickAddPicks), findsOneWidget);
    // The two picks the fake catalog holds, and not the non-pick.
    expect(find.widgetWithText(ActionChip, 'Samosa'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Toast'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Masala Dosa'), findsNothing);
    // The full catalog is browsable without typing.
    expect(find.widgetWithText(ListTile, 'Masala Dosa'), findsOneWidget);
  });

  testWidgets('typing filters the catalog and picking pops the dish id', (
    tester,
  ) async {
    final popped = await openSheet(tester, catalog: fakeCatalog);

    await tester.enterText(find.byType(TextField), 'dosa');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Masala Dosa'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Samosa'), findsNothing);

    await tester.tap(find.widgetWithText(ListTile, 'Masala Dosa'));
    await tester.pumpAndSettle();

    expect(popped, ['masala dosa']);
    expect(find.byType(QuickAddSheet), findsNothing);
  });

  testWidgets('a quick pick pops its own id', (tester) async {
    final popped = await openSheet(tester, catalog: fakeCatalog);

    await tester.tap(find.widgetWithText(ActionChip, 'Samosa'));
    await tester.pumpAndSettle();

    expect(popped, ['samosa']);
  });

  testWidgets('no match says so instead of showing an empty list', (
    tester,
  ) async {
    await openSheet(tester, catalog: fakeCatalog);

    await tester.enterText(find.byType(TextField), 'zzzzz');
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.quickAddNoMatch), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(find.widgetWithText(ActionChip, 'Samosa'), findsNothing);
  });

  testWidgets('the sheet fits a small screen without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 3, 480 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await openSheet(tester, catalog: fakeCatalog);

    // RenderFlex overflow is reported as a test failure, so reaching
    // here clean is the assertion.
    expect(tester.takeException(), isNull);
    expect(find.byType(QuickAddSheet), findsOneWidget);
  });

  test('every quick pick still exists in the shipped catalog', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final raw = await rootBundle.loadString(
      'assets/nutrition/khana_catalog.json',
    );
    final catalog = DishCatalog.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );

    final missing = [
      for (final id in quickPickIds)
        if (!catalog.dishes.containsKey(id)) id,
    ];
    expect(
      missing,
      isEmpty,
      reason: 'quick picks must resolve to real catalog rows (R7)',
    );
  });
}
