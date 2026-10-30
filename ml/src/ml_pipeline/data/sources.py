"""Registry of public ingestion sources and their licence terms (T1.3, D-02).

`ml/data/LICENSES.md` is the human-readable registry; this module is the
machine-checked copy of the parts the pipeline needs. A test fails if a source
here has no row there, so a new dataset cannot be ingested without a licence
entry (AGENTS.md §0 rule 6).
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from pathlib import Path

# ml/src/ml_pipeline/data/sources.py -> parents[3] == ml/
LICENSE_REGISTRY_PATH = Path(__file__).resolve().parents[3] / "data" / "LICENSES.md"


class Layout(Enum):
    """How a source stores its files on disk."""

    FOLDER_PER_CLASS = "folder_per_class"
    CSV_METADATA = "csv_metadata"  # ships its own metadata table; not ingested yet


@dataclass(frozen=True)
class PublicSource:
    """One external dataset we may ingest.

    `license_marker` is the literal substring identifying this dataset's row in
    `ml/data/LICENSES.md`; the guard below matches on it.
    """

    name: str
    display_name: str
    license_marker: str
    license_id: str
    layout: Layout
    shipped_weights_allowed: bool
    notes: str


class LicenseRegistryError(RuntimeError):
    """Raised when a source would be used without a licence entry or permission."""


SOURCES: tuple[PublicSource, ...] = (
    PublicSource(
        name="khana",
        display_name="Khana (arXiv 2509.06006)",
        license_marker="**Khana**",
        license_id="CC-BY-NC-ND-4.0",
        layout=Layout.FOLDER_PER_CLASS,
        shipped_weights_allowed=False,
        notes="80 Indian dish classes, ~131K images. Research baseline only.",
    ),
    PublicSource(
        name="indian_thali",
        display_name="Indian Thali Dataset (IIIT-H, ICVGIP 2025)",
        license_marker="**Indian Thali Dataset**",
        license_id="research-academic (terms pending confirmation)",
        layout=Layout.FOLDER_PER_CLASS,
        shipped_weights_allowed=False,
        notes="796 plates / 267 weighed. Terms must be confirmed with the authors.",
    ),
    PublicSource(
        name="ecoplate",
        display_name="EcoPlate (IEEE DataPort)",
        license_marker="**EcoPlate**",
        license_id="IEEE-DataPort-restricted",
        layout=Layout.FOLDER_PER_CLASS,
        shipped_weights_allowed=False,
        notes="313 plate pairs, 8 classes. Restricted academic access.",
    ),
    PublicSource(
        name="nutrition5k",
        display_name="Nutrition5k (Google Research, CVPR 2021)",
        license_marker="**Nutrition5k**",
        license_id="Apache-2.0",
        layout=Layout.CSV_METADATA,
        shipped_weights_allowed=True,
        notes="Depth + mass. Permissive; used for mass-behaviour pretraining.",
    ),
    PublicSource(
        name="foodseg103",
        display_name="FoodSeg103 / UEC-FoodPix",
        license_marker="**FoodSeg103",
        license_id="research-non-commercial",
        layout=Layout.FOLDER_PER_CLASS,
        shipped_weights_allowed=False,
        notes="Pixel masks for generic food-boundary pretraining; fine-tune on our plates.",
    ),
)

_BY_NAME = {source.name: source for source in SOURCES}


def get_source(name: str) -> PublicSource:
    """Look up a source by its short name, e.g. `khana`."""
    try:
        return _BY_NAME[name]
    except KeyError as exc:
        known = ", ".join(sorted(_BY_NAME))
        raise LicenseRegistryError(f"Unknown source {name!r}. Known sources: {known}") from exc


def registered_sources(registry_path: Path = LICENSE_REGISTRY_PATH) -> tuple[PublicSource, ...]:
    """Sources that appear in the licence registry (and may therefore be ingested)."""
    text = registry_path.read_text(encoding="utf-8")
    return tuple(source for source in SOURCES if source.license_marker in text)


def assert_registered(source: PublicSource, registry_path: Path = LICENSE_REGISTRY_PATH) -> None:
    """Fail closed when a source has no licence row (D-02, AGENTS.md §0 rule 6)."""
    text = registry_path.read_text(encoding="utf-8")
    if source.license_marker not in text:
        raise LicenseRegistryError(
            f"No licence entry for {source.display_name!r} in {registry_path}. "
            "Add a row to ml/data/LICENSES.md before ingesting this dataset."
        )


def assert_shipped_weights_allowed(source: PublicSource) -> None:
    """Guard for anything that would end up inside shipped model weights (D-02)."""
    if not source.shipped_weights_allowed:
        raise LicenseRegistryError(
            f"{source.display_name!r} is licensed {source.license_id}: usable for "
            "research baselines only, never for shipped weights. Record an owner "
            "approval in ml/data/LICENSES.md before changing this."
        )
