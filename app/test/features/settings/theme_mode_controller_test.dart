import 'package:app/data/preferences/theme_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('theme mode names round-trip with a system fallback', () {
    expect(themeModeFromName('light'), ThemeMode.light);
    expect(themeModeFromName('dark'), ThemeMode.dark);
    expect(themeModeFromName('system'), ThemeMode.system);
    expect(themeModeFromName(null), ThemeMode.system);
    expect(themeModeFromName('unexpected'), ThemeMode.system);
  });

  test('selecting a mode updates state and persists it', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [initialThemeModeProvider.overrideWithValue(ThemeMode.light)],
    );
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.light);

    await container.read(themeModeProvider.notifier).select(ThemeMode.dark);
    expect(container.read(themeModeProvider), ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(themeModePrefsKey), 'dark');
  });

  test('loadSavedThemeMode reads the stored choice', () async {
    SharedPreferences.setMockInitialValues({themeModePrefsKey: 'dark'});
    expect(await loadSavedThemeMode(), ThemeMode.dark);
  });
}
