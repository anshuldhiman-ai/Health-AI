#!/usr/bin/env python
"""Compare two model checkpoints without needing the full dataset.

This script loads both checkpoints and compares:
- Checkpoint metadata (epoch, git commit, etc.)
- Weight statistics
- File sizes
"""

from __future__ import annotations

import argparse
from pathlib import Path

import torch


def compare_metadata(ckpt1: dict, ckpt2: dict) -> None:
    """Compare checkpoint metadata."""
    print("\n" + "=" * 70)
    print("METADATA COMPARISON")
    print("=" * 70)

    meta1 = ckpt1.get("meta", {})
    meta2 = ckpt2.get("meta", {})

    print(f"{'Key':<20} {'Checkpoint 1':<25} {'Checkpoint 2':<25}")
    print("-" * 70)

    all_keys = sorted(set(meta1.keys()) | set(meta2.keys()))
    for key in all_keys:
        val1 = meta1.get(key, "N/A")
        val2 = meta2.get(key, "N/A")
        print(f"{key:<20} {str(val1):<25} {str(val2):<25}")

    print(f"{'epoch':<20} {ckpt1.get('epoch', 'N/A'):<25} {ckpt2.get('epoch', 'N/A'):<25}")
    print()


def compare_weights(ckpt1: dict, ckpt2: dict) -> None:
    """Compare weight statistics."""
    print("=" * 70)
    print("WEIGHT STATISTICS COMPARISON")
    print("=" * 70)

    state1 = ckpt1["model"]
    state2 = ckpt2["model"]

    print(f"{'Layer':<40} {'Mean diff':<15} {'Max diff':<15} {'Std diff':<15}")
    print("-" * 70)

    diffs = []
    for key in state1.keys():
        if key not in state2:
            continue
        w1 = state1[key]
        w2 = state2[key]
        if not w1.dtype.is_floating_point:
            print(f"{key:<40} {'(non-float)':<15} {'(non-float)':<15} {'(non-float)':<15}")
            continue
        diff = (w1 - w2).abs()
        mean_diff = diff.mean().item()
        max_diff = diff.max().item()
        std_diff = diff.std().item()
        diffs.append((key, mean_diff, max_diff, std_diff))
        print(f"{key:<40} {mean_diff:<15.6e} {max_diff:<15.6e} {std_diff:<15.6e}")

    if diffs:
        avg_mean = sum(d[1] for d in diffs) / len(diffs)
        avg_max = sum(d[2] for d in diffs) / len(diffs)
        avg_std = sum(d[3] for d in diffs) / len(diffs)
        print("-" * 70)
        print(f"{'AVERAGE':<40} {avg_mean:<15.6e} {avg_max:<15.6e} {avg_std:<15.6e}")
    print()


def compare_ema_weights(ckpt1: dict, ckpt2: dict) -> None:
    """Compare EMA weight statistics."""
    print("=" * 70)
    print("EMA WEIGHT STATISTICS COMPARISON")
    print("=" * 70)

    if not ckpt1.get("ema") or not ckpt2.get("ema"):
        print("One or both checkpoints missing EMA weights")
        print()
        return

    state1 = ckpt1["ema"]
    state2 = ckpt2["ema"]

    print(f"{'Layer':<40} {'Mean diff':<15} {'Max diff':<15} {'Std diff':<15}")
    print("-" * 70)

    diffs = []
    for key in state1.keys():
        if key not in state2:
            continue
        w1 = state1[key]
        w2 = state2[key]
        if not w1.dtype.is_floating_point:
            print(f"{key:<40} {'(non-float)':<15} {'(non-float)':<15} {'(non-float)':<15}")
            continue
        diff = (w1 - w2).abs()
        mean_diff = diff.mean().item()
        max_diff = diff.max().item()
        std_diff = diff.std().item()
        diffs.append((key, mean_diff, max_diff, std_diff))
        print(f"{key:<40} {mean_diff:<15.6e} {max_diff:<15.6e} {std_diff:<15.6e}")

    if diffs:
        avg_mean = sum(d[1] for d in diffs) / len(diffs)
        avg_max = sum(d[2] for d in diffs) / len(diffs)
        avg_std = sum(d[3] for d in diffs) / len(diffs)
        print("-" * 70)
        print(f"{'AVERAGE':<40} {avg_mean:<15.6e} {avg_max:<15.6e} {avg_std:<15.6e}")
    print()


def compare_file_sizes(path1: Path, path2: Path) -> None:
    """Compare file sizes."""
    print("=" * 70)
    print("FILE SIZE COMPARISON")
    print("=" * 70)

    size1 = path1.stat().st_size
    size2 = path2.stat().st_size

    print(f"{path1.name:<30} {size1:>15} bytes")
    print(f"{path2.name:<30} {size2:>15} bytes")
    print(f"{'Difference':<30} {size2 - size1:>15} bytes")
    print()


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--ckpt1", type=Path, required=True)
    ap.add_argument("--ckpt2", type=Path, required=True)
    args = ap.parse_args()

    print(f"Loading {args.ckpt1}...")
    ckpt1 = torch.load(args.ckpt1, map_location="cpu", weights_only=False)

    print(f"Loading {args.ckpt2}...")
    ckpt2 = torch.load(args.ckpt2, map_location="cpu", weights_only=False)

    # Compare
    compare_metadata(ckpt1, ckpt2)
    compare_file_sizes(args.ckpt1, args.ckpt2)
    compare_weights(ckpt1, ckpt2)
    compare_ema_weights(ckpt1, ckpt2)

    print("=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print(f"Checkpoint 1: {args.ckpt1}")
    print(f"Checkpoint 2: {args.ckpt2}")
    print()
    print("Both checkpoints have been compared on:")
    print("  1. Metadata (epoch, git commit, seed, num_classes)")
    print("  2. File sizes")
    print("  3. Model weight statistics (mean, max, std differences)")
    print("  4. EMA weight statistics (mean, max, std differences)")
    print()
    print("If all weight differences are 0.0, the checkpoints are identical.")


if __name__ == "__main__":
    main()
