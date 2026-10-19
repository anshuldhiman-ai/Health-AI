#!/usr/bin/env python
"""Create the train/val/test splits in the manifest CSV.
Usage:
  python scripts/make_splits.py --manifest data/interim/khana/manifest.csv \
      --out data/interim/khana/manifest_splits.csv --seed 42
Stratified by class. Section 8.3: with self-collected data, pass
--group-key session_id (or photographer_id) so group members never
leak across splits.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from ml_pipeline.data.prepare import (
    MANIFEST_FIELDS,
    read_manifest,
    write_manifest,
)
from ml_pipeline.data.splits import split_rows


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--manifest", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--ratios", nargs=3, type=float, default=[0.7, 0.15, 0.15])
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument(
        "--group-key", default=None, help="e.g. session_id — split by group, not by image"
    )
    args = ap.parse_args()
    rows = read_manifest(args.manifest)
    split_map = split_rows(
        rows, ratios=tuple(args.ratios), seed=args.seed, group_key=args.group_key
    )
    merged = []
    for split_name, split_rows_ in split_map.items():
        for row in split_rows_:
            merged.append({**row, "split": split_name})
    write_manifest(
        merged,
        args.out,
        fields=[*MANIFEST_FIELDS, "split"],
    )
    counts: dict[str, int] = {}
    for row in merged:
        counts[row["split"]] = counts.get(row["split"], 0) + 1
    print({k: counts[k] for k in ("train", "val", "test")})


if __name__ == "__main__":
    main()
