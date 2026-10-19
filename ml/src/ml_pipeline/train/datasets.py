"""Manifest-driven torch Dataset + transforms (Section 8.7.4)."""

from __future__ import annotations

import csv
from pathlib import Path

import torch
from PIL import Image
from torch.utils.data import Dataset
from torchvision import transforms

IMAGENET_MEAN = (0.485, 0.456, 0.406)
IMAGENET_STD = (0.229, 0.224, 0.225)


def build_transform(train: bool, image_size: int = 224) -> transforms.Compose:
    """Train: RRC + flip + light colour jitter (kitchen lighting).
    Eval: fixed resize + centre crop at the deployment size."""
    if train:
        return transforms.Compose(
            [
                transforms.RandomResizedCrop(image_size, scale=(0.5, 1.0)),
                transforms.RandomHorizontalFlip(),
                transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2),
                transforms.ToTensor(),
                transforms.Normalize(IMAGENET_MEAN, IMAGENET_STD),
            ]
        )
    return transforms.Compose(
        [
            transforms.Resize(int(image_size * 1.14)),
            transforms.CenterCrop(image_size),
            transforms.ToTensor(),
            transforms.Normalize(IMAGENET_MEAN, IMAGENET_STD),
        ]
    )


class ManifestDataset(Dataset):
    """One split of the manifest CSV written by scripts/make_splits.py.

    CSV columns: path,label,sha256,width,height,source,split
    The class list is passed in (from the taxonomy) so the label ->
    index mapping is stable across runs and matches the exported
    labels.json.
    """

    def __init__(
        self,
        manifest_csv: Path,
        split: str,
        classes: list[str],
        train: bool,
        image_size: int = 224,
    ):
        self.classes = classes
        self.class_to_idx = {c: i for i, c in enumerate(classes)}
        self.transform = build_transform(train, image_size)
        self.samples: list[tuple[str, int]] = []
        with open(manifest_csv, newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                if row["split"] == split:
                    self.samples.append((row["path"], self.class_to_idx[row["label"]]))

    def __len__(self) -> int:
        return len(self.samples)

    def __getitem__(self, index: int) -> tuple[torch.Tensor, int]:
        path, target = self.samples[index]
        with Image.open(path) as img:
            tensor = self.transform(img.convert("RGB"))
        return tensor, target
