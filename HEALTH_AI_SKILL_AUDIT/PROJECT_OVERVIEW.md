# Project Overview: Health-AI

> **Document Type**: Technical Audit & Skill Preparation Dossier  
> **Target Audience**: AI Agent Skill Developers, Software Architects, ML/Mobile Engineers  
> **Source Repository**: `https://github.com/anshuldhiman-ai/Health-AI`  
> **Local Root**: `f:\CODING\HACKER WORK\Health AI`  
> **Date**: 2026-11-03  

---

## 1. Executive Summary & Purpose

**Health-AI** is a privacy-first, 100% offline Android wellness and nutrition application built with Flutter and an on-device Machine Learning pipeline. The application delivers daily macro and calorie tracking, hydration monitoring, sleep logging, and step tracking, anchored by an on-device vision engine capable of recognizing Indian meals and decomposing composite meal plates (such as an Indian thali with rice, dal, roti, and sabzi).

### Core Differentiating Philosophy
Unlike the overwhelming majority of commercial nutrition and fitness applications that rely on cloud backends, remote multi-modal LLM APIs (OpenAI GPT-4o, Google Gemini, Anthropic Claude), and telemetry networks, Health-AI operates under an uncompromising **100% Offline-First Invariant**:
- **Zero Remote Network Dependencies in Release Builds**: The Android release manifest strips `android.permission.INTERNET` and `android.permission.ACCESS_NETWORK_STATE` using explicit `tools:node="remove"` directives.
- **On-Device Edge Inference**: Food vision inference executes entirely on-device via LiteRT (formerly TensorFlow Lite / Google AI Edge) using quantized MobileNetV4 models.
- **Local Cryptographic Persistence**: User data, meal logs, and preferences reside solely on the physical device, using multi-layer durability (atomic JSON file storage, `SharedPreferences`, and Android Keystore-backed `FlutterSecureStorage`).
- **Honest Accuracy Contract**: Nutrition and mass are never rendered as misleading single-point pseudoscientific numbers; they are computed and presented as empirical confidence intervals ($P_{10} / P_{50} / P_{90}$ percentile ranges) calibrated to actual Indian meal densities and plate geometries.

---

## 2. Technology Stack & Framework Inventory

Every technology listed below has been verified against the physical local repository.

| Domain | Technology / Library | Version / Spec | Repository Source File | Classification | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Mobile Framework** | Flutter SDK / Dart SDK | Flutter 3.29.x / Dart 3.7+ (`.fvmrc`: 3.29.0) | `app/.fvmrc`, `app/pubspec.yaml` | Verified Implemented | Cross-platform mobile runtime targeting Android 8.0+ (API 26 to 36). |
| **State Management** | `flutter_riverpod` | `^2.6.1` (`riverpod_generator`) | `app/pubspec.yaml`, `app/lib/app/log_store.dart` | Verified Implemented | Compile-safe reactive dependency injection, state invalidation, and async loading. |
| **Navigation & Routing** | `go_router` | `^14.6.2` | `app/lib/app/router.dart` | Verified Implemented | Declarative routing with deep links, shell navigators, and onboarding redirect guards. |
| **On-Device ML Runtime** | `flutter_litert` | `^0.1.0` | `app/lib/features/scan/application/food_recognizer.dart` | Verified Implemented | Google LiteRT C++ native runtime bindings executing TFLite models on mobile CPU. |
| **Image Preprocessing** | `image` (pure Dart) | `^4.3.0` | `app/lib/features/scan/application/food_recognizer.dart` | Verified Implemented | EXIF orientation baking, bilinear resizing, center-cropping, and RGB float32 tensor conversion. |
| **Camera & Capture** | `camera` | `^0.11.0` | `app/pubspec.yaml`, `app/lib/features/scan/presentation/scan_screen.dart` | Verified Implemented | Camera preview, still-image capture (`takePicture()`) without audio/video permissions. |
| **Sensors & Hardware** | `pedometer`, `sensors_plus` pattern | `^4.2.0` | `app/lib/data/sensors/step_tracker.dart`, `app/lib/data/sensors/capture_tilt_service.dart` | Verified Implemented | Step counting hardware event streams and accelerometer-based 3-axis tilt measurement. |
| **Local Persistence** | `SharedPreferences`, `flutter_secure_storage` | `^2.5.6`, `^9.2.4` | `app/lib/data/local_storage.dart`, `app/lib/app/log_store.dart` | Verified Implemented | Multi-layer local KV store, atomic file writes (`app_kv_store.json`), and hardware keystore encryption. |
| **Database Engines** | `drift`, `sqlcipher_flutter_libs` | `^2.22.0`, `^0.6.4` | `app/pubspec.yaml`, `docs/adr/0003-two-databases.md` | Partially Implemented / Documented Only | Included in `pubspec.yaml` and documented in ADR 0003, but production app state currently uses `AppLocalStorage` & `khana_catalog.json`. |
| **Data Visualization** | `fl_chart` | `^0.69.2` | `app/lib/features/activity/presentation/activity_screen.dart`, `app/lib/features/insights/presentation/` | Verified Implemented | Custom-styled hourly step bar charts and historical trend visualizations. |
| **Model Training & ML** | PyTorch, `timm` | PyTorch 2.x, timm 1.0+ | `ml/pyproject.toml`, `ml/src/ml_pipeline/models/classifier.py` | Verified Implemented | MobileNetV4 training pipeline, EMA weights, cosine annealing, and CrossEntropy/Dice losses. |
| **Model Conversion** | `onnx2tf`, `litert-torch` / `ai_edge_torch` | Python 3.12+ | `ml/src/ml_pipeline/export/litert.py`, `ml/scripts/export_onnx2tf.py` | Verified Implemented | Conversion pipeline from PyTorch checkpoint to ONNX to LiteRT INT8/FP32 `.tflite` binaries. |
| **Data Versioning** | DVC (Data Version Control) | `dvc.yaml` | `ml/dvc.yaml` | Verified Implemented | Tracks dataset pipelines, preparation, splits, and training artifacts. |
| **CI / Quality Gate** | GitHub Actions, custom Bash/Python runners | Ubuntu-latest | `.github/workflows/app-ci.yml`, `.github/workflows/ml-ci.yml`, `tools/check_all.py` | Verified Implemented | Automated linting, static analysis, unit/widget/golden tests, permission manifest dump, and offline invariant checks. |

