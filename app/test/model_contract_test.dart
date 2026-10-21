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

    // The catalog may hold MORE classes than the current model (the
    // catalog covers the whole taxonomy, the model a subset). What
    // matters is that the model's label order is a prefix of the
    // catalog's order, so index -> label -> dish resolves.
    expect(
      catalogClasses.take(labels.length).toList(),
      labels,
      reason: 'catalog class order must match labels.json order',
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
