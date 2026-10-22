#!/usr/bin/env python
"""Train the student classifier (Section 8.7 baseline recipe).
Usage (Colab/Kaggle or local with data):
  python scripts/train.py --splits data/interim/khana/manifest_splits.csv \
      --model-name mobilenetv4_conv_medium --epochs 30 --out runs/baseline
Checkpoints go to --out (point it INTO Google Drive on Colab so
sessions dying does not lose runs — Section 8.6). Resume with
--resume runs/baseline/last.pt
"""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path

from torch.utils.data import DataLoader

from ml_pipeline.models.classifier import build_model
from ml_pipeline.train.datasets import ManifestDataset
from ml_pipeline.train.train_loop import fit
from ml_pipeline.utils.seeding import seed_everything


def read_classes(splits_csv: Path) -> list[str]:
    with open(splits_csv, newline="", encoding="utf-8") as f:
        return sorted({row["label"] for row in csv.DictReader(f)})


def write_class_order(classes: list[str], out_dir: Path) -> Path:
    """Save the model's class order next to the checkpoints.

    The model's output index IS this order, so the app's labels.json
    must use it. Writing it here means the class list travels with the
    run instead of having to be reconstructed from the dataset later.
    """
    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / "classes.json"
    path.write_text(json.dumps(classes, indent=2) + "\n", encoding="utf-8")
    return path


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--splits", type=Path, required=True)
    ap.add_argument("--out", type=Path, default=Path("runs/baseline"))
    ap.add_argument("--model-name", default="mobilenetv4_conv_medium")
    ap.add_argument("--image-size", type=int, default=224)
    ap.add_argument("--epochs", type=int, default=30)
    ap.add_argument("--warmup-epochs", type=int, default=3)
    ap.add_argument("--batch-size", type=int, default=96)
    ap.add_argument("--lr", type=float, default=1e-3)
    ap.add_argument("--weight-decay", type=float, default=0.05)
    ap.add_argument("--label-smoothing", type=float, default=0.1)
    ap.add_argument("--ema-decay", type=float, default=0.999)
    ap.add_argument("--num-workers", type=int, default=2)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument(
        "--no-pretrained",
        action="store_true",
        help="random weights — day-1 export check (Section 8.7)",
    )
    ap.add_argument("--resume", type=Path, default=None)
    args = ap.parse_args()
    seed_everything(args.seed)
    classes = read_classes(args.splits)
    class_order_path = write_class_order(classes, args.out)
    print(f"{len(classes)} classes: {classes[:5]}...")
    print(f"class order: {class_order_path}")
    train_ds = ManifestDataset(
        args.splits, "train", classes, train=True, image_size=args.image_size
    )
    val_ds = ManifestDataset(args.splits, "val", classes, train=False, image_size=args.image_size)
    train_loader = DataLoader(
        train_ds,
        batch_size=args.batch_size,
        shuffle=True,
        num_workers=args.num_workers,
        pin_memory=True,
        drop_last=True,
    )
    val_loader = DataLoader(
        val_ds,
        batch_size=args.batch_size,
        num_workers=args.num_workers,
        pin_memory=True,
    )
    # When resuming, weights come from the checkpoint; skip the (slow)
    # pretrained download to avoid network/size churn on Colab.
    pretrained = (not args.no_pretrained) and (args.resume is None)
    model = build_model(
        args.model_name,
        num_classes=len(classes),
        pretrained=pretrained,
    )
    best = fit(
        model,
        train_loader,
        val_loader,
        num_classes=len(classes),
        out_dir=args.out,
        epochs=args.epochs,
        warmup_epochs=args.warmup_epochs,
        lr=args.lr,
        weight_decay=args.weight_decay,
        label_smoothing=args.label_smoothing,
        ema_decay=args.ema_decay,
        seed=args.seed,
        resume_from=args.resume,
    )
    print(f"best checkpoint: {best}")


if __name__ == "__main__":
    main()
