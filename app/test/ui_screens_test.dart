import 'dart:io';

import 'package:app/app/app.dart';
import 'package:app/app/router.dart';
import 'package:app/data/preferences/theme_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders each screen to a PNG so the UI can be reviewed as an image
/// (a widget test asserting "no exception" cannot tell you that a
/// screen looks cheap).
///
/// The PNGs are a VISUAL BASELINE for humans, not a CI gate: font
/// rasterising differs per platform, so a byte comparison would fail
/// on CI for the wrong reason. The test therefore only runs when asked:
///
///   RUN_UI_GOLDENS=1 flutter test test/ui_screens_test.dart --update-goldens
///
/// then open test/goldens/ui/*.png to review the result.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final runGoldens = Platform.environment['RUN_UI_GOLDENS'] == '1';

  setUpAll(() async {
    // Real font, or every glyph renders as a filled box. The app's own
    // Plus Jakarta Sans plus Material Icons (bundled by
    // `uses-material-design: true`, cached by the Flutter SDK).
    final fontDir = Directory(
      Platform.environment['FLUTTER_ROOT'] ?? r'F:\Flutter\flutter',
    );
    final fonts = {
      'PlusJakartaSans': 'assets/fonts/PlusJakartaSans-Regular.ttf',
      'MaterialIcons':
          '${fontDir.path}\\bin\\cache\\artifacts\\material_fonts\\'
          'materialicons-regular.otf',
    };
    for (final entry in fonts.entries) {
      final loader = FontLoader(entry.key);
      final file = File(entry.value);
      if (!file.existsSync()) continue;
      loader.addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
      await loader.load();
    }
  });

  /// Bounded settle. `pumpAndSettle` never returns on a screen with a
  /// blinking text cursor (the search screen), so pump a fixed number
  /// of frames instead.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    await settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/ui/$name.png'),
    );
  }

  /// Images are decoded asynchronously and the test harness does not
  /// decode them on its own, so they would render as empty boxes.
  /// Precache them so the screenshots match the real app.
  Future<void> precacheImages(WidgetTester tester) async {
    await tester.runAsync(() async {
      for (final asset in const [
        'assets/brand/avatar.png',
        'assets/brand/meal_thali.png',
      ]) {
        final provider = AssetImage(asset);
        await precacheImage(provider, tester.element(find.byType(MaterialApp)));
      }
    });
    await settle(tester);
  }

  Future<void> open(
    WidgetTester tester,
    String route, {
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialThemeModeProvider.overrideWithValue(themeMode)],
        child: const App(),
      ),
    );
    await settle(tester);
    if (route != '/welcome') {
      appRouter.go(route);
      await settle(tester);
    }
    await precacheImages(tester);
  }

  testWidgets('welcome', (tester) async {
    await open(tester, '/welcome');
    await shoot(tester, 'welcome');
  }, skip: !runGoldens);

  testWidgets('today', (tester) async {
    await open(tester, '/today');
    await shoot(tester, 'today');
  }, skip: !runGoldens);

  testWidgets('diary', (tester) async {
    await open(tester, '/diary');
    await shoot(tester, 'diary');
  }, skip: !runGoldens);

  testWidgets('insights', (tester) async {
    await open(tester, '/insights');
    await shoot(tester, 'insights');
  }, skip: !runGoldens);

  testWidgets('profile', (tester) async {
    await open(tester, '/profile');
    await shoot(tester, 'profile');
  }, skip: !runGoldens);

  testWidgets('search', (tester) async {
    await open(tester, '/search?day=0&meal=lunch');
    await shoot(tester, 'search');
  }, skip: !runGoldens);

  testWidgets('today in dark mode', (tester) async {
    await open(tester, '/today', themeMode: ThemeMode.dark);
    await shoot(tester, 'today_dark');
  }, skip: !runGoldens);
}
