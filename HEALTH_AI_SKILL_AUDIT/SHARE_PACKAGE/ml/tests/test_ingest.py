"""Tests for public-data ingestion and licence guards (T1.3, D-02)."""

import csv
import sys
from pathlib import Path

import pytest
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from ml_pipeline.data.ingest import (
    MANIFEST_FIELDS,
    ingest_folder_per_class,
    load_dish_index,
    normalize_label,
)
from ml_pipeline.data.sources import (
    SOURCES,
    LicenseRegistryError,
    assert_registered,
    assert_shipped_weights_allowed,
    get_source,
    registered_sources,
)

ML_ROOT = Path(__file__).resolve().parents[1]
TAXONOMY_PATH = ML_ROOT / "taxonomy" / "taxonomy_v1.yaml"


def make_image(path: Path, color: tuple[int, int, int] = (120, 40, 20)) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.new("RGB", (64, 64), color=color).save(path, format="JPEG")


def build_class_folders(root: Path) -> None:
    make_image(root / "biryani" / "a.jpg", color=(10, 20, 30))
    make_image(root / "aloo gobi" / "b.jpg", color=(40, 50, 60))
    make_image(root / "mystery dish" / "c.jpg", color=(70, 80, 90))
    make_image(root / "mystery dish" / "d.jpg", color=(100, 110, 120))


# --- label normalisation and taxonomy lookup -------------------------------


@pytest.mark.parametrize(
    ("raw", "expected"),
    [
        ("Aloo  Gobi", "aloo gobi"),
        ("aloo_gobi", "aloo gobi"),
        ("Aloo-Gobi", "aloo gobi"),
        ("  DAL   MAKHANI ", "dal makhani"),
        ("biryani", "biryani"),
    ],
)
def test_normalize_label(raw: str, expected: str) -> None:
    assert normalize_label(raw) == expected


def test_dish_index_maps_ids_names_and_english_names() -> None:
    index = load_dish_index(TAXONOMY_PATH)
    for key in ("aloo gobi", "aloo_gobi", "Aloo Gobi"):
        dish = index[normalize_label(key)]
        assert dish.dish_id == "aloo_gobi"
        assert dish.role == "dry_sabzi"
        assert dish.group == "dry_potato_sabzi"


# --- folder-per-class ingestion -------------------------------------------


def test_ingest_maps_labels_and_reports_unmapped(tmp_path: Path) -> None:
    root = tmp_path / "raw"
    build_class_folders(root)
    out_csv = tmp_path / "manifest.csv"

    report = ingest_folder_per_class(
        root=root,
        source=get_source("khana"),
        taxonomy_path=TAXONOMY_PATH,
        out_csv=out_csv,
    )

    assert report.mapped_images == 2
    assert report.unmapped == {"mystery dish": 2}
    assert report.is_complete is False

    by_label = {row["label"]: row for row in report.rows}
    assert by_label["biryani"]["dish_id"] == "biryani"
    assert by_label["biryani"]["role"] == "mounded_carb"
    assert by_label["aloo gobi"]["group"] == "dry_potato_sabzi"
    assert all(row["source"] == "khana" for row in report.rows)

    with open(out_csv, newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        assert reader.fieldnames == MANIFEST_FIELDS
        written = list(reader)
    assert len(written) == 2
    assert {row["dish_id"] for row in written} == {"biryani", "aloo_gobi"}


def test_empty_root_writes_header_only(tmp_path: Path) -> None:
    root = tmp_path / "raw"
    root.mkdir()
    out_csv = tmp_path / "manifest.csv"

    report = ingest_folder_per_class(
        root=root,
        source=get_source("khana"),
        taxonomy_path=TAXONOMY_PATH,
        out_csv=out_csv,
    )

    assert report.is_complete is True
    assert report.mapped_images == 0
    assert out_csv.read_text(encoding="utf-8").splitlines() == [",".join(MANIFEST_FIELDS)]


def test_unsupported_layout_is_refused(tmp_path: Path) -> None:
    with pytest.raises(ValueError, match="folder-per-class"):
        ingest_folder_per_class(
            root=tmp_path,
            source=get_source("nutrition5k"),
            taxonomy_path=TAXONOMY_PATH,
            out_csv=tmp_path / "manifest.csv",
        )


def test_ingest_runs_the_licence_guard(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    root = tmp_path / "raw"
    build_class_folders(root)

    def blocked(*args: object, **kwargs: object) -> None:
        raise LicenseRegistryError("blocked by the test double")

    monkeypatch.setattr("ml_pipeline.data.ingest.assert_registered", blocked)

    with pytest.raises(LicenseRegistryError):
        ingest_folder_per_class(
            root=root,
            source=get_source("khana"),
            taxonomy_path=TAXONOMY_PATH,
            out_csv=tmp_path / "manifest.csv",
        )
    assert not (tmp_path / "manifest.csv").exists()


# --- licence registry guards ----------------------------------------------


def test_every_known_source_has_a_licence_row() -> None:
    assert {source.name for source in registered_sources()} == {source.name for source in SOURCES}


def test_unknown_source_name_raises() -> None:
    with pytest.raises(LicenseRegistryError, match="Unknown source"):
        get_source("kaggle-random-food")


def test_missing_registry_row_blocks_ingestion(tmp_path: Path) -> None:
    empty_registry = tmp_path / "LICENSES.md"
    empty_registry.write_text("# no datasets here\n", encoding="utf-8")

    with pytest.raises(LicenseRegistryError, match=r"LICENSES\.md"):
        assert_registered(get_source("khana"), registry_path=empty_registry)


def test_research_only_sources_cannot_ship_in_weights() -> None:
    with pytest.raises(LicenseRegistryError, match="never for shipped weights"):
        assert_shipped_weights_allowed(get_source("khana"))

    assert_shipped_weights_allowed(get_source("nutrition5k"))  # Apache-2.0: no raise
