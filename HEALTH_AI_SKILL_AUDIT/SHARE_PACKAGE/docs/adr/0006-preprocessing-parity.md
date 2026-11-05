# ADR 0006: Preprocessing parity is a release gate (R12)

## Context

"Great in the notebook, bad on the phone" is the classic failure mode
of on-device ML. The model's Python training pipeline and the Dart
inference pipeline must produce the same tensor from the same photo,
or accuracy silently degrades after export.

## Decision

1. The export module **bakes input normalisation into the graph**
   (mean/std, colour order, dtype), so the calibration constant
   (temperature) and softmax live in Dart and can change without
   re-exporting.
2. **Python parity test** (`ml/src/*/export/parity_test.py`): 200
   images through the PyTorch model and the `.tflite` via
   `ai-edge-litert`. Gate: top-1 agreement ≥99% (FP32/FP16) or
   ≥98% (INT8), logit differences within tolerance.
3. **Dart parity test** (`app/integration_test/ml_parity_test.dart`):
   ~20 fixed images with expected logits in
   `app/test/fixtures/parity/`. Dart preprocessing (decode, EXIF
   rotate, resize, colour order, dtype) must reproduce the expected
   output within tolerance on a device/emulator.
4. **Resize-interpolation trap** (Section 8.8): Pillow, OpenCV and
   Dart's `image` package resize differently. Decision: use the same
   algorithm in training and in the app — bilinear with
   area/antialias on downscale — and record the choice here. If a
   mismatch is unavoidable, measure the accuracy gap on the
   validation set and require it under 0.5 point.

## Consequences

- A re-exported model cannot silently change behaviour: both parity
  tests run in CI (Section 12.2).
- The expected-logits fixtures are committed; the images they were
  derived from are not (R8).

## Alternatives considered

- **"Just use the same library"** — impossible; Python and Dart
  ecosystems differ. Parity tests are the only reliable bridge.
- **Skip the Dart test** — the most common real-world failure is
  EXIF orientation or colour-order bugs that only appear on device.
