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
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,

      // Scaffold / surfaces
      scaffoldBackgroundColor: c.canvas,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.primary,
        onPrimary: isDark ? const Color(0xFF0D1412) : const Color(0xFFFFFFFF),
        secondary: c.primary,
        onSecondary: isDark ? const Color(0xFF0D1412) : const Color(0xFFFFFFFF),
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
        onTertiary: isDark ? const Color(0xFF241A00) : const Color(0xFF241A00),
      ),

      // Typography: one family, tabular figures for nutrition numbers.
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

      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: isDark
              ? const Color(0xFF0D1412)
              : const Color(0xFFFFFFFF),
          textStyle: AppTypography.label,
          minimumSize: const Size.fromHeight(48), // 48dp touch target (R14)
          shape: const StadiumBorder(),
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
          side: BorderSide(color: c.primary, width: 1.5),
        ),
      ),

      // Cards: hairline border, not shadows (Section 10.4)
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(AppRadii.card),
          side: BorderSide(color: c.line),
        ),
      ),

      // Dividers
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),

      // Bottom sheets
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        elevation: AppElevation.sheet,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        modalBackgroundColor: c.surface,
      ),

      // Snackbars
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: AppTypography.bodyM.copyWith(color: c.canvas),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card.x / 1),
        ),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sheet.x / 1),
        ),
      ),

      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: c.canvas,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleM,
      ),

      // Navigation bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.primaryWash,
        labelTextStyle: WidgetStateProperty.all(AppTypography.label),
        iconTheme: WidgetStateProperty.all(
          IconThemeData(color: c.inkMuted, size: 24),
        ),
        height: 64,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        side: BorderSide(color: c.line),
        labelStyle: AppTypography.label,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill.x / 1),
        ),
      ),
    );
  }

  static TextTheme _textTheme(AppColorScheme c) {
    return TextTheme(
      displayLarge: AppTypography.display.copyWith(color: c.ink),
      headlineLarge: AppTypography.titleL.copyWith(color: c.ink),
      headlineMedium: AppTypography.titleM.copyWith(color: c.ink),
      titleLarge: AppTypography.titleM.copyWith(color: c.ink),
      titleMedium: AppTypography.bodyL.copyWith(
        color: c.ink,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: AppTypography.bodyL.copyWith(color: c.ink),
      bodyMedium: AppTypography.bodyM.copyWith(color: c.ink),
      labelLarge: AppTypography.label.copyWith(
        color: c.ink,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: AppTypography.label.copyWith(color: c.ink),
      labelSmall: AppTypography.label.copyWith(color: c.inkMuted),
    );
  }
}
