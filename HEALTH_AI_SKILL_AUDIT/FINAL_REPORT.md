# Final Audit Report: Health-AI

> **Document Type**: Comprehensive Engineering Audit, Technical Findings & Skill Delivery Report  
> **Source Repository**: `https://github.com/anshuldhiman-ai/Health-AI`  
> **Local Root Path**: `f:\CODING\HACKER WORK\Health AI`  
> **Auditors**: Senior Software Architect, Flutter Specialist, Edge AI Engineer & Privacy Lead  
> **Completion Date**: 2026-11-03  

---

## 1. Executive Summary

A comprehensive architectural inspection and security audit of the **Health-AI** codebase was conducted. Health-AI is a Flutter-based mobile wellness and nutrition tracking application designed from first principles to operate **100% offline** on Android devices, pairing local SQLite/JSON persistence with an on-device Edge AI vision engine for Indian food recognition and volumetric nutrition analysis.

This audit report and the accompanying knowledge artifacts in `HEALTH_AI_SKILL_AUDIT/` provide everything needed for an external AI coding assistant to understand, reproduce, extend, and package the engineering practices of this repository into an autonomous AI Agent Skill.

---

## 2. Technology Inventory (Verified against Codebase)

| Layer | Component | Implementation Status | Verified Path |
| :--- | :--- | :--- | :--- |
| **Mobile Client** | Flutter 3.29.x / Dart 3.7+ | Verified Implemented | `app/.fvmrc`, `app/pubspec.yaml` |
| **State Management** | Riverpod 2.6.1 (`flutter_riverpod`) | Verified Implemented | `app/lib/app/log_store.dart` |
| **Navigation** | go_router 14.6.2 | Verified Implemented | `app/lib/app/router.dart` |
| **ML Inference** | Google LiteRT (`flutter_litert` 0.1.0) | Verified Implemented | `app/lib/features/scan/application/food_recognizer.dart` |
| **Image Preprocessing** | Pure Dart `image` 4.3.0 | Verified Implemented | `app/lib/features/scan/application/food_recognizer.dart` |
| **Local Persistence** | Atomic File IO + SharedPreferences + Keystore Mirror | Verified Implemented | `app/lib/data/local_storage.dart` |
| **Pure Geometrical Math** | RANSAC Ellipse Fitting & 3D Volumetric Math | Verified Implemented | `app/lib/domain/services/` |
| **Sensors** | Pedometer + Accelerometer 3-Axis Tilt | Verified Implemented | `app/lib/data/sensors/` |
| **ML Training & Export** | PyTorch + timm (MobileNetV4), onnx2tf, litert-torch | Verified Implemented | `ml/src/ml_pipeline/` |
| **Quality Gates** | Automated Python/Bash runners (7 checks) | Verified Implemented | `tools/check_all.py`, `tools/check_manifest.sh` |

---

## 3. Major Architectural Findings

### 1. Inward Dependency Discipline (Clean Architecture)
The repository strictly enforces a pure-Dart domain layer (`app/lib/domain/`). A custom static analysis test (`app/test/architecture_test.dart`) runs in CI and inspects Dart import strings to guarantee that domain entities, value objects, and mathematical services never import Flutter UI, Riverpod, or native platform channels.

### 2. Multi-Class Confidence Heuristics
The classification pipeline rejects the common mistake of applying fixed probability cutoffs. Instead, it computes the **relative ratio between the top-1 and runner-up classes** ($\text{top}_1 / \text{top}_2$) and evaluates **top-3 mass concentration** to distinguish genuine food ambiguity from non-food inputs (e.g. keyboards, pets, furniture). When ambiguity is detected, it executes a horizontal-flip test-time augmentation (TTA) pass to average distributions before prompting the user with the top-3 candidates.

### 3. Cross-Language Numerical Parity
Volumetric katori formulas, mound geometry, and mass density scaling are implemented identically in both Python (`ml/src/ml_pipeline/mass/reference.py`) and Dart (`app/lib/domain/services/mass_estimator.dart`). Both implementations are continuously validated against a shared test fixture (`app/test/fixtures/mass_vectors.json`), maintaining relative discrepancy $\le 10^{-6}$.

### 4. Manifest-Level Offline Enforcement
The release Android manifest strips `INTERNET` and `ACCESS_NETWORK_STATE` using `tools:node="remove"`. Furthermore, an automated CI gate executes `aapt2 dump permissions` on the final release `.aab` bundle to ensure third-party native plugins cannot silently re-add network access.

