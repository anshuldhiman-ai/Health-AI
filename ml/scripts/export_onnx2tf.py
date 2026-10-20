#!/usr/bin/env python
"""Export an EMA checkpoint to ONNX, then convert to float32 TFLite with onnx2tf.

This is the Windows/Colab-friendly path used for the shipped baseline and is
separate from export_tflite.py (Linux-only litert-torch backend, different
layout). Here the ONNX graph takes NCHW float32 0..1 pixels and bakes ImageNet
normalization into the graph; onnx2tf then produces an NHWC float32 TFLite
model with the same normalization already applied.

Pipeline:
  checkpoint (EMA) -> normalized wrapper -> ONNX opset 17
  -> onnx2tf -> <model>_float32.tflite
  TFLite contract: input [1,224,224,3] float32 0..1 -> output [1,80] raw logits

Usage (run from ml/):

  # ONNX only (needs onnx in this Python)
  python scripts/export_onnx2tf.py --checkpoint weights/baseline/best.pt

  # ONNX + TFLite (converter Python needs onnx2tf + tensorflow)
  python scripts/export_onnx2tf.py \\
      --checkpoint weights/baseline/best.pt \\
      --convert \\
      --converter-python "$TEMP/ai_export_env/Scripts/python.exe"

Do not silently substitute float16: only *_float32.tflite is accepted.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path
from types import ModuleType
from typing import Any

import torch
from torch import nn

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from ml_pipeline.models.classifier import build_model

IMAGENET_MEAN = (0.485, 0.456, 0.406)
IMAGENET_STD = (0.229, 0.224, 0.225)
DEFAULT_MODEL_NAME = "mobilenetv4_conv_medium"
DEFAULT_IMAGE_SIZE = 224
DEFAULT_OUT_DIR = Path("artifacts/baseline/onnx2tf")


class NormalizedClassifier(nn.Module):
    """Classifier with ImageNet normalization baked into the graph."""

    def __init__(self, model: nn.Module) -> None:
        super().__init__()
        self.model = model
        self.register_buffer("mean", torch.tensor(IMAGENET_MEAN).view(1, 3, 1, 1))
        self.register_buffer("std", torch.tensor(IMAGENET_STD).view(1, 3, 1, 1))

    def forward(self, pixel_values: torch.Tensor) -> torch.Tensor:
        return self.model((pixel_values - self.mean) / self.std)


def _load_ema_model(
    checkpoint_path: Path,
    model_name: str,
    num_classes_override: int | None,
) -> tuple[nn.Module, int, int | None]:
    """Rebuild the architecture and load the checkpoint's EMA state strictly."""
    if not checkpoint_path.is_file():
        raise SystemExit(f"error: checkpoint not found: {checkpoint_path}")

    checkpoint = torch.load(checkpoint_path, map_location="cpu", weights_only=False)
    ema_state = checkpoint.get("ema")
    if not ema_state:
        raise SystemExit(
            f"error: checkpoint has no EMA weights: {checkpoint_path}\n"
            "hint: this path intentionally never falls back to the raw `model` state; "
            "export a checkpoint that contains EMA weights"
        )

    meta = checkpoint.get("meta") or {}
    meta_classes = meta.get("num_classes")
    if meta_classes is not None:
        num_classes = int(meta_classes)
        if num_classes_override is not None and num_classes_override != num_classes:
            raise SystemExit(
                f"error: --num-classes {num_classes_override} != checkpoint meta {num_classes}"
            )
    elif num_classes_override is not None:
        num_classes = num_classes_override
    else:
        raise SystemExit("error: checkpoint meta has no num_classes; pass --num-classes explicitly")

    model = build_model(model_name, num_classes=num_classes, pretrained=False)
    try:
        model.load_state_dict(ema_state, strict=True)
    except RuntimeError as exc:
        raise SystemExit(
            f"error: EMA state did not load strictly into {model_name} "
            f"with {num_classes} classes; check --model-name / --num-classes\n{exc}"
        ) from exc
    model.eval()

    epoch = checkpoint.get("epoch")
    return model, num_classes, int(epoch) if isinstance(epoch, int) else None


def _require_onnx() -> ModuleType:
    try:
        import onnx
    except ImportError as exc:
        raise SystemExit(
            "error: ONNX export requires the `onnx` package in this Python.\n"
            "hint: python -m pip install onnx"
        ) from exc
    return onnx


def _tensor_shape(value_info: Any) -> list[int]:
    return [int(dim.dim_value) for dim in value_info.type.tensor_type.shape.dim]


def export_onnx(
    model: nn.Module,
    onnx_out: Path,
    image_size: int,
    num_classes: int,
) -> Path:
    """Write opset-17 ONNX with normalization in-graph and run onnx.checker."""
    onnx = _require_onnx()
    onnx_out.parent.mkdir(parents=True, exist_ok=True)
    wrapper = NormalizedClassifier(model).eval()
    sample = torch.zeros(1, 3, image_size, image_size, dtype=torch.float32)

    try:
        with torch.no_grad():
            torch.onnx.export(
                wrapper,
                (sample,),
                str(onnx_out),
                export_params=True,
                opset_version=17,
                do_constant_folding=True,
                input_names=["pixel_values"],
                output_names=["logits"],
                # Matches the validated export; the legacy exporter warning is expected.
                dynamo=False,
            )
        onnx.checker.check_model(str(onnx_out))
    except Exception as exc:
        raise SystemExit(f"error: ONNX export/checker failed: {exc}") from exc

    exported = onnx.load(str(onnx_out))
    input_shape = _tensor_shape(exported.graph.input[0])
    output_shape = _tensor_shape(exported.graph.output[0])
    expected_input = [1, 3, image_size, image_size]
    expected_output = [1, num_classes]
    if input_shape != expected_input:
        raise SystemExit(f"error: ONNX input shape {input_shape} != {expected_input}")
    if output_shape != expected_output:
        raise SystemExit(f"error: ONNX output shape {output_shape} != {expected_output}")

    print(
        f"onnx: {onnx_out} (opset 17, input {input_shape} NCHW 0..1, "
        f"output {output_shape} raw logits)"
    )
    return onnx_out


