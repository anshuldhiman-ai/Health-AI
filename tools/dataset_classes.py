"""Extract the class list of the training dataset (no images downloaded).

The model's output index is the SORTED set of the dataset's class
folders (see `scripts/train.py::read_classes`), and the app's
labels.json must use that same order. The catalog's class list cannot
be used for this: it was hand-extended and does not match the model's
class set (the catalog has 259 unique names, the model has 239).

This uses Kaggle's tree endpoint (`ListTreeDatasetFiles`), which
returns the directory structure directly. The flat file-listing
endpoint pages at 200 files and its token chain expires after ~60
pages, which cannot enumerate a 156k-file dataset.

Usage: python tools/dataset_classes.py [owner/dataset]
"""

import json
import os
import sys
from pathlib import Path

DEFAULT = "kashyap077/indian-food-images-for-model-fine-tuning-2026"
ROOT = Path(__file__).resolve().parents[1]
PAGE_SIZE = 200


def main() -> int:
    dataset = sys.argv[1] if len(sys.argv) > 1 else DEFAULT
    owner, slug = dataset.split("/", 1)

    os.environ.setdefault("KAGGLE_USERNAME", "nsul07")
    from kaggle.api.kaggle_api_extended import KaggleApi
    from kagglesdk.datasets.services.dataset_api_service import (
        ApiListTreeDatasetFilesRequest,
    )

    api = KaggleApi()
    api.authenticate()

    def tree_at(path: str, token: str = ""):
        with api.build_kaggle_client() as kaggle:
            request = ApiListTreeDatasetFilesRequest()
            request.owner_slug = owner
            request.dataset_slug = slug
            request.page_size = PAGE_SIZE
            request.page_token = token
            if path:
                request.path = path
            return kaggle.datasets.dataset_api_client.list_tree_dataset_files(request)

    # The root's single directory is "Images", and it reports how many
    # class folders it holds.
    root = tree_at("")
    images = next(
        (d for d in (root.directories or []) if d.name.lower() == "images"),
        None,
    )
    if images is None:
        print("error: no 'Images' directory in the dataset", file=sys.stderr)
        return 1
    expected = images.total_directories
    print(f"dataset   : {dataset}")
    print(f"classes   : {expected} (per the dataset tree)")

    # The class folders are the directories under "Images". The tree
    # endpoint pages at 200, so walk the pages.
    names: set[str] = set()
    token = ""
    while True:
        page = tree_at("Images", token)
        for directory in page.directories or []:
            names.add(directory.name)
        token = page.next_page_token
        if not token:
            break

    classes = sorted(names)
    print(f"collected : {len(classes)}")
    if len(classes) != expected:
        print(
            f"error: expected {expected} classes but collected {len(classes)}",
            file=sys.stderr,
        )
        return 1

    out = ROOT / "ml/data/classes.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(classes, indent=2) + "\n", encoding="utf-8")
    print(f"written   : {out}")
    for c in classes:
        print(f"  {c}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
