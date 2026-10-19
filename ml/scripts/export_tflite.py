#!/usr/bin/env python
"""Export a trained student checkpoint to LiteRT .tflite + labels.json.

Usage on Colab/Linux (NOT on Windows dev boxes):

  python scripts/export_tflite.py \
      --checkpoint runs/baseline/best.pt \
      --splits data/interim/khana/manifest_splits.csv \
      --model-name mobilenetv4_conv_medium \
      --out-dir artifacts/baseline

Day-1 rule (Section 8.7): also run with --no-weights to push a
RANDOM-WEIGHTS student through the converter once, before any
accuracy work — a converter bug must never surprise us later.

Outputs (per --out-dir):
  baseline.tflite     float32 model, input [1,3,224,224] 0..1 normalized
  labels.json         {"classes": [...]} — app maps outputs by index

Note: preprocessing parity (R12) is the APP's duty at inference:
toTensor() equivalent: /255 + (x - mean)/std with ImageNet stats.
"""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from ml_pipeline.export.litert import (
    build_student,
    checkpoint_num_classes,
    export_tflite,
    write_labels,
)


def read_classes(splits_csv: Path) -> list[str]:
    with open(splits_csv, newline="", encoding="utf-8") as f:
        return sorted({row["label"] for row in csv.DictReader(f)})


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--checkpoint",
        type=Path,
        default=None,
        help="trained ckpt (omit, or --no-weights, for the day-1 check)",
    )
    ap.add_argument(
        "--splits",
        type=Path,
        default=None,
        help="manifest_splits.csv — supplies/verifies the class list",
    )
    ap.add_argument("--model-name", default="mobilenetv4_conv_medium")
    ap.add_argument("--image-size", type=int, default=224)
    ap.add_argument("--batch-size", type=int, default=1)
    ap.add_argument("--num-classes", type=int, default=None)
    ap.add_argument("--no-weights", action="store_true")
    ap.add_argument("--out-dir", type=Path, required=True)
    args = ap.parse_args()

    num_classes = args.num_classes
    if args.checkpoint is not None and not args.no_weights:
        from_ckpt = checkpoint_num_classes(args.checkpoint)
        if num_classes is not None and num_classes != from_ckpt:
            raise SystemExit(f"--num-classes {num_classes} != checkpoint meta {from_ckpt}")
        num_classes = from_ckpt
        print(f"checkpoint num_classes: {num_classes}")
    if args.splits is not None:
        classes = read_classes(args.splits)
        if num_classes is not None and len(classes) != num_classes:
            raise SystemExit(f"manifest has {len(classes)} classes, checkpoint says {num_classes}")
        if num_classes is None:
            num_classes = len(classes)
    if num_classes is None:
        raise SystemExit("need --checkpoint, --num-classes or --splits")

    weights = None if args.no_weights else args.checkpoint
    if args.no_weights:
        print("DAY-1 CHECK: exporting RANDOM-WEIGHTS student through converter")
    student = build_student(
        num_classes=num_classes,
        model_name=args.model_name,
        checkpoint_path=weights,
    )

    out_tflite = args.out_dir / "baseline.tflite"
    print(f"converting -> {out_tflite} (this step takes ~a minute)")
    export_tflite(student, out_tflite, image_size=args.image_size, batch_size=args.batch_size)
    size_mb = out_tflite.stat().st_size / (1024 * 1024)
    print(f"tflite written: {out_tflite} ({size_mb:.1f} MB)")

    if args.splits is not None:
        labels = args.out_dir / "labels.json"
        write_labels(read_classes(args.splits), labels)
        print(f"labels written: {labels} ({len(read_classes(args.splits))} classes)")

    print(
        f"preprocessing parity note (R12): app normalizes ImageNet "
        f"mean/std after /255 at {args.image_size}px, same train/eval "
        "transform chain in ml_pipeline.train.datasets.build_transform"
    )


if __name__ == "__main__":
    main()
