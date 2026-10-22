import 'dart:io';

import 'package:app/app/app.dart';
import 'package:app/app/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders each screen to a PNG so the UI can be reviewed as an image
/// (a widget test asserting "no exception" cannot tell you that a
/// screen looks cheap).
///
/// Run:  flutter test test/ui_screens_test.dart --update-goldens
/// Then:  open test/goldens/ui/*.png
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Real font, or every glyph renders as a filled box. The app's own
    // Plus Jakarta Sans plus Material Icons (bundled by
    // `uses-material-design: true`, cached by the Flutter SDK).
    final fontDir = Directory(
      Platform.environment['FLUTTER_ROOT'] ?? r'F:\Flutter\flutter',
    );
    for (final entry in {
      'PlusJakartaSans': 'assets/fonts/PlusJakartaSans-Regular.ttf',
      'MaterialIcons':
          '${fontDir.path}\\bin\\cache\\artifacts\\material_fonts\\'
          'materialicons-regular.otf',
    }.entries) {
      final loader = FontLoader(entry.key);
      final file = File(entry.value);
      if (!file.existsSync()) continue;
      loader.addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
      await loader.load();
    }
  });

  Future<void> shoot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
  }

  testWidgets('welcome', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: App()));
    await shoot(tester, 'welcome');
    await precacheImages(tester);
    await shoot(tester, 'welcome');
  });

  testWidgets('today', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();
    appRouter.go('/today');
    await shoot(tester, 'today');
    await precacheImages(tester);
    await shoot(tester, 'today');
  });

  testWidgets('diary', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();
    appRouter.go('/diary');
    await shoot(tester, 'diary');
    await precacheImages(tester);
    await shoot(tester, 'diary');
  });

  testWidgets('insights', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();
    appRouter.go('/insights');
    await shoot(tester, 'insights');
    await precacheImages(tester);
    await shoot(tester, 'insights');
  });

  testWidgets('profile', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();
    appRouter.go('/profile');
    await shoot(tester, 'profile');
    await precacheImages(tester);
    await shoot(tester, 'profile');
  });
}
