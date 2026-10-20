#!/usr/bin/env python
"""Compare two model checkpoints on the validation set.

Usage:
  python scripts/compare_checkpoints.py --splits data/interim/khana/manifest_splits.csv \
      --ckpt1 ml/weights/baseline/best_new.pt \
      --ckpt2 ml/weights/baseline/best_new2.pt
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path

import torch
from torch.utils.data import DataLoader

from ml_pipeline.eval.metrics import topk_accuracy, macro_f1, balanced_accuracy
from ml_pipeline.models.classifier import build_model
from ml_pipeline.train.datasets import ManifestDataset


def read_classes(splits_csv: Path) -> list[str]:
    with open(splits_csv, newline="", encoding="utf-8") as f:
        return sorted({row["label"] for row in csv.DictReader(f)})


@torch.no_grad()
def evaluate_checkpoint(
    ckpt_path: Path,
    val_loader: DataLoader,
    num_classes: int,
    device: torch.device,
) -> dict:
    """Load checkpoint and evaluate on validation set."""
    print(f"\nLoading checkpoint: {ckpt_path}")
    ckpt = torch.load(ckpt_path, map_location="cpu", weights_only=False)

    # Build model (we need to know the model name from metadata or use default)
    # For now, assume it's the same as in training
    model = build_model("mobilenetv4_conv_medium", num_classes=num_classes, pretrained=False)
    model.load_state_dict(ckpt["model"])
    model.to(device)
    model.eval()

    logits_all: list[torch.Tensor] = []
    targets_all: list[torch.Tensor] = []

    for images, targets in val_loader:
        images = images.to(device, non_blocking=True)
        out = model(images)
        logits_all.append(out.cpu())
        targets_all.append(targets)

    logits = torch.cat(logits_all)
    targets = torch.cat(targets_all)

    return {
        "top1": topk_accuracy(logits, targets, 1),
        "top5": topk_accuracy(logits, targets, 5),
        "macro_f1": macro_f1(logits, targets, num_classes),
        "balanced_accuracy": balanced_accuracy(logits, targets, num_classes),
        "n": int(targets.numel()),
    }


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--splits", type=Path, required=True)
    ap.add_argument("--ckpt1", type=Path, required=True)
    ap.add_argument("--ckpt2", type=Path, required=True)
    ap.add_argument("--batch-size", type=int, default=96)
    ap.add_argument("--num-workers", type=int, default=2)
    args = ap.parse_args()

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Using device: {device}")

    classes = read_classes(args.splits)
    print(f"{len(classes)} classes")

    val_ds = ManifestDataset(args.splits, "val", classes, train=False, image_size=224)
    val_loader = DataLoader(
        val_ds,
        batch_size=args.batch_size,
        num_workers=args.num_workers,
        pin_memory=True,
    )
    print(f"Validation samples: {len(val_ds)}")

    # Evaluate both checkpoints
    metrics1 = evaluate_checkpoint(args.ckpt1, val_loader, len(classes), device)
    metrics2 = evaluate_checkpoint(args.ckpt2, val_loader, len(classes), device)

    # Print comparison
    print("\n" + "=" * 70)
    print("CHECKPOINT COMPARISON")
    print("=" * 70)
    print(f"{'Metric':<20} {args.ckpt1.name:<20} {args.ckpt2.name:<20} {'Delta':<10}")
    print("-" * 70)

    for key in ["top1", "top5", "macro_f1", "balanced_accuracy"]:
        val1 = metrics1[key]
        val2 = metrics2[key]
        delta = val2 - val1
        sign = "+" if delta > 0 else ""
        print(f"{key:<20} {val1:<20.4f} {val2:<20.4f} {sign}{delta:<10.4f}")

    print("-" * 70)
    print(f"{'Samples':<20} {metrics1['n']:<20} {metrics2['n']:<20}")

    # Determine winner
    if metrics2["top1"] > metrics1["top1"]:
        print(f"\n🏆 WINNER: {args.ckpt2.name} (better top-1 accuracy)")
    elif metrics1["top1"] > metrics2["top1"]:
        print(f"\n🏆 WINNER: {args.ckpt1.name} (better top-1 accuracy)")
    else:
        print(f"\n🤝 TIE (same top-1 accuracy)")


if __name__ == "__main__":
    main()
