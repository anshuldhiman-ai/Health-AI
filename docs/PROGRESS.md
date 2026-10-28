# PROGRESS.md — Health AI · Multi-Food Vision & Nutrition Engine

> **State across sessions**. Single source of truth for task completion.
> Follow the task loop in `AGENTS.md` §0:
> Take the lowest-numbered unchecked task whose dependencies are done. Never skip past a Gate.

---

## Gates Status Overview

| Gate | Phase | Status | Completed Date | Evidence File |
| :--- | :--- | :--- | :--- | :--- |
| **G0** | Phase 0 — Guardrails | Completed | 2026-10-28 | `docs/BENCHMARKS.md`, `tools/check_offline.sh`, `tools/check_all.py` |
| **G1** | Phase 1 — Data Foundation | Pending | — | `ml/data/splits/golden.sha256` |
| **G2** | Phase 2 — Nutrition Catalog | Pending | — | `app/assets/models/dish_catalog.json` |
| **G3** | Phase 3 — Role Segmenter | Pending | — | `ml/reports/seg_v1.md` |
| **G4** | Phase 4 — Dish Embedder | Pending | — | `ml/reports/emb_v1.md` |
| **G5** | Phase 5 — Geometry & Mass Engine | Pending | — | `app/test/fixtures/mass_vectors.json` |
| **G6** | Phase 6 — On-Device Pipeline | Pending | — | `docs/BENCHMARKS.md` |
| **G7** | Phase 7 — UI/UX | Pending | — | `app/test/goldens/` |
| **G8** | Phase 8 — Accuracy Sprint | Pending | — | `ml/reports/mass_v1.md` |
| **G9** | Phase 9 — Personalization | Pending | — | `app/test/domain/services/personal_calibration_test.dart` |
| **G10** | Phase 10 — Hardening & Release | Pending | — | `docs/model_cards/` |

---

## Detailed Task Checklist

### Phase 0 — Guardrails (1–2 days)
- [x] **T0.1** Create `docs/PROGRESS.md` (copy all task IDs below), `docs/adr/`, `docs/THIRD_PARTY.md`, `docs/BENCHMARKS.md`, `ml/data/LICENSES.md`.
  * `T0.1 completed: created PROGRESS.md, THIRD_PARTY.md, BENCHMARKS.md, ml/data/LICENSES.md`
- [x] **T0.2** Run existing Flutter + Python tests; save results in `docs/BENCHMARKS.md` (baseline accuracy, latency, APK size). Record the exact **RLD** phone model.
  * `T0.2 completed: 115 Flutter tests passed, 21 Python tests passed; recorded in docs/BENCHMARKS.md`
- [x] **T0.3** Write `tools/check_all.sh` = `dart format --set-exit-if-changed` + `flutter analyze` + `flutter test` + `uv run pytest` + `check_offline.sh` (aapt/manifest has no `INTERNET`; `pubspec` has no HTTP client packages unless allow-listed) + `check_placeholders.sh` + `check_licenses.sh`.
  * `T0.3 completed: tools/check_all.py, check_offline.sh, check_licenses.sh, check_placeholders.sh, check_all.sh/ps1 created; all 7 guardrail checks pass green (Gate G0 complete)`
- **Gate G0**: all existing tests green; `check_offline.sh` green. (PASSED 2026-10-28)

---

### Phase 1 — Data foundation (start day 1, runs for weeks)
- [x] **T1.1** `ml/taxonomy/taxonomy_v1.yaml`: roles (§5.1), ~40 groups, 239 dishes (map existing `labels.json`), one generic record per group.
  * `T1.1 completed: taxonomy_v1.yaml generated (11 roles, 48 groups, 239 catalog dishes, 48 generic records); verified by test_taxonomy_v1.py`
- [x] **T1.2** `docs/specs/capture_sop.md` + `plates.csv` schema (§5.4): top-down shot ± 3 more at 15° and 30°, IMU tilt logged, each item weighed separately (tare container), varied lighting/plates, ≥ 30 % restaurant/other-home plates.
  * `T1.2 completed: docs/specs/capture_sop.md written, ml/data/weighed_plates/plates.csv schema established; verified by test_plates_csv.py`
