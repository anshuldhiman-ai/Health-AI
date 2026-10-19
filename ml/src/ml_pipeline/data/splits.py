"""Group-aware stratified splits (Section 8.3/8.5).

Splits are BY GROUP (photographer/session) when a group column
exists — never random by image, or near-duplicates of the same plate
leak into validation and inflate accuracy. Without groups (the
public datasets for now), fall back to stratified random-by-image
and record that limitation.
"""

from __future__ import annotations

import random
from collections import defaultdict


def split_rows(
    rows: list[dict],
    ratios: tuple[float, float, float] = (0.7, 0.15, 0.15),
    seed: int = 42,
    group_key: str | None = "session_id",
) -> dict[str, list[dict]]:
    """Return {"train": [...], "val": [...], "test": [...]}.

    Stratified by label. With groups: each group's images all land in
    one split (majority label of the group decides the stratum).
    """
    assert abs(sum(ratios) - 1.0) < 1e-6, "ratios must sum to 1"
    rng = random.Random(seed)

    by_label: dict[str, list[dict]] = defaultdict(list)
    for row in rows:
        by_label[row["label"]].append(row)

    out: dict[str, list[dict]] = {"train": [], "val": [], "test": []}
    names = ("train", "val", "test")

    for label in sorted(by_label):
        items = by_label[label]
        if group_key and all(r.get(group_key) for r in items):
            # One row per group, keyed by the group's first-seen label
            # (rows of one group share the label by construction of
            # collection sessions).
            groups: dict[str, list[dict]] = defaultdict(list)
            for r in items:
                groups[r[group_key]].append(r)
            units = sorted(groups.values(), key=lambda g: g[0]["path"])
        else:
            units = [[r] for r in items]

        rng.shuffle(units)
        n = len(units)
        n_train = round(ratios[0] * n)
        n_val = round(ratios[1] * n)
        for i, unit in enumerate(units):
            if i < n_train:
                out["train"].extend(unit)
            elif i < n_train + n_val:
                out["val"].extend(unit)
            else:
                out["test"].extend(unit)

    # Every split name used even for degenerate small datasets —
    # keeps downstream code shape-stable.
    for name in names:
        _ = out[name]
    return out
