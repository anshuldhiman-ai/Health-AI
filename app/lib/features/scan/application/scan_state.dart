import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Scan flow state. SAMPLE predictions for the UI v0; the real ones
/// arrive from the on-device LiteRT model behind the M2 inference
/// isolate (Section 8.7, ADR 0004). Shapes here are the contract the
/// recogniser must satisfy.
class ScanPrediction {
  const ScanPrediction({
    required this.label,
    required this.confidence,
  });

  final String label;

  /// 0..1 model confidence.
  final double confidence;

  int get percent => (confidence * 100).round();
}

class ServingOption {
  const ServingOption({
    required this.label,
    required this.lowKcal,
    required this.highKcal,
  });

  final String label;
  final int lowKcal;
  final int highKcal;
}

class ScanSession {
  const ScanSession({
    required this.topMatches,
    required this.servings,
    required this.selectedMatch,
    required this.selectedServing,
  });

  final List<ScanPrediction> topMatches;
  final List<ServingOption> servings;
  final int selectedMatch;
  final int selectedServing;

  /// Calories always shown as a RANGE (Section 8.1: portion error
  /// dominates class error; never a single confident number).
  ServingOption get chosenServing => servings[selectedServing];
  ScanPrediction get chosenPrediction => topMatches[selectedMatch];
}

/// Sample state for the result sheet (values from ref_ui.png).
final sampleScanSessionProvider = StateProvider<ScanSession>((ref) {
  return const ScanSession(
    topMatches: [
      ScanPrediction(label: 'Paneer Butter Masala + Rice', confidence: 0.92),
      ScanPrediction(label: 'Chole Bhature', confidence: 0.78),
      ScanPrediction(label: 'Veg Biryani', confidence: 0.72),
    ],
    servings: [
      ServingOption(label: '1 Katori', lowKcal: 320, highKcal: 380),
      ServingOption(label: '1 Bowl', lowKcal: 430, highKcal: 520),
      ServingOption(label: '1 Piece', lowKcal: 210, highKcal: 260),
    ],
    selectedMatch: 0,
    selectedServing: 0,
  );
});
