"""Unit tests for taxonomy_v1.yaml (AGENTS.md §5.1, §5.2, T1.1)."""

import json
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[1]
TAXONOMY_PATH = REPO_ROOT / "taxonomy" / "taxonomy_v1.yaml"
CLASSES_PATH = REPO_ROOT / "data" / "classes.json"

EXPECTED_ROLES = [
    (0, "background"),
    (1, "plate_tray"),
    (2, "bowl"),
    (3, "mounded_carb"),
    (4, "flat_bread"),
    (5, "gravy_curry"),
    (6, "dry_sabzi"),
    (7, "salad_raw"),
    (8, "condiment"),
    (9, "protein_piece"),
    (10, "other_food"),
]


def load_taxonomy():
    with open(TAXONOMY_PATH, encoding="utf-8") as f:
        return yaml.safe_load(f)


def test_roles_contract():
    data = load_taxonomy()
    roles = data["roles"]
    assert len(roles) == 11, f"Expected 11 roles, got {len(roles)}"
    for idx, (expected_id, expected_name) in enumerate(EXPECTED_ROLES):
        assert roles[idx]["id"] == expected_id
        assert roles[idx]["name"] == expected_name


def test_all_239_classes_present():
    data = load_taxonomy()
    with open(CLASSES_PATH, encoding="utf-8") as f:
        classes = json.load(f)
    assert len(classes) == 239

    catalog_dishes = [d for d in data["dishes"] if not d["taxonomy"]["is_generic"]]
    assert len(catalog_dishes) == 239, f"Expected 239 catalog dishes, got {len(catalog_dishes)}"

    catalog_raw_names = {d["raw_name"] for d in catalog_dishes}
    missing = set(classes) - catalog_raw_names
    assert not missing, f"Missing classes in taxonomy: {missing}"


def test_generic_fallbacks_per_group():
    data = load_taxonomy()
    groups = {g["group_id"] for g in data["groups"]}
    generics = [d for d in data["dishes"] if d["taxonomy"]["is_generic"]]

    assert len(generics) == len(groups), (
        f"Each of the {len(groups)} groups must have 1 generic record"
    )
    generic_groups = [d["taxonomy"]["group"] for d in generics]
    assert len(generic_groups) == len(set(generic_groups)), "Duplicate generic records for a group"
    assert set(generic_groups) == groups


def test_unique_snake_case_dish_ids():
    data = load_taxonomy()
    dish_ids = [d["dish_id"] for d in data["dishes"]]
    assert len(dish_ids) == len(set(dish_ids)), "Duplicate dish_ids found in taxonomy"
    for did in dish_ids:
        assert did == did.lower(), f"{did} must be lower case"
        assert did.replace("_", "").isalnum(), f"{did} must be alphanumeric snake_case"


def test_all_dishes_have_valid_roles():
    data = load_taxonomy()
    valid_roles = {r["name"] for r in data["roles"]}
    for d in data["dishes"]:
        role = d["taxonomy"]["role"]
        assert role in valid_roles, f"Invalid role {role} for dish {d['dish_id']}"
