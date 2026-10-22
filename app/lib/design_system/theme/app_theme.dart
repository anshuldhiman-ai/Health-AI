import 'package:flutter/material.dart';

import 'package:app/design_system/tokens/tokens.dart';

/// Light and dark [ThemeData] built from tokens (Section 3.1).
///
/// Theme knows nothing about food, users or models — only tokens.
abstract final class AppTheme {
  AppTheme._();

  static ThemeData light() => _base(Brightness.light, AppColors.light);

  static ThemeData dark() => _base(Brightness.dark, AppColors.dark);

  static ThemeData _base(Brightness brightness, AppColorScheme c) {
    final isDark = brightness == Brightness.dark;
    final onPrimary = isDark
        ? const Color(0xFF0B1A14)
        : const Color(0xFFFFFFFF);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: [AppTokensExtension(c)],

      // Scaffold / surfaces
      scaffoldBackgroundColor: c.canvas,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.primary,
        onPrimary: onPrimary,
        secondary: c.primary,
        onSecondary: onPrimary,
        error: c.danger,
        onError: isDark ? const Color(0xFF1B0E0C) : const Color(0xFFFFFFFF),
        surface: c.surface,
        onSurface: c.ink,
        surfaceContainerHighest: c.primaryWash,
        onSurfaceVariant: c.inkMuted,
        outline: c.line,
        outlineVariant: c.line,
        shadow: Colors.transparent,
        scrim: const Color(0x8013201C),
        inverseSurface: c.ink,
        onInverseSurface: c.canvas,
        inversePrimary: c.primaryWash,
        tertiary: c.accent,
        onTertiary: const Color(0xFF241A00),
      ),

      // Typography: one family (bundled Plus Jakarta Sans), tabular
      // figures for nutrition numbers.
      textTheme: _textTheme(c),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(AppRadii.input),
          borderSide: BorderSide(color: c.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(AppRadii.input),
          borderSide: BorderSide(color: c.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(AppRadii.input),
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(AppRadii.input),
          borderSide: BorderSide(color: c.danger, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x3,
        ),
      ),

      // Buttons: 52dp tall, rounded rectangle (not a stadium). The
      // reference uses a 14 radius - a full pill reads as a toy.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: onPrimary,
          textStyle: AppTypography.label,
          minimumSize: const Size.fromHeight(52), // 52dp touch target (R14)
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(AppRadii.button),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: AppTypography.label,
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: AppTypography.label,
          minimumSize: const Size.fromHeight(48),
          shape: const StadiumBorder(),
          side: BorderSide(color: c.line, width: 1.5),
        ),
      ),

      // Cards: soft shadow, no border (reference look)
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: const Color(0x0F10201A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(AppRadii.card),
        ),
      ),

      // Dividers: hairlines
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),

      // Bottom sheets
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: AppRadii.sheet),
        ),
        modalBackgroundColor: c.surface,
      ),

      // Snackbars
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: AppTypography.bodyM.copyWith(color: c.canvas),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(AppRadii.card),
        ),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(AppRadii.sheet),
        ),
      ),

      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: c.canvas,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleL.copyWith(color: c.ink),
      ),

      // Chips (defaults; screens override selection colours)
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        side: BorderSide(color: c.line),
        labelStyle: AppTypography.label.copyWith(color: c.ink),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
        shape: const StadiumBorder(),
      ),
    );
  }

  static TextTheme _textTheme(AppColorScheme c) {
    return TextTheme(
      displayLarge: AppTypography.hero.copyWith(color: c.ink),
      headlineLarge: AppTypography.titleL.copyWith(color: c.ink),
      headlineMedium: AppTypography.counter.copyWith(color: c.ink),
      headlineSmall: AppTypography.value20.copyWith(color: c.ink),
      titleLarge: AppTypography.titleL.copyWith(color: c.ink),
      titleMedium: AppTypography.itemTitle.copyWith(color: c.ink),
      titleSmall: AppTypography.itemS.copyWith(color: c.ink),
      bodyLarge: AppTypography.bodyM.copyWith(
        color: c.ink,
        fontSize: 16,
        height: 24 / 16,
      ),
      bodyMedium: AppTypography.bodyM.copyWith(color: c.ink),
      labelLarge: AppTypography.label.copyWith(color: c.ink),
      labelMedium: AppTypography.caption.copyWith(color: c.inkMuted),
      labelSmall: AppTypography.caption.copyWith(
        color: c.inkMuted,
        fontSize: 11,
        height: 15 / 11,
      ),
    );
  }
}

/// Carries the raw token scheme on [ThemeData] so screens can reach
/// colours outside [ColorScheme] (water/sleep data-viz, cream washes).
class AppTokensExtension extends ThemeExtension<AppTokensExtension> {
  const AppTokensExtension(this.scheme);

  final AppColorScheme scheme;

  @override
  AppTokensExtension copyWith({AppColorScheme? scheme}) =>
      AppTokensExtension(scheme ?? this.scheme);

  @override
  AppTokensExtension lerp(ThemeExtension<AppTokensExtension>? other, double t) {
    if (other is! AppTokensExtension) return this;
    return AppTokensExtension(AppColorScheme.lerp(scheme, other.scheme, t));
  }
}

/// `context.appColors.primaryWash` etc.
extension AppTokensX on BuildContext {
  AppColorScheme get appColors =>
      Theme.of(this).extension<AppTokensExtension>()!.scheme;
}