---

## 4. Discrepancies: Documentation vs. Actual Implementation

In accordance with Phase 2 instructions, the audit identified the following key discrepancies between documented architecture and physical code:

1. **Drift + SQLCipher Database Migration**:
   - *Documented (ADR 0003)*: Mandated two SQLite databases: an unencrypted `nutrition.db` and an encrypted `user.db` via SQLCipher.
   - *Actual Implementation*: `drift` and `sqlcipher_flutter_libs` are present in `pubspec.yaml`, but the production codebase persists user health data via `AppLocalStorage` (atomic file IO on `app_kv_store.json`, `SharedPreferences`, and `FlutterSecureStorage` mirror). The food database is loaded from `app/assets/nutrition/khana_catalog.json`.
   - *Classification*: **Partially Implemented / Documented Only**.
2. **Hardcoded Sandbox Path Fallbacks**:
   - In `app/lib/data/local_storage.dart`, lines 38-41 attempt to open `/data/user/0/com.anshuldhiman.app/files` directly. While guarded by try/catch, dynamic sandbox path resolution via `path_provider` is recommended for multi-user / work profile support.
   - *Classification*: **Recommended Improvement**.
3. **Multi-Dish Model Artifacts**:
   - The multi-dish segmentation and embedding models specified in `AGENTS.md` (MobileNetV4 role segmenter and proto embedder) have their pure Dart mathematical consumers fully implemented in `app/lib/domain/services/`, while the trained model weights are currently undergoing export in Phase 3/4.
   - *Classification*: **Partially Implemented**.

---

## 5. Security & Privacy Audit Findings

1. **Zero Secret Exposure**: Recursive regex inspection confirmed zero hardcoded API keys, private certificates, passwords, or tokens in the repository.
2. **Zero Telemetry**: No third-party analytics or crash reporting SDKs (no Firebase, Sentry, Mixpanel) exist in the production app.
3. **No Photo Leakage**: Meal photos are processed in temporary memory isolates and never saved to the public Android MediaStore.
4. **License Hygiene**: The codebase is 100% free of banned AGPL libraries (such as Ultralytics YOLO), ensuring compliance with Locked Decision D-02.

---

## 6. Structure of the Generated Audit Artifacts

All documentation has been compiled in `HEALTH_AI_SKILL_AUDIT/`:

| Document | Purpose |
| :--- | :--- |
| `PROJECT_OVERVIEW.md` | Executive summary, core features, framework inventory, and high-level structure. |
| `ARCHITECTURE_ANALYSIS.md` | Clean Architecture layer analysis, data flow diagrams, and ADR compliance audit. |
| `FLUTTER_ENGINEERING.md` | Riverpod state patterns, routing, atomic file persistence, and Result<T> error handling. |
| `AI_ML_ENGINEERING.md` | LiteRT on-device inference, Flip-TTA, RANSAC ellipse geometry, and 3D volumetric math. |
| `PRIVACY_SECURITY_AUDIT.md` | Android manifest node removal, permissions allow-list, sandbox isolation, and security risks. |
| `TESTING_AND_QUALITY.md` | 149 Dart tests, 42 Pytest tests, architecture linter, and dual-language parity fixtures. |
| `REUSABLE_ENGINEERING_PATTERNS.md` | Step-by-step implementation guide for 7 reusable production patterns. |
| `SKILL_REQUIREMENTS.md` | Functional capabilities, references, workflows, and limitations for an AI Agent Skill. |
| `FILES_TO_SHARE.md` | Detailed manifest of all 217 source files selected for the share package. |
| `FINAL_REPORT.md` | This summary report. |

---

## 7. Share Package Metrics (`SHARE_PACKAGE`)

- **Root Location**: `HEALTH_AI_SKILL_AUDIT/SHARE_PACKAGE/`
- **Total Files Included**: 217 files
- **Total Uncompressed Size**: 1.59 MB (1,591,635 bytes)
- **Excluded Content**: All `.git/`, `build/`, `.dart_tool/`, `ml/.venv/`, model weights (`.tflite`, `.pt`, `.onnx`), release APKs, and UI design screenshots.
- **Directory Structure**: 100% preserved relative to the repository root.
