import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/data/local_storage.dart';

/// Storage key for the saved appearance choice.
const themeModePrefsKey = 'theme_mode';

/// Read once before the first frame so launching in dark mode does not
/// flash the light theme.
Future<ThemeMode> loadSavedThemeMode() async {
  try {
    return themeModeFromName(
      await AppLocalStorage.readString(themeModePrefsKey),
    );
  } catch (_) {
    // Storage unavailable (tests/desktop): fall back to the system.
    return ThemeMode.system;
  }
}

ThemeMode themeModeFromName(String? name) => switch (name) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => ThemeMode.system,
};

/// The value resolved before `runApp`; overridden in `main`.
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

/// System / Light / Dark, persisted locally. No account, no network.
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  Future<void> select(ThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    try {
      await AppLocalStorage.writeString(themeModePrefsKey, mode.name);
    } catch (_) {
      // Persistence is best-effort; the current session still animates.
    }
  }
}