---

## 3. High-Level Repository Architecture

The workspace is organized into a clean monorepo separating mobile client engineering, machine learning pipelines, shared documentation, and release verification tools.

```
Health-AI/
├── .github/workflows/                 # Automated CI/CD pipelines
│   ├── app-ci.yml                     # Flutter formatting, analysis, testing, AAB manifest checks
│   └── ml-ci.yml                      # Python linting, pytest, tiny-model export smoke tests
├── app/                               # Production Flutter Mobile Application
│   ├── android/                       # Hardened Android native host project
│   ├── assets/                        # Bundled offline assets (models, nutrition catalog, fonts)
│   │   ├── fonts/                     # Plus Jakarta Sans (OFL license)
│   │   ├── models/                    # baseline.tflite, labels.json, container_profiles.json
│   │   └── nutrition/                 # khana_catalog.json (macronutrient/calorie database)
│   ├── lib/                           # Clean Architecture source tree
│   │   ├── app/                       # App bootstrap, lifecycle, router, global log store
│   │   ├── core/                      # Cross-cutting primitives (Result<T>, Clock, Log, UI icons)
│   │   ├── data/                      # Local storage, nutrition catalog loader, sensor services
│   │   ├── design_system/             # Design tokens, typography, custom components, themes
│   │   ├── domain/                    # Pure Dart entities, value objects, and deterministic math services
│   │   │   ├── entities/              # DishRecord, PlateGeometry, ScanResult, LogEntry, Macro
│   │   │   └── services/              # PlateGeometryCalculator, VolumetricMath, MassEstimator, NutritionCalculator
│   │   ├── features/                  # Feature-first application modules
│   │   │   ├── activity/              # Step tracker, sensor listener, hourly bar charts
│   │   │   ├── diary/                 # Food diary, meal breakdowns, item deletions
│   │   │   ├── insights/              # Long-term macro trends, weekly scorecards
│   │   │   ├── onboarding/            # Welcome gate, profile initialization
│   │   │   ├── profile/               # Macro targets, user height/weight, permissions review
│   │   │   ├── scan/                  # Camera viewfinder, food recognizer, scan result sheets
│   │   │   ├── search/                # Manual food catalog lookup and custom dish details
│   │   │   ├── sleep/                 # Sleep logging sheet, goal controls, duration rings
│   │   │   ├── today/                 # Daily summary dashboard, calorie ring, macro meters
│   │   │   └── water/                 # Hydration quick-logging buttons and daily targets
│   │   └── l10n/                      # Localization ARBs (English, Hindi, Punjabi) and generated delegates
│   └── test/                          # Unit, widget, architecture, and golden visual test suites
├── docs/                              # Engineering specifications, ADRs, safety guidelines
│   ├── adr/                           # Architecture Decision Records (ADRs 0001 through 0008)
│   ├── safety/                        # Clinical and nutritional safety rules (ED risk mitigations)
│   ├── specs/                         # Capture standard operating procedures and annotation rules
│   ├── BENCHMARKS.md                  # Accuracy, latency, memory, and APK size benchmarks
│   ├── PROGRESS.md                    # Single-source-of-truth task and phase gate tracker
│   └── THIRD_PARTY.md                 # Permissive license registry for all runtime dependencies
├── ml/                                # Machine Learning, Training, and Export Pipeline
│   ├── data/                          # Dataset schemas, licenses, class mappings, weighed plates CSV
│   ├── notebooks/                     # Colab cloud training and export notebooks
│   ├── scripts/                       # Dataset ingest, splitting, training, export, and verification scripts
│   ├── src/ml_pipeline/               # Reusable Python ML package (data, models, train, eval, export, mass)
│   ├── taxonomy/                      # Hierarchical role and group taxonomies (taxonomy_v1.yaml)
│   ├── tests/                         # Pytest test suite (42 tests covering ingest, export, mass parity)
│   ├── pyproject.toml                 # uv package configuration
│   └── dvc.yaml                       # Data version control pipeline definitions
├── tools/                             # Automation, gate runners, and release scripts
│   ├── check_all.py                   # Master cross-platform guardrail script
│   ├── check_offline.sh               # Enforces manifest node removal and forbids networking packages
│   ├── check_licenses.sh              # Audits codebase against banned AGPL/GPL libraries (e.g. Ultralytics)
│   ├── check_manifest.sh              # aapt2 dump permissions gate on final release APK/AAB
│   └── size_budget.sh                 # Enforces APK binary footprint budgets
├── AGENTS.md                          # Comprehensive 100% offline vision & nutrition engine specification
└── CLAUDE.md                          # Non-negotiable repository engineering rules and coding standards
```

