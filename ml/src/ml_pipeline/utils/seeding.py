"""Reproducibility helpers (Section 8.6: fix seeds, record versions)."""

import os
import random

import numpy as np
import torch


def seed_everything(seed: int) -> None:
    """Seed python, numpy and torch. Also sets torch matmul precision
    to high so Colab T4/A100 runs are consistent and fast."""
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    os.environ["PYTHONHASHSEED"] = str(seed)
    torch.set_float32_matmul_precision("high")


def git_commit() -> str:
    """Best-effort git commit hash for run logging (never fails offline)."""
    try:
        import subprocess

        return (
            subprocess.check_output(
                ["git", "rev-parse", "--short", "HEAD"],
                stderr=subprocess.DEVNULL,
                timeout=5,
            )
            .decode()
            .strip()
        )
    except Exception:
        return "unknown"
