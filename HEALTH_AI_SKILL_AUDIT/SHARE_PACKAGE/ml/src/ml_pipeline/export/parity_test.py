"""Python parity test (R12, ADR 0006).

The same 200 images go through the PyTorch model and the exported
.tflite via ai-edge-litert.

Gates:
  - FP32/FP16: top-1 agreement >= 99%, logit differences within tolerance
  - INT8:      top-1 agreement >= 98%

TODO(M0): implement in the smoke test with a random-weights model.
"""

# Placeholder — filled in at M0 smoke test / M2.
