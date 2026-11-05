"""Taxonomy validation (Section 8.4).

labels.yaml is the single source of truth for the model's class
labels. These tests keep its structure sane so downstream consumers
(nutrition.db label_map, export, Dart labels.json) can rely on it.
"""

from pathlib import Path

import yaml

TAXONOMY = Path(__file__).resolve().parents[1] / "taxonomy" / "labels.yaml"

REQUIRED_LOCALES = ("en", "hi", "pa")
SPECIAL_CLASSES = {"other_food", "not_food"}


def load_taxonomy() -> dict:
    with open(TAXONOMY, encoding="utf-8") as f:
        return yaml.safe_load(f)


def test_version_is_present_and_int() -> None:
    data = load_taxonomy()
    assert isinstance(data["version"], int)
    assert data["version"] >= 1


def test_special_classes_always_exist() -> None:
    """other_food and not_food back the reject option (Section 8.7.8)."""
    ids = {c["id"] for c in load_taxonomy()["classes"]}
    assert SPECIAL_CLASSES.issubset(ids)


def test_class_ids_are_unique_and_snake_case() -> None:
    ids = [c["id"] for c in load_taxonomy()["classes"]]
    assert len(ids) == len(set(ids)), "duplicate class ids"
    for class_id in ids:
        assert class_id == class_id.lower(), f"{class_id} must be snake_case"
        assert class_id.replace("_", "").isalnum(), f"bad id: {class_id}"


def test_every_class_has_all_ui_locales() -> None:
    """Labels ship in en/hi/pa (R13: no hard-coded user-facing strings)."""
    for c in load_taxonomy()["classes"]:
        names = c.get("names", {})
        missing = [loc for loc in REQUIRED_LOCALES if not names.get(loc)]
        assert not missing, f"{c['id']} missing locales: {missing}"


def test_food_ids_and_servings_are_structured() -> None:
    for c in load_taxonomy()["classes"]:
        assert isinstance(c.get("food_ids", []), list), c["id"]
        serving = c.get("default_serving")
        if serving is not None:
            assert set(serving) == {"label", "grams"}, c["id"]
            assert serving["grams"] > 0, c["id"]
