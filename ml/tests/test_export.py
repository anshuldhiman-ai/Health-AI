"""Tests for export bindings (labels + checkpoint wiring)."""

import sys
from pathlib import Path

import torch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from ml_pipeline.export.litert import (
    build_student,
    write_labels,
)


def test_labels_round_trip(tmp_path: Path) -> None:
    out = write_labels(sorted(["dal makhani", "chai", "dosa"]), tmp_path / "labels.json")
    import json

    data = json.loads(out.read_text(encoding="utf-8"))
    assert data["classes"] == ["chai", "dal makhani", "dosa"]


def test_build_student_random_weights_is_not_from_hub(tmp_path: Path) -> None:
    """Day-1 rule: random-weights student builds offline, no downloads."""
    model = build_student(num_classes=80, model_name="mobilenetv4_conv_medium")
    # fresh head -> all 80 logits wired
    out = model(torch.zeros(1, 3, 224, 224))
    assert out.shape == (1, 80)


def test_build_student_loads_ema_strict(tmp_path: Path) -> None:
    """A checkpoint's EMA state must load strictly into the same arch."""
    source = build_student(num_classes=80, model_name="mobilenetv4_conv_medium")
    ckpt = tmp_path / "best.pt"
    torch.save(
        {
            "model": source.state_dict(),
            "ema": source.state_dict(),
            "optimizer": {},
            "scheduler": {},
            "epoch": 7,
            "meta": {"git_commit": "test", "seed": 42, "num_classes": 80},
        },
        ckpt,
    )
    loaded = build_student(
        num_classes=80, model_name="mobilenetv4_conv_medium", checkpoint_path=ckpt
    )
    with torch.no_grad():
        for a, b in zip(source.parameters(), loaded.parameters(), strict=True):
            assert torch.equal(a, b)