def _find_float32_tflite(out_dir: Path, onnx_stem: str) -> Path:
    """Return the float32 artifact onnx2tf wrote; never pick float16."""
    exact = out_dir / f"{onnx_stem}_float32.tflite"
    if exact.is_file():
        return exact

    candidates = sorted(out_dir.rglob("*_float32.tflite"))
    if len(candidates) == 1:
        return candidates[0]
    if not candidates:
        found = sorted(str(path) for path in out_dir.rglob("*.tflite"))
        raise SystemExit(
            f"error: no float32 .tflite under {out_dir}; found: {found or 'nothing'}\n"
            "hint: onnx2tf normally writes <model>_float32.tflite; check its log above"
        )
    raise SystemExit(
        "error: multiple float32 .tflite files found; use a clean --out-dir:\n  "
        + "\n  ".join(str(path) for path in candidates)
    )


def _run_onnx2tf(
    converter_python: Path | None,
    onnx_out: Path,
    out_dir: Path,
) -> Path:
    python = converter_python if converter_python is not None else Path(sys.executable)
    if not python.is_file():
        raise SystemExit(f"error: --converter-python not found: {python}")

    probe = subprocess.run(
        [str(python), "-c", "import onnx2tf"],
        check=False,
        capture_output=True,
        text=True,
    )
    if probe.returncode != 0:
        raise SystemExit(
            f"error: {python} cannot import onnx2tf\n"
            "hint: pass --converter-python pointing at a venv with onnx2tf + tensorflow, e.g.\n"
            '  py -3.12 -m venv "%TEMP%\\ai_export_env"\n'
            '  "%TEMP%\\ai_export_env\\Scripts\\python.exe" -m pip install onnx2tf tensorflow\n'
            f"probe stderr: {probe.stderr.strip() or '<empty>'}"
        )

    out_dir.mkdir(parents=True, exist_ok=True)
    cmd = [str(python), "-m", "onnx2tf", "-i", str(onnx_out), "-o", str(out_dir)]
    print(f"running: {subprocess.list2cmdline(cmd)}")
    result = subprocess.run(cmd, check=False)
    if result.returncode != 0:
        raise SystemExit(
            f"error: onnx2tf failed with exit code {result.returncode}; see its log above"
        )
    return _find_float32_tflite(out_dir, onnx_out.stem)


def _print_copy_hint(tflite: Path, image_size: int, num_classes: int) -> None:
    asset = Path(__file__).resolve().parents[2] / "app/assets/models/baseline.tflite"
    resolved = tflite.resolve()
    size_mb = resolved.stat().st_size / (1024 * 1024)
    print(f"tflite (float32): {resolved} ({size_mb:.1f} MB)")
    print(
        f"contract: input [1,{image_size},{image_size},3] float32 0..1 "
        f"-> output [1,{num_classes}] raw logits"
    )
    print(f"copy to app asset: {asset}")
    print(f'  PowerShell: Copy-Item -Force "{resolved}" "{asset}"')
    print(f'  bash:       cp "{resolved}" "{asset}"')


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--checkpoint",
        type=Path,
        default=Path("weights/baseline/best_new2.pt")
        if Path("weights/baseline/best_new2.pt").exists()
        else Path("weights/baseline/best.pt"),
        help="EMA checkpoint (default: weights/baseline/best_new2.pt or best.pt)",
    )
    parser.add_argument(
        "--onnx-out",
        type=Path,
        default=None,
        help="ONNX output path (default: <out-dir>/baseline.onnx)",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=DEFAULT_OUT_DIR,
        help=f"onnx2tf output directory (default: {DEFAULT_OUT_DIR})",
    )
    parser.add_argument("--model-name", default=DEFAULT_MODEL_NAME)
    parser.add_argument("--image-size", type=int, default=DEFAULT_IMAGE_SIZE)
    parser.add_argument(
        "--num-classes",
        type=int,
        default=None,
        help="defaults to checkpoint meta; an explicit mismatch fails",
    )
    parser.add_argument(
        "--converter-python",
        type=Path,
        default=None,
        help="Python executable with onnx2tf + tensorflow (default: this Python)",
    )
    parser.add_argument(
        "--convert",
        action="store_true",
        help="run onnx2tf after the ONNX export (otherwise stop at ONNX)",
    )
    args = parser.parse_args()

    if args.image_size <= 0:
        raise SystemExit(f"error: --image-size must be positive, got {args.image_size}")

    onnx_out = args.onnx_out or args.out_dir / "baseline.onnx"
    model, num_classes, epoch = _load_ema_model(
        args.checkpoint,
        args.model_name,
        args.num_classes,
    )
    print(f"checkpoint: {args.checkpoint} (epoch {epoch}, EMA weights)")
    print(f"model: {args.model_name}, {num_classes} classes, {args.image_size}px")

    export_onnx(model, onnx_out, args.image_size, num_classes)

    if args.convert:
        tflite = _run_onnx2tf(args.converter_python, onnx_out, args.out_dir)
        _print_copy_hint(tflite, args.image_size, num_classes)
        return

    converter = args.converter_python or Path("<python-with-onnx2tf>")
    print("ONNX only; rerun with --convert to produce TFLite:")
    print(f'  "{converter}" -m onnx2tf -i "{onnx_out}" -o "{args.out_dir}"')


if __name__ == "__main__":
    main()
