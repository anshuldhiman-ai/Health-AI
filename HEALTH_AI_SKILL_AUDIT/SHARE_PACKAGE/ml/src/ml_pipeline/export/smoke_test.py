"""Tiny random-weights export smoke test (ADR 0004).

Runs in CI on every PR. Creates a tiny model, bakes normalisation
into the graph, converts with litert-torch, and runs one inference
via ai-edge-litert. This catches converter/runtime failures before
any GPU hours are spent.

Set SMOKE_TEST=true to keep the model tiny.
"""

import os


def test_tiny_export_roundtrip() -> None:
    """Random weights -> export module -> .tflite -> ai-edge-litert inference."""
    # TODO(M0): implement with litert-torch and ai-edge-litert.
    # Steps:
    #   1. build a tiny random-weights model (e.g. MobileNetV4 tiny or a ConvNet)
    #   2. wrap in ExportModule (normalisation baked in, logits out)
    #   3. convert to FP32 .tflite
    #   4. load with ai-edge-litert, run a dummy inference
    #   5. assert output shape == (1, num_classes) and finite values
    if os.environ.get("SMOKE_TEST") != "true":
        return
    raise NotImplementedError("M0 smoke test — see ADR 0004")
