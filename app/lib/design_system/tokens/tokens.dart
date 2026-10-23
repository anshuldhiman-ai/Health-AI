/// Design tokens (Section 10.2–10.4), tuned to the approved reference
/// (ref_ui.png): forest-green brand, turmeric energy, sky-blue water,
/// indigo sleep, soft-shadow cards on a warm mist canvas.
///
/// All values are a PROPOSAL until the brand name exists. They live
/// here so a rebrand is a one-folder change.
///
/// Every text/background pair must pass WCAG AA (4.5:1 body, 3:1
/// large text and graphics) — enforced by unit tests. No colour alone
/// conveys state (R14).
library;

import 'package:flutter/material.dart';

/// Semantic colour tokens, light and dark.
abstract final class AppColors {
  AppColors._();

  // --- light theme (sampled from the approved reference) ---
  static const light = AppColorScheme._(
    canvas: Color(0xFFF3F7F2),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    ink: Color(0xFF16211C),
    inkMuted: Color(0xFF6B7A72),
    primary: Color(0xFF0D5C3A),
    primaryWash: Color(0xFFE6F3EC),
    accent: Color(0xFFE5B25D),
    accentWash: Color(0xFFFBF6EC),
    accentSoft: Color(0xFFF3D28E),
    gold: Color(0xFFD4AF37),
    goldWash: Color(0xFFFBF6EC),
    deepSage: Color(0xFF4A6B5D),
    obsidian: Color(0xFF121614),
    water: Color(0xFF48ABD9),
    sleep: Color(0xFF5860AF),
    macroProtein: Color(0xFF0D5C3A),
    macroCarbs: Color(0xFFE5B25D),
    macroFat: Color(0xFF4FA576),
    danger: Color(0xFFB3392A),
    line: Color(0xFFE9EFEA),
  );

  // --- dark theme ---
  static const dark = AppColorScheme._(
    canvas: Color(0xFF0E1613),
    surface: Color(0xFF16211C),
    surfaceRaised: Color(0xFF1D2A24),
    ink: Color(0xFFEAEFEB),
    inkMuted: Color(0xFF9FB0A7),
    primary: Color(0xFF4CC18F),
    primaryWash: Color(0xFF1B3A2C),
    accent: Color(0xFFF0B429),
    accentWash: Color(0xFF3A2C12),
    accentSoft: Color(0xFF8A6A1F),
    gold: Color(0xFFE5B25D),
    goldWash: Color(0xFF332914),
    deepSage: Color(0xFF729986),
    obsidian: Color(0xFF0E1613),
    water: Color(0xFF6FC1E6),
    sleep: Color(0xFF8A90D8),
    macroProtein: Color(0xFF4CC18F),
    macroCarbs: Color(0xFFF0B429),
    macroFat: Color(0xFF8ED6B0),
    danger: Color(0xFFF08A7B),
    line: Color(0xFF27332D),
  );
}

/// The semantic colour scheme.
///
/// `accent` (turmeric) is for energy/calorie highlights — fills and
/// graphics only, never small text. `primary` (forest) is for main
/// actions and selected states. `water`/`sleep` are data-viz icon
/// colours only (never body text).
class AppColorScheme {
  const AppColorScheme._({
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.ink,
    required this.inkMuted,
    required this.primary,
    required this.primaryWash,
    required this.accent,
    required this.accentWash,
    required this.accentSoft,
    required this.gold,
    required this.goldWash,
    required this.deepSage,
    required this.obsidian,
    required this.water,
    required this.sleep,
    required this.macroProtein,
    required this.macroCarbs,
    required this.macroFat,
    required this.danger,
    required this.line,
  });

