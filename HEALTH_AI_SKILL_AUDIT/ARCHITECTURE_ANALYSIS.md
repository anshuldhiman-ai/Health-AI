# Architecture Analysis: Health-AI

> **Document Type**: Architecture Specification & Dependency Audit  
> **Source Repository**: `https://github.com/anshuldhiman-ai/Health-AI`  
> **Target Audience**: AI Agent Skill Developers & System Architects  
> **Date**: 2026-11-03  

---

## 1. High-Level Architecture Pattern

Health-AI adheres strictly to **Clean Architecture** combined with a **Feature-First modular structure** in Flutter, supported by a dual-sided engineering boundary between the mobile client (`app/`) and the training/export pipeline (`ml/`).

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                              │
│   Screens, Bottom Sheets, Dialogs, Custom Widgets, Design System       │
│   (Watches Riverpod StateNotifier / AsyncNotifier controllers)         │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Watches / Triggers
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        APPLICATION LAYER                               │
│   Feature Controllers, State Classes, Scan Isolates, Pipeline Runners   │
│   (e.g., FoodRecognizer, TodayState, DiaryState, ScanState)            │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Calls Inward
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                          DOMAIN LAYER                                  │
│   Pure Dart: Value Objects, Entities, Domain Services, Pure Math       │
│   (PlateGeometry, VolumetricMath, MassEstimator, NutritionCalculator)  │
│   *ZERO dependencies on Flutter, UI, or External Plugins*              │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ Implements / Supplies
┌───────────────────────────────────┴────────────────────────────────────┐
│                           DATA LAYER                                   │
│   Local Persistence (AppLocalStorage, SharedPreferences, SecureStore), │
│   Bundled JSON Catalog Loaders, Hardware Sensors (Step, Tilt)          │
└────────────────────────────────────────────────────────────────────────┘
```

### Verified Architectural Rules (Enforced by `app/test/architecture_test.dart`)
1. **Domain Isolation**: `app/lib/domain/` is strictly pure Dart. It may only import `dart:*`, `package:meta`, `package:collection`, and other files within `app/lib/domain/`. It is forbidden from importing Flutter UI, Riverpod, or any platform channels. *(Verified Implemented)*
2. **Design System Isolation**: `app/lib/design_system/` may only import `dart:*`, `package:flutter`, and itself. It never depends on application state, features, or domain business logic. *(Verified Implemented)*
3. **Core Isolation**: `app/lib/core/` provides cross-cutting primitives (`Result<T>`, `AppClock`, `AppLog`) and must never import `domain`, `data`, `features`, or `design_system`. *(Verified Implemented)*
4. **Data Isolation**: `app/lib/data/` may not import UI packages (`design_system`, `features`, or `app`). *(Verified Implemented)*
5. **Feature Encapsulation**: Features in `app/lib/features/<feature>/` are strictly isolated. No feature may import the internal application or presentation files of another feature. Cross-feature integration occurs only via top-level domain contracts or app-level routing. *(Verified Implemented)*

---

## 2. Layer Analysis & Module Interactions

### A. Presentation Layer (`app/lib/features/*/presentation/` & `app/lib/design_system/`)
- **Screen Lifecycle**: Screens are stateless or consumer widgets that delegate user interactions to Riverpod state controllers.
- **Visual Feedback**: Screens never execute raw data mutations directly. UI actions call methods on providers, which yield immutable states (`AsyncValue` or custom union states).
- **Design System Tokens (`app/lib/design_system/tokens/tokens.dart`)**: All spacing, radius, elevations, typography, and palette definitions are centralized in typed tokens, eliminating hardcoded magic numbers across widgets.

### B. Application Layer (`app/lib/features/*/application/`)
- **Isolate Offloading (`app/lib/features/scan/application/food_recognizer.dart`)**: Heavy CPU tasks (EXIF decoding, resizing, bilinear interpolation, tensor packing) run in background isolates via `compute()` or dedicated isolate queues, preserving a smooth 60/120 FPS UI thread.
- **Serialized Execution**: Native LiteRT model execution is guarded by an asynchronous queue (`_queue = _queue.then(...)`) ensuring that concurrent camera frames cannot race the underlying native C++ interpreter.

### C. Domain Layer (`app/lib/domain/`)
- **Entities (`app/lib/domain/entities/`)**: Defines core models such as `LogEntry`, `Macro`, `MealKind`, `NutritionTargets`, `PlateGeometry`, `DishRecord`, `Range`, `Macros`, and `ScanResult`.
- **Pure Math Services (`app/lib/domain/services/`)**:
  - `PlateGeometryCalculator`: Evaluates RANSAC algebraic ellipse fitting, foreshortening angle $\theta$, scale factor $s$, and real area $A_{\text{cm}^2}$.
  - `VolumetricMath`: Pure geometrical formulas converting container dimensions and segment areas into milliliters.
  - `MassEstimator`: Combines volume, food density, role priors, and empirical calibration factors.
  - `NutritionCalculator`: Implements Atwater factor sanity verification and Monte-Carlo uncertainty aggregation.

### D. Data Layer (`app/lib/data/`)
- **Multi-Tier Persistence (`app/lib/data/local_storage.dart`)**:
  - *Tier 1 (Authoritative)*: Synchronous atomic file writes (`app_kv_store.json`) with `.tmp` staging and `flush: true`.
  - *Tier 2 (Standard Platform)*: `SharedPreferences` cache.
  - *Tier 3 (Secure Mirror)*: `FlutterSecureStorage` using hardware-backed Android Keystore keys.
- **Nutrition Source of Truth (`app/lib/data/nutrition/dish_catalog.dart`)**: Bundled `khana_catalog.json` read via `rootBundle.loadString()`, ensuring zero network requests.

---

## 3. Data Flow Pipelines

### End-to-End Meal Capture & Recognition Flow

```
[ User captures photo via Camera preview ]
                   │
                   ▼
