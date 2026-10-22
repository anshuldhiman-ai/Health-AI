"""Verify an exported TFLite model against its ONNX source.

A TFLite that is quietly wrong (transposed axes, wrong normalisation)
ships a model that looks fine and predicts garbage. This is the check
that catches it BEFORE the model reaches a phone.

Usage:
  python scripts/verify_export.py \\
      --onnx artifacts/newmodel/baseline.onnx \\
      --tflite artifacts/newmodel/onnx2tf/baseline_float32.tflite \\
      [--labels app/assets/models/labels.json] [--tolerance 1e-4]

The ONNX graph takes NCHW float32 0..1 (ImageNet normalisation is
baked in); the TFLite takes NHWC float32 0..1 (the app's
preprocessing output). Keep that distinction exact.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_TOLERANCE = 1e-4


def build_inputs(rng: np.random.Generator) -> list[tuple[str, np.ndarray]]:
    """Deterministic 0..1 inputs in the ONNX layout (NCHW)."""
    cases: list[tuple[str, np.ndarray]] = []
    cases.append(("uniform-random", rng.random((1, 3, 224, 224), dtype=np.float32)))

    # A structured image: flat regions, so a transposed tensor produces
    # visibly different logits rather than similar noise.
    flat = np.zeros((1, 3, 224, 224), dtype=np.float32)
    flat[:, :, 40:180, 30:190] = 0.85
    flat[:, 0, 60:120, 70:150] = 0.25
    cases.append(("flat-blocks", flat))

    # A horizontal gradient: catches an NHWC/NCHW mix-up directly.
    ramp = np.linspace(0.0, 1.0, 224, dtype=np.float32)
    grad = np.tile(ramp, (3, 224, 1)).reshape(1, 3, 224, 224)
    cases.append(("horizontal-ramp", grad.astype(np.float32)))
    return cases


def run_onnx(path: Path, inputs: list[np.ndarray]) -> list[np.ndarray]:
    import onnxruntime as ort  # type: ignore[import-not-found]

    session = ort.InferenceSession(str(path), providers=["CPUExecutionProvider"])
    return [session.run(None, {session.get_inputs()[0].name: x})[0] for x in inputs]


def run_tflite(path: Path, inputs: list[np.ndarray]) -> list[np.ndarray]:
    import tensorflow as tf

    interpreter = tf.lite.Interpreter(model_path=str(path))
    interpreter.allocate_tensors()
    in_detail = interpreter.get_input_details()[0]
    out_detail = interpreter.get_output_details()[0]
    results = []
    for x in inputs:
        # ONNX NCHW -> TFLite NHWC
        feed = np.transpose(x, (0, 2, 3, 1)).astype(np.float32)
        interpreter.set_tensor(in_detail["index"], feed)
        interpreter.invoke()
        results.append(np.array(interpreter.get_tensor(out_detail["index"])))
    return results


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--onnx", type=Path, required=True)
    parser.add_argument("--tflite", type=Path, required=True)
    parser.add_argument(
        "--labels",
        type=Path,
        default=ROOT / "app/assets/models/labels.json",
        help="the app's labels.json, to check the class count against",
    )
    parser.add_argument("--tolerance", type=float, default=DEFAULT_TOLERANCE)
    args = parser.parse_args()

    rng = np.random.default_rng(20261021)
    cases = build_inputs(rng)
    inputs = [case[1] for case in cases]

    onnx_out = run_onnx(args.onnx, inputs)
    tflite_out = run_tflite(args.tflite, inputs)

    print(f"onnx   : {args.onnx}")
    print(f"tflite : {args.tflite}")
    print()
    header = f"{'input':<20} {'onnx shape':<18} {'tflite shape':<18} {'max |diff|':<12} result"
    print(header)
    print("-" * len(header))

    worst = 0.0
    failed = False
    for (name, _), a, b in zip(cases, onnx_out, tflite_out, strict=True):
        diff = float(np.max(np.abs(a.astype(np.float64) - b.astype(np.float64))))
        worst = max(worst, diff)
        ok = diff <= args.tolerance
        failed = failed or not ok
        print(
            f"{name:<20} {a.shape!s:<18} {b.shape!s:<18} {diff:<12.3e} {'PASS' if ok else 'FAIL'}"
        )

    # The class count must match the app's label file, or the app maps
    # output indices to the WRONG dishes.
    if args.labels.is_file():
        labels = json.loads(args.labels.read_text(encoding="utf-8"))["classes"]
        model_classes = int(tflite_out[0].shape[-1])
        if model_classes != len(labels):
            print()
            print(
                f"WARNING: the model outputs {model_classes} classes but "
                f"{args.labels} lists {len(labels)}. The app would map every "
                f"prediction to the wrong dish - regenerate labels.json "
                f"(export_onnx2tf.py --classes ...)."
            )
        else:
            print()
            print(f"class count: {model_classes} == labels.json ({len(labels)}) OK")

    print()
    print(f"worst max |diff| : {worst:.3e}  (tolerance {args.tolerance:.0e})")
    if failed:
        print("RESULT: FAIL - the TFLite does not match the ONNX")
        return 1
    print("RESULT: PASS - the TFLite matches the ONNX")
    return 0


if __name__ == "__main__":
    sys.exit(main())