  /// Smooth token interpolation for the light/dark theme transition.
  factory AppColorScheme.lerp(AppColorScheme a, AppColorScheme b, double t) {
    return AppColorScheme._(
      canvas: Color.lerp(a.canvas, b.canvas, t)!,
      surface: Color.lerp(a.surface, b.surface, t)!,
      surfaceRaised: Color.lerp(a.surfaceRaised, b.surfaceRaised, t)!,
      ink: Color.lerp(a.ink, b.ink, t)!,
      inkMuted: Color.lerp(a.inkMuted, b.inkMuted, t)!,
      primary: Color.lerp(a.primary, b.primary, t)!,
      primaryWash: Color.lerp(a.primaryWash, b.primaryWash, t)!,
      accent: Color.lerp(a.accent, b.accent, t)!,
      accentWash: Color.lerp(a.accentWash, b.accentWash, t)!,
      accentSoft: Color.lerp(a.accentSoft, b.accentSoft, t)!,
      gold: Color.lerp(a.gold, b.gold, t)!,
      goldWash: Color.lerp(a.goldWash, b.goldWash, t)!,
      deepSage: Color.lerp(a.deepSage, b.deepSage, t)!,
      obsidian: Color.lerp(a.obsidian, b.obsidian, t)!,
      water: Color.lerp(a.water, b.water, t)!,
      sleep: Color.lerp(a.sleep, b.sleep, t)!,
      macroProtein: Color.lerp(a.macroProtein, b.macroProtein, t)!,
      macroCarbs: Color.lerp(a.macroCarbs, b.macroCarbs, t)!,
      macroFat: Color.lerp(a.macroFat, b.macroFat, t)!,
      danger: Color.lerp(a.danger, b.danger, t)!,
      line: Color.lerp(a.line, b.line, t)!,
    );
  }

  /// App background (warm mist green).
  final Color canvas;

  /// Cards, sheets.
  final Color surface;

  /// Modals, popovers.
  final Color surfaceRaised;

  /// Primary text.
  final Color ink;

  /// Secondary text.
  final Color inkMuted;

  /// Main actions, selected states.
  final Color primary;

  /// Tinted backgrounds.
  final Color primaryWash;

  /// Energy / calorie highlight. Fills and graphics only.
  final Color accent;

  /// Cream wash behind energy callouts (estimated-calories card).
  final Color accentWash;

  /// Soft gold for the "left today" chip.
  final Color accentSoft;

  /// Premium gold accent (from ui_design.jpg).
  final Color gold;

  /// Soft gold wash behind premium elements.
  final Color goldWash;

  /// Deep sage green (from ui_design.jpg).
  final Color deepSage;

  /// Obsidian dark contrast (from ui_design.jpg).
  final Color obsidian;

  /// Water data-viz only.
  final Color water;

  /// Sleep data-viz only.
  final Color sleep;

  /// Macro data-viz: protein / carbs / fat. Tuned per theme for
  /// contrast on cards and chart legends.
  final Color macroProtein;
  final Color macroCarbs;
  final Color macroFat;

  /// Errors, destructive actions.
  final Color danger;

  /// Hairline borders, dividers.
  final Color line;

