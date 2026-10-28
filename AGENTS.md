# AGENTS.md — Health AI · 100% Offline Thali Vision & Nutrition Engine

> **Audience**: AI coding agents (Claude etc.) and the human owner.
> **Owner**: Anshul Dhiman (2nd-year AI/ML student). **App**: Health AI (Flutter, Android-first).
> **Status of this file**: single source of truth for the *scan / vision / nutrition* feature. Version 2.0.
> **Supersedes**: the earlier AGENTS.md (YOLO-seg + fixed-height plan). Reasons are in §2 (D-02, D-05, D-08).

---

## 0. READ THIS FIRST — how to work (agent protocol)

**Reading order** (every new session): (1) this file → (2) `CLAUDE.md` → (3) `docs/PROGRESS.md` → (4) the task you are about to do.

**Precedence if two documents disagree**:
1. `CLAUDE.md` code-style/invariants →
2. this `AGENTS.md` (scope, architecture, decisions) →
3. a *newer* ADR in `docs/adr/` (only for the one decision it explicitly supersedes) →
4. code comments.

**Task loop** (follow exactly):
1. Open `docs/PROGRESS.md`. Take the **lowest-numbered unchecked task whose dependencies are done**. Never skip ahead past a *Gate* (§8).
2. For pure logic (geometry, mass, nutrition, mask post-processing): **write the test first**, then the code.
3. Run the checks in §10 (`tools/check_all.sh` once T0.3 exists).
4. Tick the task in `docs/PROGRESS.md`, add one line: *what changed · evidence (test/metric file)*.
5. Stop and report. Do not start the next task unless asked or unless running in autonomous mode.

**Ten golden rules**
1. **Offline only.** No network call, no cloud API, no analytics, no `INTERNET` permission in the release manifest.
2. **One phase at a time.** A phase is done only when its Gate passes with evidence saved in `ml/reports/` or `docs/reports/`.
3. **Never invent numbers.** Every accuracy/latency/size figure must come from a script that writes a file. If you do not have the number, write `TBD` — never a guess.
4. **No hardcoded nutrition in code.** Calories/macros/densities live in `dish_catalog.json` only (§5).
5. **Every gram and kcal is a range** (P10 / P50 / P90), never a single false-precision value.
6. **License hygiene.** Nothing AGPL/GPL/non-commercial goes into a *shipped* model or app code (D-02). Log every dataset/library license.
7. **The baseline keeps working.** `baseline.tflite` + single-dish flow remain the fallback until Gate G10.
8. **Don't weaken tests** to make them pass. Fix the code or open an ADR.
9. **Placeholders are loud.** Any unvalidated constant is marked `PLACEHOLDER(Txx)` in code/JSON; `tools/check_placeholders.sh` must return zero before release.
10. **Small, reversible steps.** Ambiguity ⇒ choose the option that is (a) offline, (b) test-green, (c) easiest to undo; record it as an ADR (`docs/adr/NNNN-title.md`, 10 lines max) and continue.

**Ask the owner only when**: a license conflict appears, a step needs a human (photographing/weighing food, annotating, buying hardware), money is involved, or a *Locked Decision* (§2) would need to change.

---

## 1. Mission, honest accuracy contract, targets

**Mission**: point the phone at any meal — including a multi-dish Indian thali — and get an itemized, editable breakdown (dish · grams range · kcal range · macros) that logs to the diary in one tap, entirely on-device.

**Honest accuracy contract** (so nobody over-promises):
- One photo cannot reveal hidden oil/ghee, depth under a mound, or what is under another food. Published single-image calorie systems typically report errors in the mid-teens to ~25 % range on curated data; thalis are harder.
- "Maximum accuracy" therefore means: **(1) measure everything measurable** (scale, tilt, area, count), **(2) calibrate against real weighed Indian plates**, **(3) show uncertainty honestly**, **(4) make correction 1-tap and learn from it on-device**.

**v1 ship gates** (change only via ADR). Measured on the frozen **golden set** (§9), on the **Reference Low-End Device (RLD)**:

| Area | Metric | Gate (must) | Stretch |
| :--- | :--- | :--- | :--- |
| Segmentation | food-role mIoU / plate IoU | ≥ 0.70 / ≥ 0.93 | ≥ 0.78 / ≥ 0.96 |
| Classification | top-1 / top-3 on thali crops (239 dishes) | ≥ 85 % / ≥ 95 % | ≥ 90 % / ≥ 97 % |
| Mass | median per-item absolute % error | ≤ 25 % | ≤ 18 % |
| Calories | median total-meal absolute % error | ≤ 20 % | ≤ 15 % |
| Intervals | coverage of nominal 80 % P10–P90 | 70–88 % | 75–85 % |
| Latency | scan→result, p50 / p90 | ≤ 1.6 s / ≤ 2.5 s | ≤ 1.0 s / ≤ 1.8 s |
| Memory | peak RAM during scan | ≤ 350 MB | ≤ 250 MB |
| Size | all models + catalog in APK | ≤ 40 MB | ≤ 30 MB |
| Robustness | consecutive scans, no leak/crash | 50 | 200 |

**Out of scope for v1**: drinks in opaque cups, soups in deep opaque pots, packaged foods (barcode path already exists), video capture, iOS.

---

## 2. Locked decisions (do not re-debate; change only via ADR + owner approval)

