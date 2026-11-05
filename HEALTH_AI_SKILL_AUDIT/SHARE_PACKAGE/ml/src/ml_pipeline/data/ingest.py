"""Ingest a public dataset into a trainable manifest (T1.3).

The single built-and-tested layout today is `folder_per_class`
(`<root>/<class_name>/<images...>`), which covers Khana and most public food
datasets. Every row is validated and deduped by `prepare.scan_and_validate`,
then mapped onto the v1 taxonomy so training never sees a free-text label.

Rows whose source label has no taxonomy dish are NOT guessed and NOT written to
the manifest: they are returned in `IngestReport.unmapped` so a human can add
the mapping (taxonomy first, then re-run) — AGENTS.md §0 rule 3.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path

import yaml

from .prepare import MANIFEST_FIELDS as PREPARE_FIELDS
from .prepare import scan_and_validate, write_manifest
from .sources import Layout, PublicSource, assert_registered

MANIFEST_FIELDS = [*PREPARE_FIELDS, "dish_id", "role", "group"]

_SEPARATORS = re.compile(r"[_\-/]+")
_WHITESPACE = re.compile(r"\s+")


@dataclass(frozen=True)
class DishLabel:
    """The taxonomy facts training needs for one source label."""

    dish_id: str
    role: str
    group: str


@dataclass
class IngestReport:
    """What an ingest run did, so the caller can print honest numbers."""

    source: str
    rows: list[dict] = field(default_factory=list)
    unmapped: dict[str, int] = field(default_factory=dict)

    @property
    def mapped_images(self) -> int:
        return len(self.rows)

    @property
    def unmapped_images(self) -> int:
        return sum(self.unmapped.values())

    @property
    def is_complete(self) -> bool:
        """True when every scanned image found a taxonomy dish."""
        return not self.unmapped


def normalize_label(text: str) -> str:
    """`"Aloo  Gobi"`, `"aloo_gobi"`, `"aloo-gobi"` -> `"aloo gobi"`."""
    lowered = _SEPARATORS.sub(" ", text.strip().lower())
    return _WHITESPACE.sub(" ", lowered)


def load_dish_index(taxonomy_path: Path) -> dict[str, DishLabel]:
    """Map normalized dish names (raw_name and English name) to taxonomy facts."""
    with open(taxonomy_path, encoding="utf-8") as handle:
        taxonomy = yaml.safe_load(handle)

    index: dict[str, DishLabel] = {}
    for dish in taxonomy.get("dishes", []):
        label = DishLabel(
            dish_id=dish["dish_id"],
            role=dish["taxonomy"]["role"],
            group=dish["taxonomy"]["group"],
        )
        keys = {normalize_label(dish["dish_id"]), normalize_label(dish["raw_name"])}
        english = dish.get("names", {}).get("en")
        if english:
            keys.add(normalize_label(english))
        for key in keys:
            index.setdefault(key, label)
    return index


def ingest_folder_per_class(
    *,
    root: Path,
    source: PublicSource,
    taxonomy_path: Path,
    out_csv: Path,
) -> IngestReport:
    """Scan `root`, map labels to the taxonomy and write the manifest to `out_csv`.

    Raises `LicenseRegistryError` if the source has no licence row.
    """
    assert_registered(source)
    if source.layout is not Layout.FOLDER_PER_CLASS:
        raise ValueError(
            f"{source.display_name!r} uses layout {source.layout.value!r}; "
            "this ingester only handles folder-per-class datasets."
        )

    dish_index = load_dish_index(taxonomy_path)
    report = IngestReport(source=source.name)

    for row in scan_and_validate(root, source=source.name):
        dish = dish_index.get(normalize_label(row["label"]))
        if dish is None:
            report.unmapped[row["label"]] = report.unmapped.get(row["label"], 0) + 1
            continue
        report.rows.append(
            {
                **row,
                "dish_id": dish.dish_id,
                "role": dish.role,
                "group": dish.group,
            }
        )

    write_manifest(report.rows, out_csv, fields=MANIFEST_FIELDS)
    return report
