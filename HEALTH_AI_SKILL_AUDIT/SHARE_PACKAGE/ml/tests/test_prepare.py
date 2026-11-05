"""Tests for dataset scanning/validation (Section 8.5)."""

import shutil
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from ml_pipeline.data.prepare import scan_and_validate


def make_image(
    path: Path,
    color: tuple[int, int, int] = (120, 40, 20),
    size: tuple[int, int] = (64, 64),
) -> None:
    Image.new("RGB", size, color=color).save(path, format="JPEG")


def test_extensionless_images_are_scanned(tmp_path: Path) -> None:
    """Khana ships files with no extension — PIL must still find them."""
    class_dir = tmp_path / "biryani"
    class_dir.mkdir()
    make_image(class_dir / "_abd23fhjklmnopqrst", color=(120, 40, 20))
    make_image(class_dir / "named.jpg", color=(80, 90, 200))

    rows = scan_and_validate(tmp_path)
    assert len(rows) == 2
    assert {Path(r["path"]).name for r in rows} == {
        "_abd23fhjklmnopqrst",
        "named.jpg",
    }
    assert rows[0]["label"] == "biryani"


def test_corrupt_and_tiny_files_are_dropped(tmp_path: Path) -> None:
    class_dir = tmp_path / "dal"
    class_dir.mkdir()
    (class_dir / "garbage").write_bytes(b"definitely not an image")
    make_image(class_dir / "tiny.jpg", size=(16, 16))

    assert scan_and_validate(tmp_path) == []


def test_exact_duplicates_dropped_first_wins(tmp_path: Path) -> None:
    class_dir = tmp_path / "dosa"
    class_dir.mkdir()
    # Same bytes, different names -> one row only.
    make_image(class_dir / "_aaaa")
    shutil.copyfile(class_dir / "_aaaa", class_dir / "_bbbb")

    rows = scan_and_validate(tmp_path)
    assert len(rows) == 1
    assert Path(rows[0]["path"]).name == "_aaaa"


def test_non_image_files_do_not_crash(tmp_path: Path) -> None:
    class_dir = tmp_path / "pulao"
    class_dir.mkdir()
    subdir = class_dir / "extra"
    subdir.mkdir()  # rglob yields this; must be skipped, not sliced
    make_image(class_dir / "_ok")

    rows = scan_and_validate(tmp_path)
    assert len(rows) == 1
