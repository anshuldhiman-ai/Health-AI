# Swapping in a new model (checklist)

A new checkpoint means a new class set. The app maps a model output
index to a dish through **two** files, and both must be regenerated
together or every prediction is silently mislabelled:

```
model output index  ->  assets/models/labels.json  ->  assets/nutrition/khana_catalog.json
```

## 1. Train

Training writes `ml/weights/baseline/{best,last}.pt`. The checkpoint
records the class count in its meta:

```bash
python tools/check_checkpoints.py ml/weights/baseline
```

```
best_new3.pt
  epoch       : 9
  num_classes : 239
  model head  : ('classifier.weight', (239, 1280))
```

## 2. Export (this step regenerates labels.json)

```bash
cd ml
python scripts/export_onnx2tf.py \
    --checkpoint weights/baseline/best_new3.pt \
    --splits data/interim/indian_food/manifest_splits.csv \
    --convert \
    --converter-python "$TEMP/ai_export_env/Scripts/python.exe"
```

`--splits` is **not optional** for a new model. It makes the export:

- read the class order from the training splits (the same sorted order
  `scripts/train.py` used),
- fail if the split count does not match the checkpoint's head size,
- write `app/assets/models/labels.json` in that order.

The export also prints the copy command for the `.tflite` asset.

## 3. Copy the model into the app

```bash
cp artifacts/baseline/onnx2tf/baseline_float32.tflite \
   ../app/assets/models/baseline.tflite
```

## 4. Check the catalog covers the new class set

```bash
python tools/check_catalog.py app/assets/models/labels.json
```

```
model classes        : 239
catalog classes      : 258
catalog dishes       : 258
classes not in catalog: 0
classes with no dish : 0

RESULT: catalog covers every model class
```

If it reports missing classes, regenerate the catalog:

```bash
cd ml && python scripts/build_dish_catalog.py
```

The builder merges the curated rows with any rows already in the
shipped catalog, adds the new-dataset extras, and writes a sorted,
de-duplicated class list. It does **not** write `labels.json` (that
comes from the model's splits, step 2).

## 5. Verify

```bash
# model input/output contract, without tensorflow
python tools/tflite_shape.py app/assets/models/baseline.tflite
```
```
  INPUT  : image  shape=[1, 224, 224, 3]
  OUTPUT : logits  shape=[1, 80]
```

The output dimension MUST equal `len(labels.json["classes"])`.

```bash
cd app && flutter test test/model_contract_test.dart
```

This checks, in CI, that:

- every model label exists in the catalog,
- every model label has a dish row (otherwise the scan screen drops
  the prediction),
- the catalog has no duplicate class names,
- the model asset is bundled.

## 6. Build and install

```bash
cd app
flutter build apk --release --target-platform android-arm64
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Common mistakes

| Symptom | Cause |
|---|---|
| Every dish is wrong, but the confidence looks plausible | `labels.json` was not regenerated for the new model |
| The top-3 suggestions are empty for some photos | The class has no row in `khana_catalog.json` |
| `error: splits CSV has N classes but the checkpoint has M` | The splits CSV is from a different training run |
| `error: --num-classes ... != checkpoint meta ...` | A stale checkpoint was picked up |
| The app shows a blank window | See the black-screen notes in `main.dart`; check `adb logcat` for the `AppLog` lines |
