#!/usr/bin/env python
"""Ingest a downloaded public food dataset into a taxonomy-mapped manifest (T1.3).

Usage (from ml/):
  uv run python scripts/ingest_public_data.py --source khana \
      --root data/raw/khana --out data/interim/khana/manifest.csv

Nothing is downloaded here: point --root at a dataset you obtained yourself and
whose licence row already exists in ml/data/LICENSES.md.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from ml_pipeline.data.ingest import ingest_folder_per_class
from ml_pipeline.data.sources import (
    LICENSE_REGISTRY_PATH,
    LicenseRegistryError,
    get_source,
)

ML_ROOT = Path(__file__).resolve().parents[1]
TAXONOMY_PATH = ML_ROOT / "taxonomy" / "taxonomy_v1.yaml"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, help="e.g. khana, nutrition5k")
    parser.add_argument("--root", type=Path, required=True, help="dataset <class>/<images> root")
    parser.add_argument("--out", type=Path, required=True, help="manifest CSV to write")
    parser.add_argument("--taxonomy", type=Path, default=TAXONOMY_PATH)
    args = parser.parse_args()

    source = get_source(args.source)
    if not args.root.is_dir():
        print(f"error: --root {args.root} is not a directory", file=sys.stderr)
        return 2

    print(f"source      : {source.display_name}")
    print(f"licence     : {source.license_id}")
    print(f"shipped use : {'allowed' if source.shipped_weights_allowed else 'NOT allowed'}")
    print(f"registry    : {LICENSE_REGISTRY_PATH}")

    try:
        report = ingest_folder_per_class(
            root=args.root,
            source=source,
            taxonomy_path=args.taxonomy,
            out_csv=args.out,
        )
    except LicenseRegistryError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    print(f"mapped      : {report.mapped_images} images -> {args.out}")
    if report.unmapped:
        print(f"unmapped    : {report.unmapped_images} images dropped, by label:")
        for label, count in sorted(report.unmapped.items(), key=lambda kv: -kv[1]):
            print(f"  {label!r}: {count}")
        print("Add these dishes to the taxonomy (or an alias) and re-run; nothing was guessed.")
        return 0

    print("unmapped    : none")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
