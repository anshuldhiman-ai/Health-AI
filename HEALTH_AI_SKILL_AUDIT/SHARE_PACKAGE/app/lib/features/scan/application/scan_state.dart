import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/domain/entities/dish_info.dart';
import 'package:app/domain/entities/food_portion.dart';
import 'package:app/features/scan/application/food_recognizer.dart';

/// One model candidate, joined with its catalog row.
class ScanPrediction {
  const ScanPrediction({required this.dish, required this.confidence});

  final DishInfo dish;

  /// 0..1 model confidence.
  final double confidence;

  String get label => dish.name;

  int get percent => (confidence * 100).round();
}

/// The confirmed-scan contract the result sheet renders. Built only
/// from a real [RecognitionOutput] + the bundled catalog.
class ScanSession {
  const ScanSession({
    required this.topMatches,
    required this.servings,
    required this.selectedMatch,
    required this.selectedServing,
    required this.uncertain,
    required this.usedTta,
    required this.photo,
    required this.latencyMs,
    this.isFood = true,
  });

  final List<ScanPrediction> topMatches;
  final List<FoodPortion> servings;
  final int selectedMatch;
  final int selectedServing;

  /// Model was not confident enough to log without confirmation.
  final bool uncertain;

  /// False when the photo probably contains no dish at all (a keyboard,
  /// a pet, a wall). The camera UI checks this before opening the result
  /// sheet: a non-food photo must never reach a "Confirm" button.
  final bool isFood;

  /// The flip-TTA fallback ran.
  final bool usedTta;

  /// The captured photo (shown in the sheet header).
  final Uint8List photo;

  final int latencyMs;

  /// Calories always shown as a RANGE (Section 8.1: portion error
  /// dominates class error; never a single confident number).
  FoodPortion get chosenServing => servings[selectedServing];
  ScanPrediction get chosenPrediction => topMatches[selectedMatch];

  ScanSession selectMatch(int index) {
    final dish = topMatches[index].dish;
    return ScanSession(
      topMatches: topMatches,
      servings: portionOptionsFor(dish),
      selectedMatch: index,
      selectedServing: 0,
      uncertain: uncertain,
      usedTta: usedTta,
      photo: photo,
      latencyMs: latencyMs,
      isFood: isFood,
    );
  }

  ScanSession selectServing(int index) => ScanSession(
    topMatches: topMatches,
    servings: servings,
    selectedMatch: selectedMatch,
    selectedServing: index,
    uncertain: uncertain,
    usedTta: usedTta,
    photo: photo,
    latencyMs: latencyMs,
    isFood: isFood,
  );
}

/// Build a session from the recognizer output. Labels the catalog does
/// not know are dropped (should never happen when labels.json and the
/// catalog share the generator).
ScanSession scanSessionFrom({
  required RecognitionOutput output,
  required DishCatalog catalog,
  required Uint8List photo,
}) {
  final matches = <ScanPrediction>[
    for (final score in output.top)
      // A label the catalog has no row for still gets shown (as a
      // placeholder): dropping it silently hides a correct answer, and
      // if EVERY candidate were dropped the scan would fail outright.
      ScanPrediction(
        dish: catalog.lookup(score.label),
        confidence: score.confidence,
      ),
  ];
  if (matches.isEmpty) {
    throw const RecognitionException('No known dish was recognised.');
  }

  return ScanSession(
    topMatches: matches,
    servings: portionOptionsFor(matches.first.dish),
    selectedMatch: 0,
    selectedServing: 0,
    uncertain: output.uncertain,
    usedTta: output.usedTta,
    photo: photo,
    latencyMs: output.latencyMs,
    isFood: output.isFood,
  );
}

/// The in-flight scan result. Null until a scan completes *in the
/// current visit to the camera*.
///
/// The camera screen owns this: it clears the session on entry and again
/// when the result sheet closes. Without that, a prediction from an
/// earlier scan survives in the provider and shows up as a detection
/// pill the next time the camera opens, reading as if the app had
/// already recognised a dish it has not seen.
final scanSessionProvider = StateProvider<ScanSession?>((ref) => null);
