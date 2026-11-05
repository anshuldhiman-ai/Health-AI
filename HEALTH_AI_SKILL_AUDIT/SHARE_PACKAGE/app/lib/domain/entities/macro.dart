/// Macro nutrient value object. Pure Dart (R9: domain has no Flutter).
library;

/// Which macro a target/line refers to.
enum MacroKind { protein, carbs, fat }

/// One macro line: current value against its daily target, in grams.
class MacroLine {
  const MacroLine({
    required this.kind,
    required this.value,
    required this.target,
  });

  final MacroKind kind;

  /// Integers only, grams — grams are the exchange unit of the app.
  final int value;
  final int target;

  double get ratio => (value / target).clamp(0.0, 1.0);
}
