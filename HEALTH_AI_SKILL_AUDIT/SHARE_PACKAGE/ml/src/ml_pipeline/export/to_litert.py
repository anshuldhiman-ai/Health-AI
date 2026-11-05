"""Export module: bakes input normalisation into the graph (ADR 0006).

The trained EMA model is wrapped so that:
  - input normalisation (resize, mean/std, colour order, dtype) is
    BAKED INTO the exported graph, and
  - the module outputs RAW LOGITS.

Temperature scaling and softmax are applied in Dart, so the
calibration constant can change without re-exporting.

TODO(M0): implement with the LiteRT Torch converter (litert-torch).
The smoke test (ADR 0004) exports RANDOM-WEIGHT copies of the
student candidates and runs one dummy inference in the app.
"""

# Placeholder — filled in at M0 smoke test / M2.
