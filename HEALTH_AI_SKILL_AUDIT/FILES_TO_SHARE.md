# Files to Share: Curated Source Package Manifest

> **Document Type**: Source Code Selection & Inclusion Manifest  
> **Source Repository**: `https://github.com/anshuldhiman-ai/Health-AI`  
> **Target Directory**: `HEALTH_AI_SKILL_AUDIT/SHARE_PACKAGE/`  
> **Date**: 2026-11-03  

---

## 1. Overview of `SHARE_PACKAGE`

To allow another AI agent to understand, reproduce, and build skills based on Health-AI's engineering architecture without transferring the entire 6 GB repository (which contains gigabytes of virtual environments, intermediate builds, video crops, and ML weights), a minimal curated package has been constructed in:

`HEALTH_AI_SKILL_AUDIT/SHARE_PACKAGE/`

- **Total Files Included**: 217 files
- **Total Uncompressed Size**: 1.59 MB (1,591,635 bytes)
- **Directory Structure**: 100% preserved relative to the repository root.

---

## 2. Included Files by Category and Justification

### Category 1: Architecture, Strategy & Governance (Root & `docs/`)
| File Path | Why It Is Critical for Skill Creation |
| :--- | :--- |
| `CLAUDE.md` | Single source of truth for non-negotiable rules (R1 to R13), coding standards, Clean Architecture layers, design tokens, and git commit guidelines. |
| `AGENTS.md` | Single source of truth for the 100% offline vision & nutrition engine, 11-role taxonomy, RANSAC ellipse formulas, spherical-cap katori modeling, and Gates G0–G10. |
| `README.md` | High-level product definition, user-facing features, and architectural goals. |
| `docs/adr/*.md` (ADRs 0001–0008) | Architecture Decision Records documenting offline-first (0001), layer discipline (0002), two databases (0003), ML smoke tests (0004), timestamps (0005), preprocessing parity (0006), model packaging (0007), and permissions (0008). |
| `docs/safety/nutrition_safety.md` | Clinical nutrition safety floors, warning thresholds, and eating disorder risk mitigation rules. |
| `docs/specs/capture_sop.md` | Standard operating procedure for capturing top-down meal photos and recording tare/gross scale mass. |
| `docs/BENCHMARKS.md` | Target device specifications (Reference Low-End Device - RLD), accuracy gates, latency budgets, and memory limits. |
| `docs/PROGRESS.md` | Sequential task checklist tracking tasks T0.1 through T10.4 and gate criteria. |
| `docs/THIRD_PARTY.md` | Permissive license audit covering all mobile and ML dependencies. |

### Category 2: Android Platform Hardening & Build Configuration (`app/android/`)
| File Path | Why It Is Critical for Skill Creation |
| :--- | :--- |
| `app/android/app/src/main/AndroidManifest.xml` | Demonstrates defensive permission stripping (`tools:node="remove"`) for `INTERNET`, `ACCESS_NETWORK_STATE`, and `RECORD_AUDIO`. |
| `app/android/app/build.gradle.kts` | Demonstrates Android Gradle Plugin (AGP) 8.x configuration, NDK filters, ProGuard obfuscation rules, and compile/target SDK 36. |
| `app/android/app/proguard-rules.pro` | Keep rules for LiteRT native JNI methods, SQLCipher, and serialized data models. |
| `app/android/app/src/main/res/xml/data_extraction_rules.xml` | Android 12+ data extraction configuration disabling cloud and device-to-device backup. |
| `app/android/app/src/main/kotlin/.../MainActivity.kt` | Native Android entry point. |

### Category 3: Flutter Application Core & State (`app/lib/`)
| File Path | Why It Is Critical for Skill Creation |
| :--- | :--- |
| `app/lib/main.dart` & `app/lib/app/app.dart` | App initialization sequence: orientation lock, Riverpod `ProviderScope`, and root theme injection. |
| `app/lib/app/router.dart` | `go_router` declarative routing, shell navigation tabs, and onboarding redirect guards. |
| `app/lib/app/log_store.dart` | Global meal history store (`DayLog`), day-offset indexing, and serialized atomic persistence queue. |
| `app/lib/core/error/result.dart` | Functional `Result<T>` (`Ok` / `Err`) and `Failure` hierarchy. |
| `app/lib/data/local_storage.dart` | Multi-tier persistence implementation: atomic file swaps (`.tmp` + `flush: true`), SharedPreferences, and Keystore mirror. |
| `app/lib/data/sensors/step_tracker.dart` | Hardware step detector listener with baseline subtraction and spike filtering. |
| `app/lib/data/sensors/capture_tilt_service.dart` | Accelerometer 3-axis gravity vector angle calculation and fusion with optical ellipse tilt. |
| `app/lib/design_system/tokens/tokens.dart` | Centralized spacing, border radii, elevations, and semantic typography. |
| `app/lib/features/scan/application/food_recognizer.dart` | LiteRT on-device inference, background isolate image preprocessing, Flip-TTA, and `TopConfidence` heuristics. |

