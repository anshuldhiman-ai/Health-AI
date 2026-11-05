"""Check the app's nutrition catalog against a model's class list.

The app maps a model output index to a dish through
app/assets/models/labels.json -> app/assets/nutrition/khana_catalog.json.
If a class is missing from the catalog, the scan screen silently drops
that prediction.

Usage:
  python tools/check_catalog.py <classes.txt>       # one class per line
  python tools/check_catalog.py --classes-from splits.csv
"""

import argparse
import csv
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "app/assets/nutrition/khana_catalog.json"


def load_catalog():
    data = json.loads(CATALOG.read_text(encoding="utf-8"))
    return data["classes"], data["dishes"]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("classes_file", nargs="?", type=Path)
    ap.add_argument("--classes-from", type=Path, help="training splits CSV")
    args = ap.parse_args()

    if args.classes_from:
        with open(args.classes_from, newline="", encoding="utf-8") as f:
            classes = sorted({row["label"] for row in csv.DictReader(f)})
    elif args.classes_file:
        raw = args.classes_file.read_text(encoding="utf-8").strip()
        if raw.startswith("{"):
            # labels.json: {"classes": [...]}
            classes = json.loads(raw)["classes"]
        else:
            classes = [line.strip() for line in raw.splitlines() if line.strip()]
    else:
        ap.error("pass a classes file or --classes-from")

    catalog_classes, dishes = load_catalog()
    catalog_set = set(catalog_classes)

    missing = [c for c in classes if c not in catalog_set]
    no_dish = [c for c in classes if c not in dishes]

    print(f"model classes        : {len(classes)}")
    print(f"catalog classes      : {len(catalog_classes)}")
    print(f"catalog dishes       : {len(dishes)}")
    print(f"classes not in catalog: {len(missing)}")
    print(f"classes with no dish : {len(no_dish)}")

    if missing:
        print("\nfirst 20 missing:")
        for c in missing[:20]:
            print(f"  {c}")
    if no_dish:
        print("\nfirst 20 without a dish row:")
        for c in no_dish[:20]:
            print(f"  {c}")

    # The app maps a model output index to a dish by NAME
    # (labels.json[index] -> catalog[label]), so the catalog's own
    # (sorted) order does not have to match the model's order. What
    # must hold is that every model class has a dish.
    dupes = [c for c in set(catalog_classes) if catalog_classes.count(c) > 1]
    if dupes:
        print(f"\nDUPLICATE class names: {len(dupes)} -> {sorted(dupes)[:10]}")

    if missing or no_dish or dupes:
        print("\nRESULT: the catalog needs regenerating for this model")
        return 1
    print("\nRESULT: catalog covers every model class")
    return 0


if __name__ == "__main__":
    sys.exit(main())
