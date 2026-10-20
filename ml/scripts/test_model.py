#!/usr/bin/env python
"""Test a model checkpoint by running inference on dummy data.

Usage:
  python scripts/test_model.py --ckpt ml/weights/baseline/best_new.pt
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

import torch

from ml_pipeline.models.classifier import build_model


def test_model(ckpt_path: Path) -> None:
    """Load and test the model."""
    print(f"Loading checkpoint: {ckpt_path}")
    ckpt = torch.load(ckpt_path, map_location="cpu", weights_only=False)

    num_classes = ckpt.get("meta", {}).get("num_classes", 239)
    print(f"Number of classes: {num_classes}")

    # Build and load model
    model = build_model("mobilenetv4_conv_medium", num_classes=num_classes, pretrained=False)
    model.load_state_dict(ckpt["model"])
    model.eval()

    # Test with dummy data
    batch_size = 4
    dummy_input = torch.randn(batch_size, 3, 224, 224)

    print(f"\nRunning inference on dummy batch (size={batch_size})...")
    with torch.no_grad():
        logits = model(dummy_input)

    print(f"Output shape: {logits.shape}")
    print(f"Output dtype: {logits.dtype}")

    # Get predictions
    probs = torch.softmax(logits, dim=1)
    top_probs, top_indices = probs.topk(5, dim=1)

    print("\nTop-5 predictions for each sample:")
    for i in range(batch_size):
        print(f"\nSample {i}:")
        for j in range(5):
            print(f"  Class {top_indices[i, j].item()}: {top_probs[i, j].item():.4f}")

    # Test EMA model if available
    if ckpt.get("ema"):
        print("\n" + "=" * 70)
        print("Testing EMA model...")
        ema_model = build_model("mobilenetv4_conv_medium", num_classes=num_classes, pretrained=False)
        ema_model.load_state_dict(ckpt["ema"])
        ema_model.eval()

        with torch.no_grad():
            ema_logits = ema_model(dummy_input)

        ema_probs = torch.softmax(ema_logits, dim=1)
        ema_top_probs, ema_top_indices = ema_probs.topk(5, dim=1)

        print("\nEMA Top-5 predictions for each sample:")
        for i in range(batch_size):
            print(f"\nSample {i}:")
            for j in range(5):
                print(f"  Class {ema_top_indices[i, j].item()}: {ema_top_probs[i, j].item():.4f}")

        # Compare predictions
        agreement = (top_indices == ema_top_indices).all(dim=1).float().mean().item() * 100
        print(f"\nPrediction agreement (top-5): {agreement:.2f}%")

    print("\n" + "=" * 70)
    print("Model test completed successfully!")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    default_ckpt = (
        Path("weights/baseline/best_new2.pt")
        if Path("weights/baseline/best_new2.pt").exists()
        else Path("weights/baseline/best.pt")
    )
    ap.add_argument("--ckpt", type=Path, default=default_ckpt, help=f"Checkpoint path (default: {default_ckpt})")
    args = ap.parse_args()

    test_model(args.ckpt)


if __name__ == "__main__":
    main()
