"""Test the export script's label generation (the index -> dish contract).

Usage: python tools/test_label_export.py
"""

import csv
import importlib.util
import json
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    "export_onnx2tf", ROOT / "ml/scripts/export_onnx2tf.py"
)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []


def check(name, cond, detail=""):
    if cond:
        print(f"  PASS  {name}")
    else:
        print(f"  FAIL  {name} {detail}")
        failures.append(name)


with tempfile.TemporaryDirectory() as tmp:
    tmp = Path(tmp)

    # --- 1. class order matches scripts/train.py::read_classes ---
    print("class order")
    classes = ["chole", "aloo gobi", "paneer masala", "dal makhani"]
    splits = tmp / "splits.csv"
    with open(splits, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["path", "label", "split"])
        w.writeheader()
        for c in classes:
            for split in ("train", "val", "test"):
                w.writerow({"path": f"/x/{c}.jpg", "label": c, "split": split})
    got = mod.read_class_order(splits)
    check("sorted, deduplicated", got == sorted(set(classes)), f"got {got}")

    # --- 2. labels.json is written in that order ---
    print("labels.json")
    out = tmp / "labels.json"
    mod.export_labels(splits, len(classes), out)
    written = json.loads(out.read_text(encoding="utf-8"))
    check("classes match", written["classes"] == got, f"got {written['classes']}")
    check("has 'classes' key", "classes" in written)

    # --- 3. a class-count mismatch is refused, not silently exported ---
    print("mismatch guard")
    try:
        mod.export_labels(splits, 239, tmp / "labels2.json")
        check("mismatch raises SystemExit", False, "no error raised")
    except SystemExit as exc:
        check("mismatch raises SystemExit", True, str(exc))
    check(
        "no labels file written on mismatch",
        not (tmp / "labels2.json").exists(),
    )

    # --- 4. a missing splits file is refused ---
    try:
        mod.export_labels(tmp / "nope.csv", 4, tmp / "labels3.json")
        check("missing splits raises SystemExit", False)
    except SystemExit:
        check("missing splits raises SystemExit", True)

print()
if failures:
    print(f"FAILED: {failures}")
    sys.exit(1)
print("all label-export checks passed")