- [ ] **T1.3** Ingestion scripts for public data, each logging its license in `ml/data/LICENSES.md`: **Khana** (≈131 K images, 80 Indian classes), **Indian Thali Dataset + Weight Estimation Dataset** (IIIT-H, ICVGIP 2025: 796 plates / 267 weighed plates), **EcoPlate** (313 plate pairs, 8 classes), **Nutrition5k** (5 K dishes, depth + mass), **FoodSeg103 / UEC-FoodPix**.
- [ ] **T1.4** `sam_preannotate.py` (SAM 2 → candidate masks → map to roles → import into CVAT/Label Studio) + `annotation_guide.md`. Target **≥ 800 verified plates (gate) / 1,500 (target)**.
- [ ] **T1.5** Splits **by session/plate** (no leakage) in `ml/data/splits/`; freeze the **golden set** (≥ 60 weighed plates + their masks, never trained on, hash saved).
- **Gate G1**: ≥ 150 weighed plates collected · ≥ 800 verified segmentation plates · golden set frozen · license table complete.

---

### Phase 2 — Nutrition catalog (parallel with 1)
- [ ] **T2.1** `ml/catalog/validate_catalog.py` + tests (rules in §5.2).
- [ ] **T2.2** Recipes → `build_catalog.py` → per-100 g cooked values; start with the **40 most common dishes**, then all 239. Each recipe lists ingredients, grams, cooking-yield, oil.
- [ ] **T2.3** Add `measure` (mode, density/piece mass), `variants`, generic group records, `aliases`, Hindi names.
- [ ] **T2.4** Export `app/assets/models/dish_catalog.json` + `dish_catalog_repository.dart` + tests (load, lookup, variant math).
- **Gate G2**: validator green · 100 % dishes have provenance · Atwater check green.

---

### Phase 3 — Role segmenter (ML)
- [ ] **T3.0 Walking skeleton** (day ≤ 10): train on ~100 plates until it overfits, export, run once in Flutter offline, draw the overlay. Quality is irrelevant; the *path* is the deliverable.
- [ ] **T3.1** `train_segmenter.py` + `ml/configs/seg_v1.yaml`: 512×512, Dice+CE loss, augmentations (color jitter, blur, JPEG, scale/rotate, perspective ≤ 25°, random plate crop).
- [ ] **T3.2** Pretrain on mapped public data → fine-tune on verified thali plates.
- [ ] **T3.3** `eval_golden.py --task seg` → mIoU per role, plate IoU, boundary F1, worst-20 error gallery.
- [ ] **T3.4** Export INT8 with `litert-torch` + `ai-edge-quantizer` (representative calibration set = 300 real plates). **Parity test** with `ai_edge_litert`: INT8 mIoU drop ≤ 1.5 pt vs FP32 PyTorch; if worse → FP16 or per-layer exemptions, log ADR.
- **Gate G3**: food mIoU ≥ 0.70, plate IoU ≥ 0.93, model ≤ 8 MB, parity ok, report saved to `ml/reports/seg_v1.md` + model card.

---

### Phase 4 — Dish embedder + prototypes (ML)
- [ ] **T4.1** Crop-dataset builder: (a) single-dish images, (b) crops from GT masks of thali plates. Hold out by session.
- [ ] **T4.2** `train_embedder.py`: MobileNetV4-Conv-Medium, 256-d, normalized-softmax, aggressive crop/occlusion/blur augmentation, class-balanced sampling.
- [ ] **T4.3** `build_prototypes.py` (≤ 3 per dish via k-means on embeddings), temperature scaling, **τ_open / τ_dish** calibration, `dish_prototypes.bin`.
- [ ] **T4.4** Eval: top-1/top-3, ECE, confusion-pair report, hard-negative mining round, masked-crop ablation.
- [ ] **T4.5** INT8 export + parity (top-1 drop ≤ 1.0 pt), size ≤ 12 MB.
- **Gate G4**: top-1 ≥ 85 %, top-3 ≥ 95 %, ECE ≤ 0.08 on golden thali crops; adding 3 *held-out new dishes* by prototype only reaches ≥ 70 % top-3.

---

### Phase 5 — Geometry, mass, nutrition engine (Dart, test-first; no data needed)
- [ ] **T5.0** `container_profiles.json` from owner's measured utensils (`PLACEHOLDER` defaults for generic katori: rim Ø 10 cm, depth 4 cm ≈ 190 ml).
- [ ] **T5.1** `plate_geometry_calculator.dart`: ellipse RANSAC + LSQ, 4-pt homography, scale/tilt/area. Tests: synthetic ellipses at known tilt 0–40° with pixel noise ⇒ **scale error ≤ 1.5 %, tilt error ≤ 2°**; partial plate (60 % visible) ⇒ graceful `Failure`; circular plate edge case.
- [ ] **T5.2** `volumetric_math.dart`: bowl-cap, mound/layer, piece. Property tests: units, monotonic in area/fill, `r_s > a_c` clamped, hand-computed examples.
- [ ] **T5.3** `mass_estimator.dart`: priors (§6.2), calibration lookup, Monte-Carlo totals with shared scale error; Python reference + `mass_vectors.json` parity.
- [ ] **T5.4** `nutrition_calculator.dart`: kcal/macros ranges from catalog + variant; Atwater sanity test.
- [ ] **T5.5** `capture_tilt_service.dart` (accelerometer via `sensors_plus`) + fusion rule §6.1; fake sensor for tests.
- **Gate G5**: all above green, **≥ 90 % line coverage** on these files; `check_placeholders.sh` lists only calibration placeholders.

