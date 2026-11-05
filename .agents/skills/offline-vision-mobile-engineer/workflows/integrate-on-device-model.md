# Workflow: integrate an on-device model

## 1. Inspect the model source

Record framework, architecture, checkpoint, labels, license, dataset provenance, and intended use. Do not assume a model file exists because a README describes it.

## 2. Freeze the contract

Document input shape, dtype, layout, RGB/BGR, pixel range, normalization, resize/crop/interpolation, output shape, logits/probabilities, quantization, and class order.

## 3. Validate preprocessing

Use fixed images with portrait/landscape/EXIF cases. Compare the Python training transform and mobile transform numerically. Explain any accepted tolerance.

## 4. Export

- Export a tiny random-weight model first to validate the converter/runtime path.
- Export the trained checkpoint.
- Verify output shape and finite values.
- Compare source framework and exported runtime on fixed inputs.
- Record model hash and model card.

## 5. Integrate

- Bundle the model if offline operation is required.
- Validate asset presence and checksum.
- Validate tensor shape and label count at load time.
- Own the interpreter lifecycle and serialize calls if required.
- Add timeouts and typed error handling.
- Keep manual search/entry available if model loading or inference fails.

## 6. Calibrate

- Evaluate on held-out, representative images.
- Include out-of-domain/non-food hard negatives.
- Calibrate confidence and rejection thresholds.
- Track latency and memory on target devices.
- Do not equate a confidence ratio with calibrated probability.

## 7. Gate release

Require model contract tests, preprocessing parity, export smoke tests that truly execute, device tests, license checks, and model-card provenance.