[ CameraController.takePicture() returns XFile ]
                   │
                   ▼
[ Background Isolate: preprocessFoodPhoto(bytes) ]
  ├── img.decodeImage(bytes)
  ├── img.bakeOrientation(decoded)
  ├── img.copyResize(oriented, shortSide: 255)
  ├── img.copyCrop(resized, 224x224 center)
  └── Float32List NHWC [1, 224, 224, 3] in [0.0, 1.0]
                   │
                   ▼
[ Native LiteRT Interpreter: interpreter.run(input, output) ]
                   │
                   ▼
[ Raw Logits / Probabilities Array (239 classes) ]
                   │
                   ▼
[ TopConfidence Analysis & Decision Tree ]
  ├── Ratio Check: top1 / top2 < 1.6?
  │     ├── YES: Execute Horizontal Flip TTA & Average Probabilities
  │     └── NO:  Proceed with single-pass distribution
  ├── Non-Food Gate: top1 < 0.15 AND (top3Mass < 0.48 AND ratio < 2.4)?
  │     ├── TRUE:  Flag isFood = false ("Not a food item")
  │     └── FALSE: Pass through
  └── Uncertainty Check: ratio < 1.35 OR top1 < 0.12?
        ├── TRUE:  Flag uncertain = true (Show top-3 options for user confirmation)
        └── FALSE: High confidence top-1 prediction
                   │
                   ▼
[ UI Scan Result Sheet (scan_result_sheet.dart) ]
  ├── User confirms or corrects dish selection
  ├── User selects serving size / enters portion grams
  └── User taps "Confirm & Add"
                   │
                   ▼
[ DayLog.addAndSave(LogEntry) -> AppLocalStorage (app_kv_store.json) ]
                   │
                   ▼
