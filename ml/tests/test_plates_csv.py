"""Test weighed plates CSV schema (AGENTS.md §5.4, T1.2)."""

import csv
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = REPO_ROOT / "data" / "weighed_plates" / "plates.csv"

REQUIRED_COLUMNS = [
    "plate_id",
    "session_id",
    "image_paths",
    "imu_tilt_deg",
    "plate_type",
    "plate_diameter_cm",
    "container_ids",
    "item_index",
    "dish_id",
    "role",
    "net_mass_g",
    "piece_count",
    "variant",
    "lighting",
    "notes",
]

def test_plates_csv_schema():
    assert CSV_PATH.exists(), f"Missing {CSV_PATH}"
    with open(CSV_PATH, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        headers = reader.fieldnames
        assert headers == REQUIRED_COLUMNS, f"Header mismatch: {headers} vs {REQUIRED_COLUMNS}"
        rows = list(reader)
        assert len(rows) > 0, "plates.csv should have at least 1 sample row"
        for r in rows:
            assert float(r["net_mass_g"]) > 0
            assert float(r["plate_diameter_cm"]) > 0
            assert r["role"] in [
                "background", "plate_tray", "bowl", "mounded_carb", "flat_bread",
                "gravy_curry", "dry_sabzi", "salad_raw", "condiment", "protein_piece", "other_food"
            ]
