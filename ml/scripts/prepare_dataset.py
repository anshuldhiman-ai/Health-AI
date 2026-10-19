#!/usr/bin/env python
"""Build a validated, deduped manifest from a class-folder dataset.
Usage:
  python scripts/prepare_dataset.py --data-root data/raw/khana/images \
      --out data/interim/khana/manifest.csv --source khana
Folder layout expected: <data-root>/<class_name>/<images...>
Output manifest columns: path,label,sha256,width,height,source
"""

from __future__ import annotations

import argparse
from collections import Counter
from pathlib import Path

from ml_pipeline.data.prepare import scan_and_validate, write_manifest


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--data-root", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--source", default="khana")
    args = ap.parse_args()
    rows = scan_and_validate(args.data_root, source=args.source)
    write_manifest(rows, args.out)
    counts = Counter(r["label"] for r in rows)
    print(f"kept {len(rows)} images across {len(counts)} classes")
    print(
        "per-class min/median/max:",
        min(counts.values()),
        sorted(counts.values())[len(counts) // 2],
        max(counts.values()),
    )
    for label, n in counts.most_common()[-10:]:
        print(f"  lowest: {label}: {n}")


if __name__ == "__main__":
    main()
