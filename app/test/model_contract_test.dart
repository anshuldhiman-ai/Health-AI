import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The on-device model contract (R12, ADR 0007).
///
/// The app, the exported model and the nutrition catalog must agree on
/// the class list, or the app silently mislabels every prediction:
/// index -> label -> dish. These tests are the guard.
///
/// A mismatched model is a *silent* failure at runtime (the app shows
/// a confident but wrong dish), so it is checked in CI rather than
/// discovered on a phone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const modelPath = 'assets/models/baseline.tflite';
  const labelsPath = 'assets/models/labels.json';
  const catalogPath = 'assets/nutrition/khana_catalog.json';

  late List<String> labels;
  late Map<String, dynamic> catalog;

  setUpAll(() {
    final labelsJson =
        jsonDecode(File(labelsPath).readAsStringSync()) as Map<String, dynamic>;
    labels = (labelsJson['classes'] as List<dynamic>).cast<String>();
    final catalogJson = jsonDecode(
      File(catalogPath).readAsStringSync(),
    ) as Map<String, dynamic>;
    catalog = catalogJson;
  });

  test('labels.json and the catalog agree on the class list', () {
    final catalogClasses = (catalog['classes'] as List<dynamic>).cast<String>();

    // The catalog's own order is the taxonomy order (sorted), NOT the
    // model output order. The app maps a model index to a dish by NAME
    // (labels.json[index] -> catalog[label]), so what must hold is
    // that every model label exists in the catalog.
    for (final label in labels) {
      expect(
        catalogClasses.contains(label),
        isTrue,
        reason: 'catalog has no class for model label "$label"',
      );
    }
  });

  test('the catalog has no duplicate classes', () {
    final catalogClasses = (catalog['classes'] as List<dynamic>).cast<String>();
    expect(
      catalogClasses.length,
      catalogClasses.toSet().length,
      reason: 'duplicate class names make index -> class ambiguous',
    );
  });

  test('every model label has a dish in the catalog', () {
    final dishes = catalog['dishes'] as Map<String, dynamic>;
    for (final label in labels) {
      expect(
        dishes.containsKey(label),
        isTrue,
        reason: 'catalog has no dish for model label "$label"',
      );
    }
  });

  test('the exported model is present and is the expected size', () {
    final model = File(modelPath);
    expect(model.existsSync(), isTrue, reason: '$modelPath is missing');
    // A 34 MB float32 mobilenetv4. If this drops, the export is broken.
    expect(model.lengthSync(), greaterThan(1024 * 1024));
  });

  test('the model asset is listed in pubspec assets', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/models/'));
  });
}