  /// Emerald gradient for primary buttons and banners.
  LinearGradient get emeraldGradient => LinearGradient(
    colors: [primary, Color.lerp(primary, const Color(0xFF1B8255), 0.5)!],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gold gradient for premium badges and accents.
  LinearGradient get goldGradient => LinearGradient(
    colors: [gold, const Color(0xFFC59A3F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Calorie ring multi-tone vibrant gradient (from ui_design2.jpg).
  List<Color> get calorieRingColors => [
    const Color(0xFF0D5C3A),
    const Color(0xFF28B781),
    const Color(0xFFE5B25D),
    const Color(0xFFEE6A50),
    const Color(0xFF8A58D6),
    const Color(0xFF0D5C3A),
  ];
}

/// Typography scale (Section 10.3): Plus Jakarta Sans (OFL), bundled
/// under assets/fonts. Weights 400/500/600/700/800.
///
/// Tabular figures are set on every style so nutrition numbers align
/// in columns.
abstract final class AppTypography {
  AppTypography._();

  static const family = 'PlusJakartaSans';

  static const _tabular = [FontFeature.tabularFigures()];

  /// Hero greeting / big numbers ("Good morning!", "482").
  static const hero = TextStyle(
    fontFamily: family,
    fontSize: 30,
    height: 38 / 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    fontFeatures: _tabular,
  );

  /// Big counter numbers inside rings (34/800).
  static const counter = TextStyle(
    fontFamily: family,
    fontSize: 34,
    height: 40 / 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    fontFeatures: _tabular,
  );

  /// Medium emphasis values ("1,420 avg kcal/day", names) 20/800.
  static const value20 = TextStyle(
    fontFamily: family,
    fontSize: 20,
    height: 27 / 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    fontFeatures: _tabular,
  );

  /// Estimated-calories figure (18/800).
  static const value18 = TextStyle(
    fontFamily: family,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w800,
    fontFeatures: _tabular,
  );

  /// Screen titles ("Diary", "Insights") and sheet titles (24/800).
  static const titleL = TextStyle(
    fontFamily: family,
    fontSize: 24,
    height: 30 / 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    fontFeatures: _tabular,
  );

  /// Card titles / section headers (15/700).
  static const titleM = TextStyle(
    fontFamily: family,
    fontSize: 15,
    height: 21 / 15,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );

  /// List item titles (15/700).
  static const itemTitle = TextStyle(
    fontFamily: family,
    fontSize: 15,
    height: 21 / 15,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );

  /// Small titles in list rows (14/700).
  static const itemS = TextStyle(
    fontFamily: family,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );

  /// Body / description (14/400).
  static const bodyM = TextStyle(
    fontFamily: family,
    fontSize: 14,
    height: 21 / 14,
    fontWeight: FontWeight.w400,
    fontFeatures: _tabular,
  );

  /// Small labels, captions (12/500).
  static const caption = TextStyle(
    fontFamily: family,
    fontSize: 12,
    height: 17 / 12,
    fontWeight: FontWeight.w500,
    fontFeatures: _tabular,
  );

  /// Buttons / chips (14/700).
  static const label = TextStyle(
    fontFamily: family,
    fontSize: 14,
    height: 19 / 14,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );

  /// Nav labels (11/600).
  static const navLabel = TextStyle(
    fontFamily: family,
    fontSize: 11,
    height: 15 / 11,
    fontWeight: FontWeight.w600,
    fontFeatures: _tabular,
  );
}

/// Spacing on the 4pt grid (Section 10.4).
abstract final class AppSpacing {
  AppSpacing._();

  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x12 = 48.0;

  /// Screen horizontal padding.
  static const screenPadding = 20.0;
}

/// Radii by hierarchy, not one radius for everything (Section 10.4).
abstract final class AppRadii {
  AppRadii._();

  static const input = Radius.circular(10); // inputs, small tiles
  static const card = Radius.circular(20); // cards
  static const sheet = Radius.circular(28); // bottom sheets, hero surfaces
  static const button = Radius.circular(14); // primary buttons
  static const pill = Radius.circular(999); // chips, segmented controls
}

/// Motion tokens (Section 10.8). Durations 120–240 ms, standard
/// easing. Respect system "reduce motion".
abstract final class AppMotion {
  AppMotion._();

  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 240);

  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeInOutCubic;
}

/// Soft diffusion shadows from the approved reference: cards lift on
/// very low-alpha black, never harsh borders.
abstract final class AppShadows {
  AppShadows._();

  /// Cards and tiles.
  ///
  /// The reference surfaces are FLAT white on the mist canvas with a
  /// hairline edge - a heavy shadow made every card read as a floating
  /// blob. This is now barely-there depth; the hairline border in
  /// [AppCard] does the defining.
  static const card = [
    BoxShadow(
      color: Color(0x0A10201A), // 4% ink
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// Flat chrome: the bottom nav bar lifts upward.
  static const nav = [
    BoxShadow(
      color: Color(0x1410201A), // 8% ink
      blurRadius: 24,
      offset: Offset(0, -2),
    ),
  ];

  /// The centre scan button.
  static const scanButton = [
    BoxShadow(
      color: Color(0x2410201A), // 14% ink
      blurRadius: 12,
      offset: Offset(0, 5),
    ),
  ];
}
