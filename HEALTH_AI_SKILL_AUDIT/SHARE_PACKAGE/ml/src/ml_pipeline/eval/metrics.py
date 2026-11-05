"""Classification metrics (Section 8.9).

Pure functions over prediction/target tensors so they are unit
testable without data or GPU. Release gates live in the eval script,
not here.
"""

from __future__ import annotations

import torch
from torchmetrics.classification import (
    MulticlassAccuracy,
    MulticlassF1Score,
)


def topk_accuracy(logits: torch.Tensor, targets: torch.Tensor, k: int) -> float:
    """Fraction of samples whose target is in the top-k logits."""
    if logits.numel() == 0:
        return 0.0
    k = min(k, logits.shape[1])
    topk = logits.topk(k, dim=1).indices
    correct = topk.eq(targets.unsqueeze(1)).any(dim=1)
    return correct.float().mean().item()


def confusion_counts(logits: torch.Tensor, targets: torch.Tensor, num_classes: int) -> torch.Tensor:
    """Confusion matrix: rows = target, cols = prediction."""
    preds = logits.argmax(dim=1)
    matrix = torch.zeros(num_classes, num_classes, dtype=torch.long)
    for t, p in zip(targets.tolist(), preds.tolist(), strict=True):
        matrix[t, p] += 1
    return matrix


def worst_class_recalls(matrix: torch.Tensor, k: int = 10) -> list[tuple[int, float]]:
    """k classes with the lowest recall (Section 8.7.9: collect more
    photos of exactly these). Classes with zero support are skipped."""
    support = matrix.sum(dim=1)
    out: list[tuple[int, float]] = []
    for cls in range(matrix.shape[0]):
        if support[cls] == 0:
            continue
        recall = (matrix[cls, cls] / support[cls]).item()
        out.append((cls, recall))
    out.sort(key=lambda x: x[1])
    return out[:k]


def top_confusion_pairs(matrix: torch.Tensor, k: int = 10) -> list[tuple[int, int, int]]:
    """Off-diagonal pairs (target, predicted) with the most confusion."""
    m = matrix.clone()
    m.fill_diagonal_(0)
    flat = m.flatten()
    counts, idxs = flat.topk(min(k, flat.numel()))
    return [
        (int(i // m.shape[1]), int(i % m.shape[1]), int(c))
        for c, i in zip(counts.tolist(), idxs.tolist(), strict=True)
        if c > 0
    ]


def macro_f1(logits: torch.Tensor, targets: torch.Tensor, num_classes: int) -> float:
    f1 = MulticlassF1Score(num_classes=num_classes, average="macro")
    return f1(logits.argmax(dim=1), targets).item()


def balanced_accuracy(logits: torch.Tensor, targets: torch.Tensor, num_classes: int) -> float:
    acc = MulticlassAccuracy(num_classes=num_classes, average="macro")
    return acc(logits.argmax(dim=1), targets).item()