---

### Phase 6 — On-device pipeline (Flutter)
- [ ] **T6.1** Preprocess: decode with `ui.instantiateImageCodec(targetWidth: …)` (native downscale), apply EXIF orientation, produce `Float32List`/`Uint8List` 512×512; send to worker as `TransferableTypedData`.
- [ ] **T6.2** `scan_worker.dart`: **one long-lived isolate** owning both `Interpreter`s, warm-up on screen open, `dispose()` on close. `segmenter_runner.dart`, `embedder_runner.dart`.
- [ ] **T6.3** `mask_postprocess.dart` (§6.5) with synthetic-mask tests.
- [ ] **T6.4** `multi_food_pipeline.dart` orchestration, `StageTimings`, `Result<ScanResult>`.
- [ ] **T6.5** Fallbacks: no plate / low seg confidence / manifest mismatch ⇒ baseline single-dish flow + manual portion. Never a dead end.
- [ ] **T6.6** Integration test on 10 fixture photos + on-device latency/RAM benchmark → `docs/BENCHMARKS.md`.
- **Gate G6**: works in **airplane mode** on RLD · latency within budget · 50 consecutive scans without memory growth > 10 %.

---

### Phase 7 — UI/UX
- [ ] **T7.1** Capture HUD: plate guide, live tilt indicator, "hold steady", capture.
- [ ] **T7.2** Overlay polygons by role; tap a region → `region_editor_sheet`: change dish, merge/split/delete, add missing item, set piece count.
- [ ] **T7.3** `multi_scan_result_sheet.dart`: item cards showing grams range, slider, alternatives, piece stepper, oil variant chips, total bar, atomic "Log all".
- [ ] **T7.4** "My Plates" profile (plate Ø, tray type, katori size) in onboarding/profile.
- [ ] **T7.5** Dark mode, en/hi strings, accessibility.
- [ ] **T7.6** Widget + golden tests (`multi_scan_result_sheet_test.dart`, `region_editor_sheet_test.dart`).
- **Gate G7**: scan → logged in ≤ 3 taps for a correct scan; every error path has a recovery action.

---

### Phase 8 — Accuracy sprint (calibration on real weighed plates)
- [ ] **T8.1** Run the *Python reference* pipeline on training plates ⇒ residual table.
- [ ] **T8.2** `fit_mass_calibration.py` → `mass_calibration.json` (per role/dish, shrinkage, quantiles).
- [ ] **T8.3** `eval_golden.py --task mass` → per-item & total error by role, interval coverage, bias plot, top-10 worst plates review.
- [ ] **T8.4** *Optional* residual model (small MLP/GBM) — adopt only if golden total-kcal median error improves ≥ 3 points and latency +< 50 ms.
- [ ] **T8.5** *Optional* depth cue (small monocular-depth model, permissive license verified).
- [ ] **T8.6** *Optional* Geometry v2 height-aware scale.
- **Gate G8**: Calories median ≤ 20 %, per-item median ≤ 25 %, coverage 70–88 %.

---

### Phase 9 — Personalization (offline learning)
- [ ] **T9.1** `personal_calibration.dart` (§6.3) + tests with simulated corrections.
- [ ] **T9.2** "Teach a dish": 3–5 photos ⇒ on-device embeddings ⇒ local prototype + user-entered nutrition.
- [ ] **T9.3** Local backup/restore (JSON file) — no cloud.
- **Gate G9**: tests green; manual test: correct one dish 5× ⇒ next prediction moves toward the user's value.

---

### Phase 10 — Hardening & release
- [ ] **T10.1** Benchmark `Interpreter` vs `CompiledModel` (GPU/NNAPI/NPU) per device; choose with automatic CPU fallback; 20-scan thermal test.
- [ ] **T10.2** APK/AAB size (ABI splits), models ≤ 40 MB total.
- [ ] **T10.3** Privacy review: no image persistence unless user saves it; buffers zeroed/closed; no logging of images.
- [ ] **T10.4** Model cards in `docs/model_cards/`, reproducibility (`dvc repro`, seeds), README demo, portfolio write-up.
- **Gate G10**: every earlier gate green · `check_all.sh` green · zero `PLACEHOLDER(` · demo recorded.