### Category 4: Pure Dart Domain & Volumetric Math Engine (`app/lib/domain/`)
| File Path | Why It Is Critical for Skill Creation |
| :--- | :--- |
| `app/lib/domain/entities/dish_record.dart` | Core entities: `Range` (P10/P50/P90), `Macros`, `Role` (11 roles), `NutritionPer100g`, `DishVariant`. |
| `app/lib/domain/entities/plate_geometry.dart` | Geometrical entities: `PlateGeometry`, `FittedEllipse`, `Point2D`, `PlateKind`, `TiltSource`. |
| `app/lib/domain/entities/scan_result.dart` | Segmented scan result, top-K scoring, stage latency timings (`StageTimings`). |
| `app/lib/domain/services/plate_geometry_calculator.dart` | Pure Dart RANSAC 5-point subset selection + 5x5 algebraic least-squares ellipse fitting. |
| `app/lib/domain/services/volumetric_math.dart` | Analytical volume calculations: spherical-cap katori model, mound/layer, and piece modes. |
| `app/lib/domain/services/mass_estimator.dart` | Mass prediction engine applying density priors, calibration multipliers, and confidence quantiles. |
| `app/lib/domain/services/nutrition_calculator.dart` | Atwater sanity checks, cooking variant oil adjustments, and 500-sample Monte-Carlo uncertainty aggregation. |

### Category 5: Automated Testing, Parity & Fixtures (`app/test/` & `ml/tests/`)
| File Path | Why It Is Critical for Skill Creation |
| :--- | :--- |
| `app/test/architecture_test.dart` | Static architectural import scanner enforcing Clean Architecture layer discipline. |
| `app/test/fixtures/mass_vectors.json` | Golden mathematical test vectors for cross-language validation. |
| `app/test/domain/services/*_test.dart` | 100% test coverage for geometry, volumetric math, mass estimation, and nutrition calculations. |
| `ml/src/ml_pipeline/mass/reference.py` | Python reference implementation of volumetric math and mass priors. |
| `ml/tests/test_mass_reference.py` | Pytest suite validating Python math against `mass_vectors.json`. |

### Category 6: CI Workflows & Quality Gate Scripts (`tools/` & `.github/`)
| File Path | Why It Is Critical for Skill Creation |
| :--- | :--- |
| `tools/check_manifest.sh` | Shell script verifying release APK/AAB merged permissions with `aapt2 dump permissions`. |
| `tools/check_offline.sh` | Shell script verifying manifest node removal and banning remote networking packages. |
| `tools/check_licenses.sh` | License hygiene auditor scanning for banned AGPL Ultralytics code. |
| `tools/check_all.py` | Cross-platform master quality gate orchestrating all checks. |
| `.github/workflows/app-ci.yml` | GitHub Actions workflow for Flutter formatting, analysis, testing, and release checks. |
| `.github/workflows/ml-ci.yml` | GitHub Actions workflow for Python ruff, pytest, and tiny-model export smoke tests. |

---

## 3. Excluded Directories and Rationale

The following directories are intentionally omitted from `SHARE_PACKAGE`:

| Excluded Directory | Reason for Exclusion |
| :--- | :--- |
| `.git/` | Version control metadata; redundant for skill engineering. |
| `app/build/` & `app/.dart_tool/` | Generated compiler artifacts and intermediate build outputs (~3.4 GB). |
| `ml/.venv/` | Python virtual environment holding >50,000 files in `site-packages` (~2.5 GB). |
| `ml/weights/` & `ml/artifacts/` | Heavy trained model checkpoints (`.pt`, `.onnx`, `.npy` files exceeding 2.5 GB). Model architecture and export code are preserved instead. |
| `app/assets/models/*.tflite` | Compiled model binary weights. Replaced by `README.md`, `labels.json`, and `container_profiles.json`. |
| `releases/` | Compiled release APK binaries (~285 MB). |
| `ref_crops/` & root UI screenshots | PNG visual design slices (~30 MB). |
| `app/test/goldens/` | Binary PNG reference images used for pixel testing (~2 MB). The test code referencing them is included. |

---

## 4. Security & Credentials Verification

A comprehensive recursive regex scan of `SHARE_PACKAGE` was executed:
- **No private keys, certificates, or keystores** (`.jks`, `.keystore`, `.pem`, `.p12`).
- **No environment files or secrets** (`.env`, `.env.local`).
- **No API keys or cloud tokens** (all occurrences of "secret", "token", or "password" are code comments, design token names, or documentation explaining that no secrets exist).
