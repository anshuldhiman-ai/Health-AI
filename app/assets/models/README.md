# On-device food classifier assets

`baseline.tflite` is generated; `labels.json` is source and must stay in
sync with it. Model binaries under `app/assets/models/` are gitignored
(`app/assets/models/*.tflite`) and must not be committed.

## Model contract

- **Input**: `float32[1,224,224,3]`, NHWC, RGB, raw `0..1`.
  ImageNet normalization (`(x - mean) / std`) is baked into the graph;
  do **not** normalize again in Dart.
- **Output**: `float32[1,80]` raw logits. The app applies temperature
  scaling and softmax; the graph must not contain either.
- **Preprocessing**: resize the shorter side to 255, then center-crop 224
  (torchvision eval transform), matching `preprocessFoodPhoto`.
- **Labels**: output index `i` maps to `labels.json["classes"][i]`.
  Keep that file's order exactly; do not sort it.

## Current checkpoint

- `ml/weights/baseline/best.pt`, epoch 9, **EMA weights**.
- `timm` `mobilenetv4_conv_medium`, 80 classes.
- Export path: PyTorch -> ONNX (opset 17, `dynamo=False`) -> onnx2tf.
  `ml/scripts/export_tflite.py` is the separate Linux/litert-torch path
  and is not used for this asset.

## Export

The ONNX step needs `onnx` in the ML environment (`python -m pip install onnx`).

From `ml/` (ONNX output first):

```bash
python scripts/export_onnx2tf.py --checkpoint weights/baseline/best.pt
```

Then convert with a Python that has `onnx2tf` and `tensorflow`:

```bash
python scripts/export_onnx2tf.py \
  --checkpoint weights/baseline/best.pt \
  --convert \
  --converter-python "$TEMP/ai_export_env/Scripts/python.exe"
```

On PowerShell, use `"$env:TEMP\ai_export_env\Scripts\python.exe"`.

The script prints the exact `*_float32.tflite` path and a copy command for
`app/assets/models/baseline.tflite`. Only float32 output is accepted;
there is no float16 fallback.

## Validation before copying

Run the exported TFLite and the PyTorch EMA model on the same fixed inputs
(at least two) and require **max absolute logit difference <= 1e-4**.
The epoch-9 asset measured `5e-6`. If parity fails, do not ship the asset.
