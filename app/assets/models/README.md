# On-device food classifier assets

`baseline.tflite` is generated; `labels.json` is source and must stay in
sync with it. Model binaries under `app/assets/models/` are gitignored
(`app/assets/models/*.tflite`) and must not be committed.

> The full swap procedure (train -> export -> copy -> verify) is in
> `docs/model_swap.md` at the repo root. The short version: a new model
> means a new class set, so `labels.json` **and**
> `assets/nutrition/khana_catalog.json` must be regenerated together.

## Model contract

- **Input**: `float32[1,224,224,3]`, NHWC, RGB, raw `0..1`.
  ImageNet normalization (`(x - mean) / std`) is baked into the graph;
  do **not** normalize again in Dart.
- **Output**: `float32[1,N]` raw logits, where `N` is the number of
  classes in `labels.json`. The app applies temperature scaling and
  softmax; the graph must not contain either.
- **Preprocessing**: resize the shorter side to 255, then center-crop 224
  (torchvision eval transform), matching `preprocessFoodPhoto`.
- **Labels**: output index `i` maps to `labels.json["classes"][i]`, and
  that name must have a row in `assets/nutrition/khana_catalog.json`.
  Keep the file's order exactly; do not sort it.

## Current checkpoint

- `ml/weights/best.pt`, **EMA weights**, epoch 9, **239 classes**,
  validation top-1 **86.5%** on 15,642 held-out images.
- `timm` `mobilenetv4_conv_medium`, 239 classes (the new Kaggle
  dataset: 156k images over 239 food items).
- Export path: PyTorch (`best.pt`) -> ONNX (opset 17, `dynamo=False`)
  -> onnx2tf -> LiteRT `.tflite`.
  `ml/scripts/export_tflite.py` is the separate Linux/litert-torch path
  and is not used for this asset.
- The model is bundled inside the mobile APK at `assets/models/baseline.tflite`
  and executed completely on-device with `flutter_litert` in a background isolate.

> The full swap procedure is `docs/model_swap.md` at the repo root.

## Export

The ONNX step needs `onnx` in the ML environment (`python -m pip install onnx`).

From `ml/` (ONNX output first):

```bash
python scripts/export_onnx2tf.py \
  --checkpoint weights/best.pt \
  --classes ../ml/data/classes.json
```

Then convert with a Python that has `onnx2tf` and `tensorflow`:

```bash
python scripts/export_onnx2tf.py \
  --checkpoint weights/best.pt \
  --classes ../ml/data/classes.json \
  --convert \
  --converter-python "$TEMP/ai_export_env/Scripts/python.exe"
```

On PowerShell, use `"$env:TEMP\ai_export_env\Scripts\python.exe"`.

The script prints the exact `*_float32.tflite` path and a copy command for
`app/assets/models/baseline.tflite`. Only float32 output is accepted;
there is no float16 fallback.

## Validation before copying

Run the exported TFLite and the ONNX source on the same fixed inputs
(at least two) and require **max absolute logit difference <= 1e-4**.
The current 239-class asset measured `1.2e-5`. If parity fails, do not
ship the asset.

```bash
"$TEMP/ai_export_env/Scripts/python.exe" ml/scripts/verify_export.py \
  --onnx artifacts/newmodel/baseline.onnx \
  --tflite artifacts/newmodel/onnx2tf/baseline_float32.tflite \
  --labels app/assets/models/labels.json
```

`app/test/model_contract_test.dart` additionally checks in CI that the
model's output dimension equals `len(labels.json["classes"])`, that
every label has a dish row in the catalog, and that the catalog's class
order equals the model's label order. A mismatch there is what makes
the app show a confident, WRONG dish.
