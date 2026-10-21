"""Inspect saved checkpoints: epoch, class count, and the head shape.

The head shape is the ground truth for the exported model's output
dimension, so it is what the app's labels.json must match.

Usage: python tools/check_checkpoints.py [weights_dir]
"""

import sys
from pathlib import Path

import torch

WEIGHTS = Path(sys.argv[1] if len(sys.argv) > 1 else "ml/weights/baseline")

for path in sorted(WEIGHTS.glob("*.pt")):
    try:
        ck = torch.load(path, map_location="cpu", weights_only=False)
    except Exception as exc:  # noqa: BLE001
        print(f"{path.name}: ERROR {exc}")
        continue

    meta = ck.get("meta") or {}
    ncls = meta.get("num_classes")

    head = None
    for key, val in ck.get("model", {}).items():
        if hasattr(val, "dim") and val.dim() == 2 and val.shape[0] != 1:
            if head is None or val.shape[0] > head[1][0]:
                head = (key, tuple(val.shape))

    ema_head = None
    ema = ck.get("ema")
    if ema:
        for key, val in ema.items():
            if hasattr(val, "dim") and val.dim() == 2 and val.shape[0] != 1:
                if ema_head is None or val.shape[0] > ema_head[1][0]:
                    ema_head = (key, tuple(val.shape))

    print(f"{path.name}")
    print(f"  epoch       : {ck.get('epoch')}")
    print(f"  num_classes : {ncls}")
    print(f"  model head  : {head}")
    print(f"  ema   head  : {ema_head}")
    print(f"  git commit  : {meta.get('git_commit')}")
