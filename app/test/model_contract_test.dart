import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// The model contract (R12, ADR 0007).
///
/// The app maps a model output index to a dish name through TWO files:
/// `assets/models/labels.json` and `assets/nutrition/khana_catalog.json`.
/// If the shipped model, the labels and the catalog disagree, every
/// prediction is silently mislabelled - a confident, WRONG dish. That
/// is the failure the user reported, so it is checked in CI.
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
    catalog = jsonDecode(
      File(catalogPath).readAsStringSync(),
    ) as Map<String, dynamic>;
  });

  test('the model asset is bundled', () {
    final model = File(modelPath);
    expect(model.existsSync(), isTrue, reason: '$modelPath is missing');
    expect(model.lengthSync(), greaterThan(1024 * 1024));
  });

  test('every model label has a dish in the catalog', () {
    final dishes = catalog['dishes'] as Map<String, dynamic>;
    for (final label in labels) {
      expect(
        dishes.containsKey(label),
        isTrue,
        reason: 'no dish row for model label "$label"',
      );
    }
  });

  test('the catalog class list matches the model label order', () {
    final catalogClasses = (catalog['classes'] as List<dynamic>).cast<String>();
    expect(
      catalogClasses,
      labels,
      reason: 'the catalog class order must equal the model output order',
    );
  });

  test('the catalog has no duplicate classes', () {
    final catalogClasses = (catalog['classes'] as List<dynamic>).cast<String>();
    expect(
      catalogClasses.length,
      catalogClasses.toSet().length,
      reason: 'duplicate class names make index -> class ambiguous',
    );
  });

  test('the model outputs as many classes as the labels list', () {
    // The TFLite is a flatbuffer: the output tensor's shape is
    // [1, numClasses]. Read the shape straight out of the file so
    // this needs no runtime.
    final bytes = File(modelPath).readAsBytesSync();
    final shape = _outputShape(bytes);
    expect(
      shape,
      labels.length,
      reason:
          'the model outputs $shape classes but labels.json lists '
          '${labels.length} - the app would map every prediction to the '
          'wrong dish',
    );
  });

  test('every dish row has usable nutrition values', () {
    final dishes = catalog['dishes'] as Map<String, dynamic>;
    for (final entry in dishes.entries) {
      final dish = entry.value as Map<String, dynamic>;
      final per100g = dish['per100g'] as Map<String, dynamic>;
      expect(
        (per100g['kcal'] as num).toDouble(),
        greaterThan(0),
        reason: '${entry.key} has no kcal',
      );
      final servings = dish['servings'] as List<dynamic>;
      expect(servings, isNotEmpty, reason: '${entry.key} has no serving');
    }
  });
}

/// Read the output tensor's class count from a TFLite flatbuffer.
///
/// The file starts with the root table offset; the schema puts the
/// subgraphs at field 2, the subgraph's tensors at field 0 and its
/// outputs at field 2. Each tensor's shape is a vector of ints.
int? _outputShape(Uint8List data) {
  final bytes = ByteData.sublistView(data);
  int u32(int off) => bytes.getUint32(off, Endian.little);
  int i32(int off) => bytes.getInt32(off, Endian.little);

  final root = u32(0);

  /// The SLOT of a table field (a uoffset lives there for vectors).
  int fieldSlot(int table, int id) {
    final vtable = table - i32(table);
    final vtableSize = bytes.getUint16(vtable, Endian.little);
    final slot = 4 + id * 2;
    if (slot + 2 > vtableSize) return 0;
    final rel = bytes.getUint16(vtable + slot, Endian.little);
    return rel == 0 ? 0 : table + rel;
  }

  /// A vector field: the slot holds a uoffset to the vector start.
  int? vectorField(int table, int id) {
    final slot = fieldSlot(table, id);
    if (slot == 0) return null;
    return slot + u32(slot);
  }

  // Model.subgraphs -> the first SubGraph.
  final subgraphs = vectorField(root, 2);
  if (subgraphs == null || u32(subgraphs) == 0) return null;
  final subgraph = subgraphs + 4 + u32(subgraphs + 4);

  // SubGraph.outputs -> the first output tensor index.
  final outputs = vectorField(subgraph, 2);
  if (outputs == null || u32(outputs) == 0) return null;
  final outputIndex = i32(outputs + 4);

  // SubGraph.tensors -> that tensor's table.
  final tensors = vectorField(subgraph, 0);
  if (tensors == null) return null;
  final tensor =
      tensors + 4 + 4 * outputIndex + u32(tensors + 4 + 4 * outputIndex);

  // Tensor.shape -> the shape vector; the class count is its last dim.
  final shape = vectorField(tensor, 0);
  if (shape == null) return null;
  final dims = u32(shape);
  if (dims == 0) return null;
  return i32(shape + 4 + 4 * (dims - 1));
}