| ID | Decision | Why |
| :--- | :--- | :--- |
| **D-01** | 100 % offline. Release manifest has **no `INTERNET`** permission. Only `CAMERA` (+ sensors, which need no permission). CI script enforces it. | Core product promise & privacy. |
| **D-02** | Shipped code **and** weights must be permissive (Apache-2.0 / MIT / BSD / CC0 / CC-BY with attribution). **Ultralytics YOLO (AGPL-3.0) is banned from shipped artifacts**; allowed only in throw-away `ml/experiments/`. Every library → `docs/THIRD_PARTY.md`; every dataset → `ml/data/LICENSES.md`. Non-commercial datasets may be used for *research baselines only*, never for shipped weights, unless the owner approves. | "Scale freely": no license blocker later. |
| **D-03** | Runtime: `flutter_litert` (LiteRT). v1 uses the same `Interpreter` API as existing `food_recognizer.dart`; each model lives inside **one long-lived worker isolate**. Evaluating `CompiledModel` (LiteRT Next, GPU/NPU) is task T10.1. | Lowest migration risk first, speed later. |
| **D-04** | Training: PyTorch + `timm` + `segmentation_models_pytorch` (MIT), env by `uv`, data by DVC. Export: **`litert-torch`** (Google's PyTorch→`.tflite` converter, formerly ai-edge-torch) with `ai-edge-quantizer` for INT8; fallback = existing PyTorch→ONNX→TFLite exporter in `ml/src/ml_pipeline/export/`. **Read the current official docs before writing exporters — this API moves fast.** | Direct, supported path; avoids YOLO-seg INT8 head problems. |
| **D-05** | **Segmenter = semantic segmentation, 11 role classes** (§5.1): `timm` MobileNetV4-Conv-Small encoder + FPN/UNet-lite decoder (via `smp` `tu-mobilenetv4_conv_small`; if that encoder fails, hand-write a small FPN over `timm.create_model(..., features_only=True)`). Instances = connected components + watershed split (T6.3). Labels bootstrapped with **SAM 2 (Apache-2.0) as an offline teacher**, then human-verified. SAM is *never* shipped. | Permissive, quantizes well, cheap to label at scale. |
| **D-06** | **Classifier = embedding + prototypes.** MobileNetV4-Conv-Medium → 256-d L2-normalized embedding → cosine similarity to a bundled prototype matrix (`dish_prototypes.bin`, ≤ 3 prototypes per dish). Trained with normalized-softmax (small angular margin). **Adding a new dish = compute its prototypes from ≥ 10 images; no network retraining.** Open-set threshold τ for "Unknown". | Scales to 500+ dishes freely; supports "teach my dish" on-device. |
| **D-07** | Geometry is **pure Dart, deterministic, unit-tested** (no OpenCV dependency in v1): round plate → ellipse fit; rectangular tray → 4-corner homography; camera tilt fused with **phone IMU** (gravity vector). | Testable, small APK, fewer native crashes. |
| **D-08** | **Mass = physics prior × data-calibrated correction**, reported as P10/P50/P90. Katori uses a **spherical-cap bowl model**, not a fixed cylinder. Piece-based foods (roti, idli, egg…) use **count × unit mass**. A learned residual model (MLP/GBM) or depth cue is adopted **only** if it passes the T8.4 gate. | Fixed-height priors alone cannot tell 150 g from 500 g. |
| **D-09** | **Nutrition source of truth** = `dish_catalog.json`, generated by script from recipes (ingredient tables + cooking-yield + oil factors), per-100 g cooked values, with **variants** (e.g. `home_light_oil`, `home_regular`, `restaurant_rich`) and **provenance**. Sources: IFCT 2017 (Indian ingredients), USDA FoodData Central (CC0), label data. No LLM-generated numbers, ever. Record IFCT redistribution terms in `docs/THIRD_PARTY.md`; if unclear → ask owner. | Accuracy and auditability. |
| **D-10** | **3-level taxonomy**: role (11) → group (~40) → dish (239 now, 500+ later). Every group has a `generic` record; when dish confidence is low but the group is consistent, use the group-generic record with wider intervals. `dish_id` is immutable snake_case, never reused. | Graceful degradation instead of wrong confident answers. |
| **D-11** | Personalization is on-device only: per-user per-dish correction factor with shrinkage (T9.1) and user-taught dishes (T9.2). Data never leaves the device. | Accuracy that improves with use, still offline. |
| **D-12** | Keep existing stack: Clean Architecture + Riverpod + GoRouter + Hive/SQLite `LogStore`. Do not swap state management or DB for this feature. | Avoid churn. |
| **D-13** | Models are versioned by `app/assets/models/model_manifest.json` (SHA-256, input shapes, quant params, taxonomy version, eval metrics). If the manifest ≠ assets, the app **fails closed to the baseline flow**. | Safe upgrades, no silent mismatch. |

---

## 3. Architecture

```
 Camera still (+ IMU tilt)                       User profile: "My Plates"
        │                                         (plate Ø / tray size / katori size)
        ▼                                                    │
 [Preprocess: native downscaled decode → 512×512 RGB]        │
        │                                                    │
        ▼                                                    ▼
 [Model 1: Role Segmenter INT8] ──► role map ──► [Mask post-process]
                                               components · watershed · polygons
                                               container association (food ⊂ bowl)
                                                     │                │
                      ┌──────────────────────────────┘                │
                      ▼                                               ▼
        [Model 2: Dish Embedder INT8]                     [Plate Geometry (Dart)]
        crops 224² ► embedding ► cosine vs prototypes     ellipse / homography + IMU
        ► top-K + role prior + generic fallback           ► cm/px, tilt θ, area_cm² per region
                      │                                               │
                      └───────────────┬───────────────────────────────┘
                                      ▼
                     [Mass Engine (Dart): volume|piece → grams P10/P50/P90]
                     physics prior × calibration × personal factor
                                      ▼
                     [Nutrition Calculator: catalog + variant → kcal/macros ranges]
                                      ▼
                     [Multi-item result sheet → one-tap atomic "Log all"]
```

**Bundled assets** (`app/assets/models/`):

| File | Purpose | Budget |
| :--- | :--- | :--- |
| `food_segmenter.tflite` | role segmenter INT8 | ≤ 8 MB |
| `dish_embedder.tflite` | MobileNetV4-M embedder INT8 | ≤ 12 MB |
| `dish_prototypes.bin` | float16 matrix [N_protos × 256] + index | ≤ 1 MB |
| `dish_catalog.json` | taxonomy + nutrition + measure + variants | ≤ 3 MB |
| `container_profiles.json` | plate/tray/katori geometry presets | ≤ 50 KB |
| `mass_calibration.json` | per-role/dish correction + quantiles | ≤ 200 KB |
| `model_manifest.json` | versions, hashes, metrics | ≤ 20 KB |
| `baseline.tflite`, `labels.json` | **existing fallback — do not touch before G10** | existing |

**Latency budget on RLD (to be measured in T6.6, not assumed)**: preprocess ≤ 120 ms · segmenter ≤ 400 ms · post-process ≤ 150 ms · embedder ≤ 60 ms × ≤ 8 crops (batched/sequential) · geometry+mass+nutrition ≤ 30 ms · UI overlay ≤ 100 ms.

---

## 4. Repository map (`[E]` exists · `[N]` create)

```
Health AI/
├── AGENTS.md                         [E→replace by this]
├── CLAUDE.md                         [E]
├── tools/                            [N] check_all.sh, check_offline.sh, check_placeholders.sh, check_licenses.sh
├── docs/
│   ├── PROGRESS.md                   [N] task checklist = state across sessions
│   ├── THIRD_PARTY.md  BENCHMARKS.md [N]
│   ├── adr/                          [N] one file per decision change
│   ├── specs/annotation_guide.md     [N] role-labeling rules
│   ├── specs/capture_sop.md          [N] how to photograph + weigh plates
│   └── model_cards/                  [N] one per shipped model
├── ml/
│   ├── data/{LICENSES.md, weighed_plates/, splits/}      [N]
│   ├── configs/{seg_v1.yaml, emb_v1.yaml}                [N]
│   ├── taxonomy/taxonomy_v1.yaml                         [N]
│   ├── catalog/{recipes/, build_catalog.py, validate_catalog.py}  [N]
│   ├── scripts/{sam_preannotate.py, train_segmenter.py, train_embedder.py,
│   │            build_prototypes.py, export_models.py, eval_golden.py, fit_mass_calibration.py} [N]
│   ├── src/ml_pipeline/{data,models,train,eval,export,utils}      [E]
│   ├── src/ml_pipeline/mass/reference.py                 [N] Python reference of Dart math
│   ├── reports/                                          [N] metrics JSON/MD (committed)
│   └── dvc.yaml, pyproject.toml                          [E]
└── app/
    ├── assets/models/                                    [E+N] see §3
    ├── lib/domain/entities/      scan_result.dart, dish_record.dart, plate_geometry.dart   [N]
    ├── lib/domain/services/      plate_geometry_calculator.dart, volumetric_math.dart,
    │                             mass_estimator.dart, nutrition_calculator.dart,
    │                             personal_calibration.dart                                  [N]
    ├── lib/data/sensors/         capture_tilt_service.dart                                  [N]
    ├── lib/data/nutrition/       dish_catalog_repository.dart                               [N]
    ├── lib/features/scan/application/
    │     food_recognizer.dart [E, fallback]   scan_worker.dart  segmenter_runner.dart
    │     embedder_runner.dart  mask_postprocess.dart  multi_food_pipeline.dart  scan_state.dart [N]
    ├── lib/features/scan/presentation/
    │     scan_screen.dart [E→extend]  multi_scan_result_sheet.dart  region_editor_sheet.dart [N]
    └── test/ (+ test/fixtures/: mass_vectors.json, 10 sample plate images, synthetic masks)
```

---

## 5. Data contracts

### 5.1 Role classes (segmenter output, fixed order — do not renumber)

`0 background · 1 plate_tray · 2 bowl · 3 mounded_carb · 4 flat_bread · 5 gravy_curry · 6 dry_sabzi · 7 salad_raw · 8 condiment · 9 protein_piece · 10 other_food`

Labeling rules (full text in `docs/specs/annotation_guide.md`): `bowl` = visible rim/exterior ring only; the *contents* take the food role. Curd/raita/kadhi → `gravy_curry`. Papad/roti/naan/dosa → `flat_bread`. Sweets, fruit, fried snacks → `other_food`. Overlapping rotis in a stack = one region (count is entered by the user).

### 5.2 `dish_catalog.json` (one record, all fields required unless marked optional)

```json
{
  "dish_id": "dal_tadka",
  "names": {"en": "Dal Tadka", "hi": "दाल तड़का"},
  "aliases": ["yellow dal", "arhar dal tadka"],
  "taxonomy": {"role": "gravy_curry", "group": "dal", "cuisine": ["north_indian"], "is_generic": false},
  "measure": {
    "mode": "volume",                         // "volume" | "piece"
    "density_g_per_ml": {"p10": 1.00, "p50": 1.04, "p90": 1.08},
    "piece_mass_g": null,                     // piece mode: {"p10":28,"p50":36,"p90":46}
    "reference_piece_area_cm2": null,         // piece mode: area of a typical piece
    "serving_default_g": 150
  },
  "nutrition_per_100g": {"kcal": 118, "protein_g": 6.1, "carb_g": 15.8, "fat_g": 3.2,
                          "fiber_g": 3.6, "sugar_g": 1.4, "sodium_mg": 310, "micros": {}},
  "variants": [
    {"id": "home_light_oil",   "fat_delta_g_per_100g": -1.5},
    {"id": "home_regular",     "fat_delta_g_per_100g": 0.0},
    {"id": "restaurant_rich",  "fat_delta_g_per_100g": 3.5}
  ],
  "provenance": {"recipe_id": "dal_tadka_v1", "sources": ["IFCT2017", "USDA_FDC"], "yield_factor": 2.4, "reviewed_by": "owner", "date": "2026-11-01"}
}
```
*(Numbers above are illustrative formatting only — real values come from `build_catalog.py`.)* Validator rules (`validate_catalog.py`): unique `dish_id`; Atwater check `4P+4C+9F` within ±12 % of kcal; all percentiles ordered; every dish has provenance; every group has exactly one `is_generic: true` record; `variants` adjust fat and re-derive kcal consistently.

### 5.3 Core Dart types (signatures are binding; internals are free)

```dart
class Range { final double p10, p50, p90; }                         // grams, kcal, macros
class PlateGeometry { PlateKind kind; double cmPerPx; double tiltDeg;
                      TiltSource source; bool conflict; double plateDiameterCm; }
class DetectedItem {
  String regionId; Role role; Polygon outline; double areaCm2; String? containerId;
  List<DishScore> topK;         // (dishId, calibratedProb) sorted desc, K=5
  String dishId;                // chosen; may be a group-generic id
  bool isGenericFallback; int? pieceCount; Range grams; Range kcal; Macros macros;
  Set<ConfidenceFlag> flags;    // lowSegConf, occluded, geometryConflict, unknownDish, userEdited
}
class ScanResult { PlateGeometry geometry; List<DetectedItem> items;
                   Range totalKcal; Macros totalMacros; StageTimings timings; String modelManifestVersion; }
```
Pipeline entry point: `Future<Result<ScanResult>> MultiFoodPipeline.run(ScanInput input)`. It **never throws**; failures become `Failure` types from `core/`.

### 5.4 Weighed-plate dataset row (`ml/data/weighed_plates/plates.csv`)

`plate_id, session_id, image_paths(;), imu_tilt_deg, plate_type, plate_diameter_cm, container_ids(;), item_index, dish_id, role, net_mass_g, piece_count, variant, lighting, notes` — one row per item per plate; **net mass = gross − tare**, scale resolution ≤ 1 g.

---

## 6. Algorithm specifications

### 6.1 Scale, tilt, area (Phase 5 · `plate_geometry_calculator.dart`)

**Round plate** — fit an ellipse to the outer contour of the `plate_tray` mask (RANSAC over 5-point subsets + algebraic least-squares refit on inliers; reject if inlier ratio < 0.6):

```
a, b   = semi-major, semi-minor axes (pixels)          D = user plate diameter (cm)
s      = D / (2a)                    cm per pixel along the un-foreshortened direction
θ_ell  = arccos(b / a)               camera tilt from vertical (0° = straight down)
A_cm²  = N_pixels × s² / cos(θ)      real area of a region lying in the plate plane
```
**IMU fusion** (`capture_tilt_service.dart`): θ_imu = angle between camera optical axis and gravity. If `|θ_imu − θ_ell| ≤ 8°` → `θ = 0.5·θ_imu + 0.5·θ_ell`; else `θ = θ_imu`, set `conflict = true`. Capture HUD blocks/warns when `θ_imu > 25°` (tables are assumed level).

**Rectangular tray** — 4 corner points → homography (DLT) to a rectangle of known size (`container_profiles.json`); warp region masks to metric top-down space; area = rectified pixel count × (cm/px)². *Prefer the homography whenever 4 reliable points exist.*

**Geometry v2 (T8.6, optional)** — height-aware scale for items above the plate plane: `s(h) = s₀ · (1 − h / Z)`, where camera height `Z ≈ f_px · D / (2a)` (needs focal length in pixels). Until then, this bias is absorbed by calibration (§6.3).

### 6.2 Volume → mass (Phase 5 · `volumetric_math.dart`, `mass_estimator.dart`)

Three modes (selected by the dish's `measure.mode` and container association):

```
BOWL (food inside a katori)        spherical-cap bowl: rim radius a_c, depth d_c (from container profile)
   R   = (a_c² + d_c²) / (2·d_c)             sphere radius of the bowl
   r_s = sqrt(A_surface / π)                 contents surface radius from the mask (metric)
   h   = R − sqrt(R² − r_s²)                 fill depth       (clamp r_s ≤ a_c)
   V   = π·h²·(3R − h) / 3                   (+ optional heap term, role-based, calibrated)
LAYER / MOUND (food on the plate)
   V   = A_cm² × h_eff                       h_eff = κ × h_peak, prior per role (table below)
PIECE (roti, idli, vada, egg, gulab jamun…)
   m   = n × unit_mass × clamp(A_piece / A_ref, 0.6, 1.5)     n = count (components or user stepper)

mass_phys  = ρ × V                (volume modes)  |  formula above (piece mode)
mass_final = mass_phys × k        k = calibration factor (§6.3);  P10/P50/P90 = mass_phys × exp(q10/q50/q90)
```
**Initial priors — `PLACEHOLDER(T8.2)`, copied from the earlier plan, NOT validated:**

| Role | Mode | `h_eff` cm (p10 / p50 / p90) | ρ g/ml |
| :--- | :--- | :--- | :--- |
| gravy_curry (in bowl) | BOWL | — | 1.02–1.08 |
| gravy_curry (on plate) | LAYER | 0.6 / 1.0 / 1.5 | 1.05 |
| mounded_carb | MOUND | 1.4 / 2.0 / 2.8 | 0.78–0.88 (per dish) |
| dry_sabzi | MOUND | 1.0 / 1.6 / 2.4 | 0.65 |
| salad_raw | LAYER | 0.8 / 1.2 / 1.8 | 0.38 |
| condiment | LAYER | 0.5 / 0.8 / 1.2 | 1.20 |
| flat_bread, protein_piece, other_food | PIECE (or LAYER if catalog says volume) | catalog | catalog |

**Meal total uncertainty**: Monte-Carlo (N = 500) in log-space with **one shared plate-scale error term** (σ from §9 geometry tests) plus independent per-item terms; report P10/P50/P90 of the sum. Items are *not* assumed independent.

### 6.3 Calibration & personalization

- **Global (T8.2)** — on the training weighed plates: `r_i = log(m_true / m_phys)` per item. Per role and per dish (with shrinkage to its role: `k_dish = exp( Σr_i / (n + 5) )`, clamp 0.6–1.6) store the median and the (q10, q50, q90) of residuals in `mass_calibration.json`. Before data exists: role default ±35 % `PLACEHOLDER`.
- **Personal (T9.1)** — each time the user edits grams, log `r = log(m_user / m_pred)`. `k_user(dish) = exp( Σr / (n + 5) )`, clamp 0.6–1.6, applied on top of global k. Stored locally only.
- **Python ↔ Dart parity**: the formulas in §6.2 are implemented **twice** — Python reference (`ml/src/ml_pipeline/mass/reference.py`, used for calibration) and Dart (production). Both must pass the same vectors in `app/test/fixtures/mass_vectors.json` (relative error ≤ 1e-6). *This is the guard against silent divergence.*

### 6.4 Classification logic (Phase 4/6)

```
crop      = mask bbox + 10 % context padding → letterbox 224×224   (ablation: masked crop, T4.4)
embedding = embedder(crop)  (256-d, L2-normalized)
score_d   = cosine(embedding, prototype_d)  → temperature-scaled probability p_d   (T fitted on held-out)
role_prior: p'_d ∝ p_d × (role(d) == segmenter_role ? 1.0 : 0.25)       # SOFT prior, never a hard filter
if max p' < τ_open                                   → flag unknownDish, show search/"teach dish"
else if p'_top1 < τ_dish and top-3 share one group   → use group-generic record, widen intervals
else                                                 → top-1 dish, show top-3 as alternatives
```

### 6.5 Mask post-processing (Phase 6 · `mask_postprocess.dart`, pure Dart)
argmax → per-role binary mask → morphological open/close (3×3) → connected components (drop < 0.3 % of image) → watershed split if `solidity < 0.85` and area > 1.5× role median → contour polygon (Douglas-Peucker) → **container association**: a food region belongs to the `bowl` whose (rim+contents) region contains ≥ 60 % of its pixels → rim ellipse fit for the spherical-cap model.

---

## 7. START HERE — your first 10 days (human + agent)

Goal: by **day 10** you have a *walking skeleton* — one photo → segmentation overlay on the phone in airplane mode, with a rough model — plus the data habit started. Data is the long pole, so it starts on **day 1**.

| Day | You (human) | Agent |
| :--- | :--- | :--- |
| **1** | Run `flutter doctor`, `uv sync`, existing tests. Buy/borrow a **kitchen scale (1 g or better)**. Start photographing + weighing meals (§Capture SOP, 5 plates/day). | T0.1–T0.3: scaffold `docs/`, `tools/`, offline check, record baseline test results. |
| **2** | Write down the plates, katoris, trays you actually use. | T1.1 taxonomy v1 (11 roles → groups → 239 dishes mapped from `labels.json`). T1.2 SOP + CSV schema. |
| **3** | Measure each plate Ø, katori rim Ø + depth, and capacity (fill with water, weigh: 1 g = 1 ml). | T5.0 `container_profiles.json` from your measurements. T5.1 start: ellipse fit **tests first** (synthetic ellipses with known tilt). |
| **4–5** | Keep capturing plates. Check dataset licenses the agent lists. | T5.1 finish, T5.2 spherical-cap + mound + piece math with tests. T1.3 dataset ingestion + `LICENSES.md`. |
| **6–7** | Annotate/verify first **100 plates** (SAM2 pre-masks → fix). | T1.4 `sam_preannotate.py` + annotation guide. T5.4 nutrition calculator. |
| **8–10** | Verify a handful of catalog dishes against your own cooking. | T2.1–T2.2 catalog schema/validator + first 40 dishes. **T3.0 walking skeleton**: tiny segmenter overfit on 100 plates → export → run in Flutter on one photo. |

**Parallel tracks** (so you are never blocked): **A. Data** (capture, annotate, catalog) · **B. Dart math** (Phase 5, needs no data) · **C. ML** (Phases 3–4, needs data). Suggested pace for a part-time student: Phase 0–2 weeks 1–6 · Phase 5 weeks 3–7 · Phases 3–4 weeks 5–10 · Phase 6 weeks 10–12 · Phase 7 weeks 12–14 · Phase 8 weeks 14–16 · Phases 9–10 weeks 16–19.

---

## 8. Roadmap — phases, tasks, gates

Tick tasks in `docs/PROGRESS.md`. `→` means "depends on".

### Phase 0 — Guardrails (1–2 days)
- [ ] **T0.1** Create `docs/PROGRESS.md` (copy all task IDs below), `docs/adr/`, `docs/THIRD_PARTY.md`, `docs/BENCHMARKS.md`, `ml/data/LICENSES.md`.
- [ ] **T0.2** Run existing Flutter + Python tests; save results in `docs/BENCHMARKS.md` (baseline accuracy, latency, APK size). Record the exact **RLD** phone model.
- [ ] **T0.3** Write `tools/check_all.sh` = `dart format --set-exit-if-changed` + `flutter analyze` + `flutter test` + `uv run pytest` + `check_offline.sh` (aapt/manifest has no `INTERNET`; `pubspec` has no HTTP client packages unless allow-listed) + `check_placeholders.sh` + `check_licenses.sh`.
- **Gate G0**: all existing tests green; `check_offline.sh` green.

### Phase 1 — Data foundation (start day 1, runs for weeks)
- [ ] **T1.1** `ml/taxonomy/taxonomy_v1.yaml`: roles (§5.1), ~40 groups, 239 dishes (map existing `labels.json`), one generic record per group.
- [ ] **T1.2** `docs/specs/capture_sop.md` + `plates.csv` schema (§5.4): top-down shot ± 3 more at 15° and 30°, IMU tilt logged, each item weighed separately (tare container), varied lighting/plates, ≥ 30 % restaurant/other-home plates.
- [ ] **T1.3** Ingestion scripts for public data, each logging its license in `ml/data/LICENSES.md`: **Khana** (≈131 K images, 80 Indian classes), **Indian Thali Dataset + Weight Estimation Dataset** (IIIT-H, ICVGIP 2025: 796 plates / 267 weighed plates — verify availability and terms), **EcoPlate** (313 plate pairs, 8 classes — access may be restricted), **Nutrition5k** (5 K dishes, depth + mass — pretraining for mass behavior), **FoodSeg103 / UEC-FoodPix** (segmentation pretraining; check non-commercial terms ⇒ research-only if NC).
- [ ] **T1.4** `sam_preannotate.py` (SAM 2 → candidate masks → map to roles → import into CVAT/Label Studio) + `annotation_guide.md`. Target **≥ 800 verified plates (gate) / 1,500 (target)**.
- [ ] **T1.5** Splits **by session/plate** (no leakage) in `ml/data/splits/`; freeze the **golden set** (≥ 60 weighed plates + their masks, never trained on, hash saved).
- **Gate G1**: ≥ 150 weighed plates collected · ≥ 800 verified segmentation plates · golden set frozen · license table complete.

### Phase 2 — Nutrition catalog (parallel with 1)
- [ ] **T2.1** `ml/catalog/validate_catalog.py` + tests (rules in §5.2).
- [ ] **T2.2** Recipes → `build_catalog.py` → per-100 g cooked values; start with the **40 most common dishes**, then all 239. Each recipe lists ingredients, grams, cooking-yield, oil.
- [ ] **T2.3** Add `measure` (mode, density/piece mass), `variants`, generic group records, `aliases`, Hindi names.
- [ ] **T2.4** Export `app/assets/models/dish_catalog.json` + `dish_catalog_repository.dart` + tests (load, lookup, variant math).
- **Gate G2**: validator green · 100 % dishes have provenance · Atwater check green.

### Phase 3 — Role segmenter (ML)
- [ ] **T3.0 Walking skeleton** (day ≤ 10): train on ~100 plates until it overfits, export, run once in Flutter offline, draw the overlay. Quality is irrelevant; the *path* is the deliverable.
- [ ] **T3.1** `train_segmenter.py` + `ml/configs/seg_v1.yaml`: 512×512, Dice+CE loss, augmentations (color jitter, blur, JPEG, scale/rotate, perspective ≤ 25°, random plate crop).
- [ ] **T3.2** Pretrain on mapped public data → fine-tune on verified thali plates.
- [ ] **T3.3** `eval_golden.py --task seg` → mIoU per role, plate IoU, boundary F1, worst-20 error gallery.
- [ ] **T3.4** Export INT8 with `litert-torch` + `ai-edge-quantizer` (representative calibration set = 300 real plates). **Parity test** with `ai_edge_litert`: INT8 mIoU drop ≤ 1.5 pt vs FP32 PyTorch; if worse → FP16 or per-layer exemptions, log ADR.
- **Gate G3**: food mIoU ≥ 0.70, plate IoU ≥ 0.93, model ≤ 8 MB, parity ok, report saved to `ml/reports/seg_v1.md` + model card.

### Phase 4 — Dish embedder + prototypes (ML)
- [ ] **T4.1** Crop-dataset builder: (a) single-dish images, (b) crops from GT masks of thali plates (this fixes the "whole-plate vs crop" domain gap). Hold out by session.
- [ ] **T4.2** `train_embedder.py`: MobileNetV4-Conv-Medium, 256-d, normalized-softmax, aggressive crop/occlusion/blur augmentation, class-balanced sampling.
- [ ] **T4.3** `build_prototypes.py` (≤ 3 per dish via k-means on embeddings), temperature scaling, **τ_open / τ_dish** calibration, `dish_prototypes.bin`.
- [ ] **T4.4** Eval: top-1/top-3, ECE, confusion-pair report (Dal Tadka vs Makhani vs Sambar, Bhindi vs Aloo Gobi, Mango pickle vs Mint chutney…), hard-negative mining round, masked-crop ablation.
- [ ] **T4.5** INT8 export + parity (top-1 drop ≤ 1.0 pt), size ≤ 12 MB.
- **Gate G4**: top-1 ≥ 85 %, top-3 ≥ 95 %, ECE ≤ 0.08 on golden thali crops; adding 3 *held-out new dishes* by prototype only reaches ≥ 70 % top-3 (proves scalability).

### Phase 5 — Geometry, mass, nutrition engine (Dart, test-first; no data needed)
- [ ] **T5.0** `container_profiles.json` from owner's measured utensils (`PLACEHOLDER` defaults for generic katori: rim Ø 10 cm, depth 4 cm ≈ 190 ml).
- [ ] **T5.1** `plate_geometry_calculator.dart`: ellipse RANSAC + LSQ, 4-pt homography, scale/tilt/area. Tests: synthetic ellipses at known tilt 0–40° with pixel noise ⇒ **scale error ≤ 1.5 %, tilt error ≤ 2°**; partial plate (60 % visible) ⇒ graceful `Failure`; circular plate edge case.
- [ ] **T5.2** `volumetric_math.dart`: bowl-cap, mound/layer, piece. Property tests: units, monotonic in area/fill, `r_s > a_c` clamped, hand-computed examples (e.g. a=5, d=4 ⇒ R=5.125, full bowl ≈ 190.6 ml).
- [ ] **T5.3** `mass_estimator.dart`: priors (§6.2), calibration lookup, Monte-Carlo totals with shared scale error; Python reference + `mass_vectors.json` parity.
- [ ] **T5.4** `nutrition_calculator.dart`: kcal/macros ranges from catalog + variant; Atwater sanity test.
- [ ] **T5.5** `capture_tilt_service.dart` (accelerometer via `sensors_plus`) + fusion rule §6.1; fake sensor for tests.
- **Gate G5**: all above green, **≥ 90 % line coverage** on these files; `check_placeholders.sh` lists only calibration placeholders.

### Phase 6 — On-device pipeline (Flutter)
- [ ] **T6.1** Preprocess: decode with `ui.instantiateImageCodec(targetWidth: …)` (native downscale — do **not** decode 12 MP JPEGs with the pure-Dart `image` package), apply EXIF orientation, produce `Float32List`/`Uint8List` 512×512; send to worker as `TransferableTypedData`.
- [ ] **T6.2** `scan_worker.dart`: **one long-lived isolate** owning both `Interpreter`s (created *inside* the isolate; native handles can't cross isolates), warm-up on screen open, `dispose()` on close. `segmenter_runner.dart`, `embedder_runner.dart`.
- [ ] **T6.3** `mask_postprocess.dart` (§6.5) with synthetic-mask tests (touching rotis, two katoris, partial occlusion).
- [ ] **T6.4** `multi_food_pipeline.dart` orchestration, `StageTimings`, `Result<ScanResult>`.
- [ ] **T6.5** Fallbacks: no plate / low seg confidence / manifest mismatch ⇒ baseline single-dish flow + manual portion. Never a dead end.
- [ ] **T6.6** Integration test on 10 fixture photos (deterministic outputs within tolerance) + on-device latency/RAM benchmark → `docs/BENCHMARKS.md`.
- **Gate G6**: works in **airplane mode** on RLD · latency within budget · 50 consecutive scans without memory growth > 10 %.

### Phase 7 — UI/UX
- [ ] **T7.1** Capture HUD: plate guide, live tilt indicator (green ≤ 15°, amber ≤ 25°, red beyond), "hold steady", capture.
- [ ] **T7.2** Overlay polygons by role; tap a region → `region_editor_sheet`: change dish (top-5 + search), merge/split/delete, **add missing item**, set piece count.
- [ ] **T7.3** `multi_scan_result_sheet.dart`: item cards showing `≈160 g (130–195)`, slider, alternatives, piece stepper, oil **variant chips**, total bar (kcal + P/C/F, range), **atomic "Log all"** into `LogStore` + Riverpod.
- [ ] **T7.4** "My Plates" profile (plate Ø, tray type, katori size) in onboarding/profile; used by geometry.
- [ ] **T7.5** Dark mode, en/hi strings, accessibility (labels, 48 dp targets).
- [ ] **T7.6** Widget + golden tests (`multi_scan_result_sheet_test.dart`, `region_editor_sheet_test.dart`).
- **Gate G7**: scan → logged in ≤ 3 taps for a correct scan; every error path has a recovery action.

### Phase 8 — Accuracy sprint (calibration on real weighed plates)
- [ ] **T8.1** Run the *Python reference* pipeline on training plates ⇒ residual table.
- [ ] **T8.2** `fit_mass_calibration.py` → `mass_calibration.json` (per role/dish, shrinkage, quantiles) replaces placeholders.
- [ ] **T8.3** `eval_golden.py --task mass` → per-item & total error by role, interval coverage, bias plot, top-10 worst plates review.
- [ ] **T8.4** *Optional* residual model (small MLP/GBM on role, dish group, area, tilt, compactness) — adopt only if golden **total-kcal median error improves ≥ 3 points** and latency +< 50 ms.
- [ ] **T8.5** *Optional* depth cue (small monocular-depth model, **permissive license verified**) — same adoption gate as T8.4.
- [ ] **T8.6** *Optional* Geometry v2 height-aware scale (needs camera focal length via platform channel).
- **Gate G8**: Calories median ≤ 20 %, per-item median ≤ 25 %, coverage 70–88 %.

### Phase 9 — Personalization (offline learning)
- [ ] **T9.1** `personal_calibration.dart` (§6.3) + tests with simulated corrections (error shrinks, clamps hold, `n=0` ⇒ identity).
- [ ] **T9.2** "Teach a dish": 3–5 photos ⇒ on-device embeddings ⇒ local prototype + user-entered nutrition; used in open-set suggestions.
- [ ] **T9.3** Local backup/restore (JSON file) — no cloud.
- **Gate G9**: tests green; manual test: correct one dish 5× ⇒ next prediction moves toward the user's value.

### Phase 10 — Hardening & release
- [ ] **T10.1** Benchmark `Interpreter` vs `CompiledModel` (GPU/NNAPI/NPU) per device; choose with automatic CPU fallback; 20-scan thermal test.
- [ ] **T10.2** APK/AAB size (ABI splits), models ≤ 40 MB total.
- [ ] **T10.3** Privacy review: no image persistence unless the user saves it; buffers zeroed/closed; no logging of images.
- [ ] **T10.4** Model cards in `docs/model_cards/`, reproducibility (`dvc repro`, seeds), README demo (airplane-mode video), portfolio write-up (problem → data → method → honest metrics → limits).
- **Gate G10**: every earlier gate green · `check_all.sh` green · zero `PLACEHOLDER(` · demo recorded. Only now may `baseline.tflite` be demoted.

---

## 9. Evaluation protocol (no leakage, no cheating)

- **Golden set**: ≥ 60 weighed plates (+ masks) frozen in T1.5, hash in `ml/data/splits/golden.sha256`. Never used for training, tuning, threshold selection, or calibration. Re-freeze only via ADR.
- **Tuning data**: separate validation split (by session) for thresholds τ, temperature, early stopping.
- **Metrics scripts** (`eval_golden.py`) write `ml/reports/*.json` + `.md`; docs and model cards quote only those files.
- **Mass/calorie error** = `|pred_P50 − true| / true` per item and per meal; report median, mean, P90, and by role/plate type/lighting.
- **Interval coverage** = share of items with `true ∈ [P10, P90]` (nominal 80 %).
- **Geometry tests** (synthetic, Phase 5) give the σ used for the shared scale-error term in §6.2.
- **Regression rule**: a new model ships only if golden metrics are ≥ previous − 0.5 pt on every gate metric.

---

## 10. Engineering invariants & commands

- **Memory**: close camera streams and bitmaps immediately; `Interpreter`/`CompiledModel` owned by the worker isolate, closed in `dispose()`; no per-scan allocations of model-sized buffers (reuse).
- **UI thread**: zero inference on the UI isolate. Overlay drawing uses `CustomPainter` from already-computed polygons.
- **Errors**: `Result<T>` + typed `Failure`; no raw exceptions across layers.
- **Determinism**: seeded training (`seed` in every config), fixed preprocessing, no `DateTime.now()` inside algorithms.
- **Tests never touch the network.**
- **Coverage**: ≥ 90 % on `domain/services/*` listed in §4; widget + golden tests for new screens.

**Commands**
```bash
# Flutter (from app/)
flutter pub get && dart format --set-exit-if-changed . && flutter analyze && flutter test --coverage
# Python (from ml/)
uv sync && uv run ruff check . && uv run pytest
uv run python scripts/train_segmenter.py --config configs/seg_v1.yaml
uv run python scripts/eval_golden.py --task seg|cls|mass
dvc repro                       # reproduce data/model pipeline
# Everything, from repo root
tools/check_all.sh
```
*(Scripts marked `[N]` in §4 must be created by the tasks above; until then the command does not exist — do not pretend it ran.)*

---

## 11. Agent do / don't & definition of done

**Do**: keep diffs small · read the task's dependencies first · state assumptions in the PR note · save evidence files · prefer deleting complexity · add a test for every bug you fix.

**Don't**:
- ✗ Add any cloud/LLM/network dependency or `INTERNET` permission.
- ✗ Add Ultralytics/YOLO, GPL/AGPL/NC code or weights to the shipped path.
- ✗ Hardcode kcal, density, or grams in Dart/Python logic.
- ✗ Report a metric you did not compute, or tune on the golden set.
- ✗ Rename role IDs, `dish_id`s, or asset files without a manifest/ADR update.
- ✗ Replace `baseline.tflite`/`labels.json` before G10.
- ✗ Refactor unrelated code or change state-management/DB (D-12).
- ✗ Silence analyzer warnings or delete failing tests.

**If stuck** (same error twice): (1) write the smallest failing reproduction; (2) check §2 for a locked decision that already answers it; (3) try the documented fallback (e.g. FP16 instead of INT8, hand-written FPN instead of `smp`); (4) log an ADR and move on, or ask the owner if it needs a human.

**Definition of done (per task)**: code + tests + evidence file + `PROGRESS.md` line + `check_all.sh` green (or the failing check explained) + no new unlabelled constants.

---

## 12. Glossary & references

**Role** = visual super-class (11). **Group** = dish family (~40). **Dish** = exact recipe label. **Region** = one connected food area. **Container** = plate/tray/bowl. **Piece mode** = count × unit mass. **P10/P50/P90** = low/median/high estimate. **RLD** = Reference Low-End Device (≤ 4 GB RAM mid-range Android, model recorded in `docs/BENCHMARKS.md`). **Golden set** = frozen weighed evaluation plates. **Walking skeleton** = thinnest end-to-end path that runs on device.

**References** (verify current versions/terms before use):
- `flutter_litert` — LiteRT plugin for Flutter (Interpreter + IsolateInterpreter + CompiledModel): https://pub.dev/packages/flutter_litert
- `litert-torch` — PyTorch → LiteRT converter: https://github.com/google-ai-edge/litert-torch
- Nutrition5k (Google Research, CVPR 2021): https://github.com/google-research-datasets/Nutrition5k
- "What is there in an Indian Thali?" (ICVGIP 2025) — zero-shot segmentation + prototype classification + nutrition on Indian thalis: https://cdn.iiit.ac.in/cdn/cvit.iiit.ac.in/images/ConferencePapers/2025/ICVGIP_Food_Scanner.pdf
- Khana Indian cuisine dataset (2025): https://arxiv.org/abs/2509.06006
- "Single-Item Training for Multi-Dish Recognition" (Frontiers in Computer Science, 2026) — supports train-on-single-dish, apply-to-segmented-regions: https://www.frontiersin.org/journals/computer-science/articles/10.3389/fcomp.2026.1753764/full
- EcoPlate Indian cafeteria instance-segmentation dataset (IEEE DataPort): https://ieee-dataport.org/documents/ecoplate-paired-multimodal-dataset-indian-cafeteria-food-instance-segmentation

> **Ready**: begin with **§7 Day 1**, then Phase 0. Do not skip the Gates.
