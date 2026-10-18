/// Design tokens (Section 10.2–10.4).
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
///
/// The palette deliberately avoids the common "cream + terracotta"
/// and "near-black + acid green" looks. No decorative gradients; the
/// only gradient allowed is inside the calorie ring / scan highlight.
abstract final class AppColors {
  AppColors._();

  // --- light theme ---
  static const light = AppColorScheme._(
    canvas: Color(0xFFF4F6F3),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    ink: Color(0xFF13201C),
    inkMuted: Color(0xFF55645E),
    primary: Color(0xFF1E6B57),
    primaryWash: Color(0xFFDDEFE8),
    accent: Color(0xFFD99A00),
    danger: Color(0xFFB3392A),
    line: Color(0xFFDCE3DF),
  );

  // --- dark theme ---
  static const dark = AppColorScheme._(
    canvas: Color(0xFF0D1412),
    surface: Color(0xFF141E1B),
    surfaceRaised: Color(0xFF1B2723),
    ink: Color(0xFFE8F0EC),
    inkMuted: Color(0xFF9DB0A8),
    primary: Color(0xFF5CC4A3),
    primaryWash: Color(0xFF16322B),
    accent: Color(0xFFF0B429),
    danger: Color(0xFFF08A7B),
    line: Color(0xFF25332E),
  );
}

/// The semantic colour scheme.
///
/// `accent` (turmeric) is for energy/calorie highlights — fills and
/// graphics only, never small text. `primary` (moss) is for main
/// actions and selected states.
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
    required this.danger,
    required this.line,
  });

  /// App background.
  final Color canvas;

  /// Cards, sheets.
  final Color surface;

  /// Modals, popovers (light adds a hairline border via [line]).
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

  /// Errors, destructive actions.
  final Color danger;

  /// Hairline borders, dividers.
  final Color line;
}

/// Typography scale (Section 10.3).
///
/// One UI family, bundled as an asset (OFL-licensed, tabular
/// figures verified with [FontFeature.tabularFigures]).
/// Weights 400/500/600/700 only. Sentence case everywhere.
///
/// Tabular figures are set on every style so nutrition numbers
/// align in columns (the bundled font must support this — verify
/// in M0).
abstract final class AppTypography {
  AppTypography._();

  static const _tabular = [FontFeature.tabularFigures()];

  // sp / line-height pairs.
  static const display = TextStyle(
    fontSize: 36,
    height: 42 / 36,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );
  static const titleL = TextStyle(
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );
  static const titleM = TextStyle(
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w600,
    fontFeatures: _tabular,
  );
  static const bodyL = TextStyle(
    fontSize: 17,
    height: 26 / 17,
    fontWeight: FontWeight.w400,
    fontFeatures: _tabular,
  );
  static const bodyM = TextStyle(
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w400,
    fontFeatures: _tabular,
  );
  static const label = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
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
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x12 = 48.0;

  /// Screen horizontal padding.
  static const screenPadding = 20.0;
}

/// Radii by hierarchy, not one radius for everything (Section 10.4).
abstract final class AppRadii {
  AppRadii._();

  static const input = Radius.circular(8); // inputs, chips
  static const card = Radius.circular(14); // cards
  static const sheet = Radius.circular(24); // bottom sheets, hero surfaces
  static const pill = Radius.circular(999); // buttons, segmented controls
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

/// Elevation: at most two soft shadow levels, used only for floating
/// elements (bottom sheet, scan button). Depth otherwise comes from
/// tonal surfaces and 1px [AppColorScheme.line] borders.
abstract final class AppElevation {
  AppElevation._();

  static const sheet = 8.0;
  static const fab = 12.0;
}
