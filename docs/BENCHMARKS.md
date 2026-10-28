# BENCHMARKS.md — Health AI Performance & Accuracy Benchmarks

> **Golden Rule 3**: Never invent numbers. Every accuracy/latency/size figure must come from a script that writes a file.
> If the number has not been measured yet, write `TBD` — never a guess.

---

## 1. Reference Low-End Device (RLD) Specification

All target latency and memory gates are benchmarked against this device:

* **Device Model**: `TBD (To be recorded by owner in T0.2)` (e.g. Samsung Galaxy A14 / Redmi 12)
* **Chipset**: `TBD`
* **RAM**: $\le$ 4 GB LPDDR4X
* **OS**: Android 13 or 14 (API level 33/34)
* **Inference Runtime**: CPU / NNAPI / GPU (LiteRT `Interpreter`)

---

## 2. Gate Metrics vs Targets (Gate G0 Baseline & Targets)

| Area | Metric | v1 Ship Gate (Must) | Stretch Target | Baseline (v1.9 Current) | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Segmentation** | Food-role mIoU | $\ge 0.70$ | $\ge 0.78$ | N/A (Single-dish classifier) | Pending Phase 3 |
| | Plate IoU | $\ge 0.93$ | $\ge 0.96$ | N/A | Pending Phase 3 |
| **Classification** | Top-1 (239 dishes) | $\ge 85\%$ | $\ge 90\%$ | `TBD` (Measured on test set) | In Progress |
| | Top-3 (239 dishes) | $\ge 95\%$ | $\ge 97\%$ | `TBD` | In Progress |
| **Mass** | Median per-item abs % error | $\le 25\%$ | $\le 18\%$ | N/A (Fixed portion) | Pending Phase 8 |
| **Calories** | Median total-meal abs % error | $\le 20\%$ | $\le 15\%$ | N/A | Pending Phase 8 |
| **Intervals** | Nominal 80% coverage (P10–P90) | $70 - 88\%$ | $75 - 85\%$ | N/A | Pending Phase 8 |
| **Latency** | Scan $\to$ Result (p50) | $\le 1.6\text{ s}$ | $\le 1.0\text{ s}$ | `TBD` | Benchmark T0.2 |
| | Scan $\to$ Result (p90) | $\le 2.5\text{ s}$ | $\le 1.8\text{ s}$ | `TBD` | Benchmark T0.2 |
| **Memory** | Peak RAM during scan | $\le 350\text{ MB}$ | $\le 250\text{ MB}$ | `TBD` | Benchmark T0.2 |
| **Size** | All models + catalog in APK | $\le 40\text{ MB}$ | $\le 30\text{ MB}$ | ~18 MB (`baseline.tflite` + `labels.json`) | Meets gate |
| **APK Size** | Total Release APK | $\le 160\text{ MB}$ | $\le 100\text{ MB}$ | 147.5 MB (`HealthAI-release.apk`) | Meets gate |
| **Robustness** | Consecutive scans, 0 leaks/crashes| 50 scans | 200 scans | `TBD` | Benchmark T6.6 |

---

## 3. Latency Budget Breakdown (on RLD)

| Stage | Target Budget | Measured p50 | Measured p90 | Notes |
| :--- | :--- | :--- | :--- | :--- |
| Image Preprocessing (downscaled decode to 512×512) | $\le 120\text{ ms}$ | `TBD` | `TBD` | `ui.instantiateImageCodec` native downscale |
| Role Segmenter (MobileNetV4-Small FPN INT8) | $\le 400\text{ ms}$ | `TBD` | `TBD` | Background isolate execution |
| Mask Post-Processing (Components + Watershed) | $\le 150\text{ ms}$ | `TBD` | `TBD` | Pure Dart |
| Dish Embedder (MobileNetV4-M, $\le 8$ crops) | $\le 480\text{ ms}$ | `TBD` | `TBD` | $\le 60\text{ ms}$ per crop |
| Geometry + Volumetric Math + Nutrition | $\le 30\text{ ms}$ | `TBD` | `TBD` | Deterministic Dart math |
| UI Overlay & Sheet Presentation | $\le 100\text{ ms}$ | `TBD` | `TBD` | 60 FPS flutter render |
| **Total Pipeline (p50 / p90)** | $\le 1.6\text{ s} / 2.5\text{ s}$ | `TBD` | `TBD` | |

---

## 4. Test Suite Baseline (as of Phase 0 / Task T0.2)

* **Flutter Unit & Widget Tests**:
  * Date: 2026-10-28
  * Command: `cd app; flutter test`
  * Result: **115 passed** (7 skipped goldens) in 16s.
  * Status: **100% Green**.
* **Python ML Tests**:
  * Date: 2026-10-28
  * Command: `cd ml; uv run pytest`
  * Result: **21 passed** in 18s (`test_export`, `test_metrics`, `test_prepare`, `test_splits`, `test_taxonomy`).
  * Status: **100% Green**.
