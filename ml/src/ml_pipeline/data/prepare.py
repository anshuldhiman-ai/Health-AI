"""Dataset preparation (Section 8.5): ingest, validate, dedupe.

Input: a directory of class folders (`<root>/<class_name>/*.jpg`).
Output: a manifest CSV — one row per kept image:

    path,label,sha256,width,height,source

Validation drops corrupt and tiny images. Dedupe drops exact
duplicates by content hash (perceptual-hash near-dup pass is
optional — it is slow on 100K+ images).
"""

from __future__ import annotations

import csv
import hashlib
from pathlib import Path

from PIL import Image

MANIFEST_FIELDS = ["path", "label", "sha256", "width", "height", "source"]

MIN_SIDE_PX = 32


def sha256_of(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def scan_and_validate(root: Path, source: str = "khana") -> list[dict]:
    """Walk class folders and return rows for valid, unique images.

    The FIRST occurrence of a content hash wins; later duplicates are
    dropped (deterministic: sorted path order).
    """
    rows: list[dict] = []
    seen_hashes: set[str] = set()
    class_dirs = sorted(d for d in root.iterdir() if d.is_dir())
    for class_dir in class_dirs:
        for img_path in sorted(class_dir.rglob("*")):
            if not img_path.is_file():
                continue
            # No extension filter: Khana ships extensionless files and
            # web-scraped datasets in general come with arbitrary or
            # missing extensions. PIL reads by content; undecodable
            # files are dropped below.
            digest = sha256_of(img_path)
            if digest in seen_hashes:
                continue
            try:
                with Image.open(img_path) as im:
                    im.verify()  # corrupt images raise here
                with Image.open(img_path) as im:
                    width, height = im.size
            except Exception:
                continue  # corrupt — dropped, counted by caller
            if min(width, height) < MIN_SIDE_PX:
                continue
            seen_hashes.add(digest)
            rows.append(
                {
                    "path": str(img_path),
                    "label": class_dir.name,
                    "sha256": digest,
                    "width": width,
                    "height": height,
                    "source": source,
                }
            )
    return rows


def write_manifest(rows: list[dict], out_csv: Path, fields: list[str] | None = None) -> None:
    fieldnames = fields or list(MANIFEST_FIELDS)
    out_csv.parent.mkdir(parents=True, exist_ok=True)
    with open(out_csv, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def read_manifest(in_csv: Path) -> list[dict]:
    with open(in_csv, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))
