"""Tests for group-aware stratified splits (Section 8.3)."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from ml_pipeline.data.splits import split_rows


def rows(n: int, label: str, group: str | None = None, offset: int = 0) -> list[dict]:
    out = []
    for i in range(n):
        out.append(
            {
                "path": f"r/{label}/{offset + i}.jpg",
                "label": label,
                **({"session_id": group} if group else {}),
            }
        )
    return out


def test_all_rows_assigned_exactly_once() -> None:
    data = rows(60, "dal") + rows(40, "dosa")
    split = split_rows(data, seed=1)
    total = sum(len(v) for v in split.values())
    assert total == len(data)
    paths = [r["path"] for s in split.values() for r in s]
    assert len(paths) == len(set(paths)), "no row in two splits"


def test_stratification_keeps_class_proportions() -> None:
    data = rows(60, "dal") + rows(20, "dosa", offset=100)
    split = split_rows(data, seed=3)
    for split_name, want in (("train", 0.7), ("val", 0.15)):
        labels = [r["label"] for r in split[split_name]]
        dal = labels.count("dal")
        dosa = labels.count("dosa")
        assert abs(dal - want * 60) <= 2, (split_name, dal)
        assert abs(dosa - want * 20) <= 2, (split_name, dosa)


def test_groups_never_span_splits() -> None:
    data = []
    for g in range(10):
        data += rows(10, "dal", group=f"s{g}", offset=g * 100)
    split = split_rows(data, seed=5)
    seen: dict[str, str] = {}
    for split_name, split_rows_list in split.items():
        for r in split_rows_list:
            g = r["session_id"]
            if g in seen:
                assert seen[g] == split_name, f"group {g} leaked into two splits"
            seen[g] = split_name


def test_deterministic_for_same_seed() -> None:
    data = rows(50, "dal") + rows(50, "dosa", offset=99)
    a = split_rows(data, seed=7)
    b = split_rows(data, seed=7)
    assert [r["path"] for r in a["train"]] == [r["path"] for r in b["train"]]


def test_split_changes_with_seed() -> None:
    data = rows(50, "dal") + rows(50, "dosa", offset=99)
    a = split_rows(data, seed=7)
    b = split_rows(data, seed=8)
    assert [r["path"] for r in a["train"]] != [r["path"] for r in b["train"]]
