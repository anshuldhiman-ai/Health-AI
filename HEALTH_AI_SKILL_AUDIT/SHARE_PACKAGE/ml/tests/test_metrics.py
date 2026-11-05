"""Tests for classification metrics (Section 8.9)."""

import sys
from pathlib import Path

import torch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from ml_pipeline.eval.metrics import (
    confusion_counts,
    top_confusion_pairs,
    topk_accuracy,
    worst_class_recalls,
)


def test_topk_accuracy_basics() -> None:
    # 3 classes; targets 0,1,2; model puts true class first / second / last
    logits = torch.tensor([[9.0, 1.0, 0.0], [0.0, 9.0, 1.0], [0.0, 1.0, 9.0]])
    targets = torch.tensor([0, 1, 2])
    assert topk_accuracy(logits, targets, 1) == 1.0
    assert topk_accuracy(logits, targets, 2) == 1.0

    logits2 = torch.tensor([[0.0, 9.0, 0.5], [9.0, 1.0, 0.0], [0.0, 0.5, 9.0]])
    # row0: top1=1 (miss), top2 misses too; row1: top1=0 (miss), top2 hit;
    # row2: hit. => top1 = 1/3, top2 = 2/3.
    assert abs(topk_accuracy(logits2, targets, 1) - 1 / 3) < 1e-6
    assert abs(topk_accuracy(logits2, targets, 2) - 2 / 3) < 1e-6


def test_confusion_counts_and_worst_classes() -> None:
    logits = torch.tensor([[3.0, 0.0, 0.0], [3.0, 0.0, 0.0], [0.0, 0.0, 3.0], [3.0, 0.0, 0.0]])
    targets = torch.tensor([0, 1, 2, 2])
    m = confusion_counts(logits, targets, num_classes=3)
    assert m[0, 0] == 1  # target 0 -> pred 0
    assert m[1, 0] == 1  # target 1 -> pred 0 (confused)
    assert m[2, 2] == 1  # target 2 -> pred 2
    assert m[2, 0] == 1  # target 2 -> pred 0 (confused)

    worst = worst_class_recalls(m)
    # class 1: 0/1 recall; class 2: 1/2; class 0: 1/1
    assert worst[0][0] == 1 and worst[0][1] == 0.0
    assert worst[-1][0] == 0 and worst[-1][1] == 1.0


def test_top_confusion_pairs_sorted() -> None:
    logits = torch.tensor([[0.0, 3.0, 0.0], [0.0, 3.0, 0.0], [0.0, 3.0, 0.0], [0.0, 0.0, 3.0]])
    targets = torch.tensor([0, 0, 2, 0])
    m = confusion_counts(logits, targets, 3)
    pairs = top_confusion_pairs(m)
    # target 0 -> pred 1 twice; one 1 -> pred 1? no: (target 2 -> pred 1)
    # once and (target 0 -> pred 2) once.
    assert len(pairs) == 3
    assert pairs[0][:2] == (0, 1) and pairs[0][2] == 2
    assert all(count == 1 for _, _, count in pairs[1:])


def test_empty_input_is_zero_not_crash() -> None:
    logits = torch.zeros(0, 5)
    targets = torch.zeros(0, dtype=torch.long)
    assert topk_accuracy(logits, targets, 5) == 0.0