---

## 4. Key Functional Modules & Responsibilities

### 1. Vision & Recognition Engine (`app/lib/features/scan/`)
- Manages camera stream capture, native frame downscaling, and on-device LiteRT execution.
- Implements test-time augmentation (horizontal flip averaging) when confidence is marginal.
- Employs distribution margin heuristics ($\text{top}_1 / \text{top}_2$ ratio and top-3 mass concentration) rather than naive raw probability thresholds to detect non-food images and flag classification uncertainty.

### 2. Pure Dart Geometry & Volumetric Mass Engine (`app/lib/domain/services/`)
- **Plate Geometry (`PlateGeometryCalculator`)**: RANSAC 5-point subset selection followed by 5x5 algebraic least-squares ellipse fitting to recover semi-axes $(a, b)$, foreshortening tilt angle $\theta = \arccos(b/a)$, metric scale $s = D / (2a)$, and optical/IMU sensor fusion.
- **Volumetric Math (`VolumetricMath`)**: Computes 3D food volume using analytical physics priors:
  - *Spherical-cap katori model*: $V = \frac{\pi h^2 (3R - h)}{3}$ where $R = \frac{a_c^2 + d_c^2}{2 d_c}$.
  - *Mound / Layer model*: $V = A_{\text{cm}^2} \times h_{\text{eff}}$.
  - *Piece model*: $m = n \times \text{unit\_mass} \times \text{clamp}(A / A_{\text{ref}}, 0.6, 1.5)$.
- **Mass Estimator (`MassEstimator`)**: Applies calibrated empirical density factors and outputs confidence ranges ($P_{10} / P_{50} / P_{90}$).
- **Nutrition Calculator (`NutritionCalculator`)**: Validates Atwater energy equivalence ($4P + 4C + 9F \approx \text{kcal}$ within $\pm 12\%$), applies cooking variant oil delta ($\pm 9\text{ kcal/g}$ fat delta), and performs 500-sample Monte-Carlo uncertainty aggregation incorporating shared plate scale covariance.

### 3. Local State & Persistence Core (`app/lib/app/log_store.dart` & `app/lib/data/local_storage.dart`)
- Eliminates cloud databases in favor of an in-memory reactive state synchronized to a multi-tiered local storage engine.
- Implements atomic file swaps (`.tmp` write followed by atomic rename) with POSIX/Android `flush: true` to prevent data corruption during OS process termination.
- Manages day-boundary offset shifts (0 = today, 1 = yesterday) so historical diary entries retain temporal integrity without timezone conversion bugs.

### 4. Sensor & Activity Processing (`app/lib/data/sensors/`)
- Listens to Android hardware step detector / step counter events via `pedometer`.
- Maintains day baselines and filters corrupt step spikes.
- Reads 3-axis accelerometer gravity vectors to compute real-time camera pitch angle for HUD warnings and optical ellipse tilt fusion.

---

## 5. Artifact & Resource Hygiene

The local workspace contains generated, development-only, and heavy binary directories that are strictly excluded from the skill share package:
- `app/build/`, `app/.dart_tool/`: Generated intermediate Flutter build artifacts and FVM cache.
- `ml/.venv/`, `ml/.pytest_cache/`, `ml/.ruff_cache/`: Python virtual environments (over 50,000 files in `site-packages`) and linter caches.
- `ml/weights/`, `ml/artifacts/`: Heavy model checkpoints (`.pt`, `.onnx`, `.npy` files exceeding 2.5 GB).
- `releases/`: Compiled release APK binaries (~285 MB).
- `ref_crops/`: UI design reference slice images.

All necessary engineering logic, configuration files, test suites, and documentation are isolated cleanly in `HEALTH_AI_SKILL_AUDIT/SHARE_PACKAGE/`.
