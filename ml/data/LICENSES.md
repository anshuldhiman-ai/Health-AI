# LICENSES.md — ML Datasets & Weights License Registry

> **Locked Decision D-02**: Shipped code and weights must be permissive (Apache-2.0 / MIT / BSD / CC0 / CC-BY with attribution).
> Ultralytics YOLO (AGPL-3.0) is banned from shipped artifacts.
> Non-commercial datasets may be used for *research baselines only*, never for shipped weights, unless the owner approves.

---

## Dataset License Registry

| Dataset | Modality / Task | Stated License | Commercial Use Permitted? | Shipped Weights Allowed? | Status / Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Khana** (arXiv 2509.06006) | ~131K images, 80 Indian dishes | CC BY-NC-ND 4.0 | No (Non-commercial) | **No** (Research baseline only) | Verified (Prabhu, 2025). Used for pretraining / experiments only. |
| **Indian Thali Dataset** (IIIT-H, ICVGIP 2025) | 796 plates, 267 weighed plates | Research / Academic | Pending confirmation | **Ask Owner** before training shipped weights | Verify terms with IIIT-H authors. |
| **EcoPlate** (IEEE DataPort) | 313 plate pairs, 8 classes | IEEE DataPort / Restricted | No / Restricted | **No** (Research-only) | Verified. Restricted academic access. |
| **Nutrition5k** (Google Research, CVPR 2021) | 5K dishes, depth + weight + kcal | Apache-2.0 / CC-BY-4.0 (Google Research) | Yes (permissive) | **Yes** (Attribution required) | Benchmark for volume & mass pretraining. |
| **FoodSeg103 / UEC-FoodPix** | 9,490 images, 103 classes, pixel masks | Non-Commercial / Research | No | **No** (Research pretraining only) | Used for generic food boundary pretraining; fine-tune on consented plates. |
| **SAM 2** (Meta) | Teacher segmentation model | Apache-2.0 | Yes | **Teacher only** (Never shipped in app) | Used offline to bootstrap annotations in `sam_preannotate.py`. |
| **IFCT 2017** | Indian Food Composition Tables | ICMR / Govt. of India | Educational / Non-commercial research | **Verify Redistribution** | Source for raw ingredient nutrient tables in `dish_catalog.json`. |
| **USDA FoodData Central** | Ingredient & recipe nutrition | CC0 / Public Domain | Yes | **Yes** | US Department of Agriculture. Permissive. |
| **Self-Collected Plates** (`ml/data/weighed_plates/`) | Weighed Indian thalis & mixed plates | Proprietary (Health AI Owner) | Yes | **Yes** (Primary dataset for shipped weights) | 100% consented photos + scale measurements. |

---

## License Verification Rules
1. Every new dataset introduced must have an entry here **before** code ingests it.
2. If license terms are ambiguous, mark `Ask Owner` and do not use for training shipped models.
3. Shipped `.tflite` model cards in `docs/model_cards/` must link to this document.