[ Riverpod Invalidation -> TodayScreen & DiaryScreen auto-refresh ]
```

---

## 4. Architectural Decision Records (ADRs) Audit

The project maintains 8 binding ADRs in `docs/adr/`. Below is an audit comparing documented decisions against actual code implementation:

| ADR ID | Title | Key Documented Mandate | Actual Implementation Verification | Classification |
| :--- | :--- | :--- | :--- | :--- |
| **ADR 0001** | Offline-First, No Network | No `INTERNET` permission in release manifest; no network SDKs; local assets only. | `AndroidManifest.xml` explicitly removes `INTERNET` and `ACCESS_NETWORK_STATE` with `tools:node="remove"`. Zero HTTP client packages in `pubspec.yaml`. Guardrails enforced by `tools/check_offline.sh`. | **Verified Implemented** |
| **ADR 0002** | Layer Discipline | Pure-Dart domain; Riverpod state management; go_router; inward dependency rule. | Enforced by `app/test/architecture_test.dart`. All domain entities and services are 100% pure Dart. | **Verified Implemented** |
| **ADR 0003** | Two Databases | Read-only `nutrition.db` and encrypted `user.db` via Drift + SQLCipher. | `drift` and `sqlcipher_flutter_libs` are declared in `pubspec.yaml`, but actual app persistence uses `AppLocalStorage` (atomic file + SharedPreferences + SecureStorage mirror) and JSON catalogs (`khana_catalog.json`). | **Partially Implemented / Documented Only** |
| **ADR 0004** | ML Smoke Test | Day-1 random-weights export and tiny smoke test to prevent conversion surprises. | Implemented in `ml/src/ml_pipeline/export/smoke_test.py` and automated in `.github/workflows/ml-ci.yml`. | **Verified Implemented** |
| **ADR 0005** | Timestamps & Day Boundaries | Day indexing by integer offset from today (0 = today, 1 = yesterday) to avoid timezone shift bugs. | Fully implemented in `DayLog` (`app/lib/app/log_store.dart`) and `LocalDate` (`app/lib/domain/services/local_date.dart`). | **Verified Implemented** |
| **ADR 0006** | Preprocessing Parity | Python training transforms must match Dart on-device transforms to $< 0.5\text{ pt}$ top-1 accuracy drop. | Implemented in `app/lib/features/scan/application/food_recognizer.dart` matching `ml/src/ml_pipeline/data/prepare.py`. Parity tests exist in `ml/tests/test_mass_reference.py`. | **Verified Implemented** |
| **ADR 0007** | Model Packaging & Integrity | Bundled models verified via SHA-256 at startup; fallback gracefully on tamper or mismatch. | Fallback on missing model is implemented in `food_recognizer.dart` (`ModelUnavailableException`), though SHA-256 manifest verification is planned in `AGENTS.md` D-13. | **Partially Implemented** |
| **ADR 0008** | Permissions Least Privilege | Minimal permissions; no audio, no broad storage, no location; automated `aapt2` dump check. | `AndroidManifest.xml` strips audio and storage; `tools/check_manifest.sh` verifies release AAB merged permissions in CI. | **Verified Implemented** |

---

## 5. Architectural Strengths & Technical Debt

### Key Strengths
1. **Automated Architectural Enforcement**: The existence of `architecture_test.dart` running in CI guarantees that layer discipline cannot degrade over time.
2. **Defensive Error Types**: Custom functional `Result<T>` (`Ok<T>` and `Err<T>`) eliminates uncaught exceptions in core business logic.
3. **Deterministic Dual Parity**: Volumetric and mass formulas are implemented in both Python (`ml/src/ml_pipeline/mass/reference.py`) and Dart (`app/lib/domain/services/`), validated against a shared test fixture `mass_vectors.json` to $\le 10^{-6}$ relative error.

### Technical Debt & Discrepancies
1. **Unused Database Dependencies**: `drift` and `sqlcipher_flutter_libs` add unnecessary native compilation overhead since the production code currently uses `AppLocalStorage` and JSON.
2. **Catalog Format Transition**: The legacy single-dish flow loads `khana_catalog.json` (80/239 classes), while the multi-dish engine (`AGENTS.md`) is transitioning to `dish_catalog.json` with 11 roles and 48 groups.
