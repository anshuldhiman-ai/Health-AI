"""Export utilities: checkpoint -> student module -> LiteRT .tflite.

Runs ON Colab/Linux only (the converter wheels are not available on
Windows dev boxes), so the conversion path itself is exercised in
the notebook. Everything here is unit-testable on any OS.
"""

from __future__ import annotations

import importlib
import json
from pathlib import Path

import torch
import torch.nn as nn

from ml_pipeline.models.classifier import build_model


def litert_facade() -> object:
    """Resolve the LiteRT/torch converter facade across package renames."""
    last_error: Exception | None = None
    for name in ("litert_torch", "ai_edge_torch"):
        try:
            return importlib.import_module(name)
        except ImportError as exc:  # pragma: no cover - depends on env
            last_error = exc
    raise ImportError(
        "LiteRT export backend missing. Install the Linux-only extra: "
        "`uv sync --extra export` (or on Colab: pip install litert-torch)"
    ) from last_error


def checkpoint_num_classes(checkpoint_path: Path) -> int:
    checkpoint = torch.load(checkpoint_path, map_location="cpu", weights_only=False)
    return int(checkpoint["meta"]["num_classes"])


def build_student(
    num_classes: int,
    model_name: str,
    checkpoint_path: Path | None = None,
) -> nn.Module:
    """Build the student; with a checkpoint -> load its EMA weights.

    Day-1 rule (Section 8.7): also export a RANDOM-WEIGHTS copy (no
    checkpoint) straight through the converter before any accuracy
    work, so a converter bug can never surprise us weeks later.
    """
    model = build_model(
        model_name,
        num_classes=num_classes,
        pretrained=False,  # weights must come from our checkpoint only
    )
    if checkpoint_path is not None:
        checkpoint = torch.load(checkpoint_path, map_location="cpu", weights_only=False)
        state = checkpoint["ema"] or checkpoint["model"]
        model.load_state_dict(state)  # strict: full copy by construction
    model.eval()
    return model


def export_tflite(
    model: nn.Module,
    out_tflite: Path,
    image_size: int = 224,
    batch_size: int = 1,
) -> Path:
    """Convert an eval-mode student to .tflite through the LiteRT facade."""
    out_tflite.parent.mkdir(parents=True, exist_ok=True)
    sample = torch.zeros(batch_size, 3, image_size, image_size)
    converted = litert_facade().convert(model, (sample,))  # type: ignore[attr-defined]
    converted.export(str(out_tflite))
    return out_tflite


def write_labels(classes: list[str], out_json: Path) -> Path:
    """Persist the class list; the app maps outputs via this exact order."""
    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(
        json.dumps({"classes": classes}, indent=2),
        encoding="utf-8",
    )
    return out_json
