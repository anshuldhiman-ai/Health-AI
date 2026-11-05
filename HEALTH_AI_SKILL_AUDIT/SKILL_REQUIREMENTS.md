# AI Agent Skill Requirements: Health-AI

> **Document Type**: Specification for Creating a Reusable Antigravity / Claude Agent Skill  
> **Source Repository**: `https://github.com/anshuldhiman-ai/Health-AI`  
> **Target Audience**: AI Skill Authors & Agent System Engineers  
> **Date**: 2026-11-03  

---

## 1. Skill Identity & Purpose

The proposed skill, tentatively named `health-ai-offline-vision-engine`, encapsulates the engineering methodology, architecture, and coding patterns of the **Health-AI** codebase.

Its purpose is to equip AI coding assistants with the deep domain knowledge required to build, test, refactor, and maintain high-performance, **100% offline-first Flutter applications** equipped with **on-device LiteRT ML vision**, **pure Dart computer vision geometry**, and **resilient local persistence**.

---

## 2. Supported Tasks & Capabilities

An agent powered by this skill must be capable of executing the following specialized workflows:

### 1. Offline-First Mobile Hardening
- Audit and configure Android manifests using `tools:node="remove"` for `INTERNET`, `ACCESS_NETWORK_STATE`, and unnecessary sensor/storage permissions.
- Author CI gate scripts using `aapt2` to verify binary permissions in final release APK/AAB bundles.
- Configure dependency manifests (`pubspec.yaml`) to block remote networking and cloud SDKs.

### 2. Clean Architecture Layer Discipline in Flutter
- Enforce strict separation between Presentation, Application, Domain, and Data layers.
- Implement pure Dart domain entities and services with zero Flutter/external dependencies.
- Write and run automated architectural linting tests (`architecture_test.dart`) that scan Dart imports in CI.

### 3. Edge AI & LiteRT Model Integration
- Integrate Google LiteRT / TFLite interpreters inside long-lived isolates or serialized async execution queues.
- Implement pure Dart image preprocessing (EXIF orientation, bilinear resize, center crop, NHWC tensor formatting) matching PyTorch / torchvision eval transforms.
- Implement distribution-aware confidence heuristics (top-1/top-2 margin ratios, top-3 mass concentration, horizontal-flip TTA) to detect out-of-domain/non-food images and flag ambiguity.

### 4. Pure Dart Computer Vision & Volumetric Math
- Implement algebraic least-squares ellipse fitting and RANSAC contour sampling to derive metric scale $s$ and foreshortening tilt angle $\theta$.
- Implement 3D analytical geometry models (spherical-cap katori bowls, mounds, layers, and piece-based counts).
- Formulate empirical mass density priors and Atwater calorie validation ($4P + 4C + 9F \approx \text{kcal}$).
- Author dual-language parity tests ensuring Python calibration code and Flutter Dart math agree to $\le 10^{-6}$ relative tolerance.

### 5. Multi-Tier Durable Local Persistence
- Implement atomic file-writing strategies (`.tmp` write with `flush: true` followed by atomic rename) for crash-proof JSON persistence.
- Layer `SharedPreferences` caching and Android Keystore-backed `FlutterSecureStorage` with timeout guards.
- Design corruption-tolerant deserialization flows that gracefully recover without app-crashing exceptions.

---

## 3. Required References & Source Inputs

To execute these tasks without access to the full 6 GB repository, an AI agent requires the following curated source files bundled in `HEALTH_AI_SKILL_AUDIT/SHARE_PACKAGE/`:

1. **Architecture & Project Rules**:
   - `CLAUDE.md`: Non-negotiable engineering rules, Clean Architecture layers, naming conventions.
   - `AGENTS.md`: Volumetric nutrition engine specification, 11-role taxonomy, mathematical formulas.
   - `docs/adr/0001-offline-first.md` through `0008-permissions-manifest.md`: Binding architectural decisions.
2. **Flutter Application Implementations**:
   - `app/lib/app/log_store.dart`: Riverpod global diary state with serialized writes.
   - `app/lib/data/local_storage.dart`: Multi-tier persistence implementation.
   - `app/lib/core/error/result.dart`: Sealed `Result<T>` and `Failure` definitions.
   - `app/lib/features/scan/application/food_recognizer.dart`: On-device LiteRT inference, preprocessing, and Flip-TTA.
   - `app/lib/domain/services/plate_geometry_calculator.dart`: Pure Dart RANSAC ellipse fitting.
   - `app/lib/domain/services/volumetric_math.dart`: Analytical volume calculations.
   - `app/lib/domain/services/mass_estimator.dart`: Density calibration and quantile mass engine.
   - `app/lib/domain/services/nutrition_calculator.dart`: Atwater validation and Monte-Carlo aggregation.
3. **Automated Testing & Parity**:
   - `app/test/architecture_test.dart`: Automated import scanner.
   - `app/test/fixtures/mass_vectors.json`: Cross-language parity test vectors.
   - `ml/src/ml_pipeline/mass/reference.py`: Python mathematical reference.
   - `ml/tests/test_mass_reference.py`: Pytest parity validation.
4. **CI & Release Guardrails**:
   - `tools/check_manifest.sh`: aapt2 dump permissions release gate.
   - `tools/check_offline.sh`: Manifest node removal and package auditor.
   - `tools/check_licenses.sh`: Permissive license auditor and AGPL scanner.
   - `tools/check_all.py`: Master quality runner.

---

## 4. Recommended AI Agent Workflows

When an AI assistant is assigned a task within a repository following the Health-AI blueprint, it should follow this systematic workflow:

```
Step 1: Check Invariants & Rules
  ├── Read CLAUDE.md and relevant ADRs
  └── Verify offline constraints (zero network calls)

Step 2: Test-First Pure Logic Implementation
  ├── Formulate input/output contract in pure Dart domain layer
  ├── Write comprehensive unit tests in app/test/domain/
  └── Run unit tests to confirm red-to-green progression

Step 3: Dual Parity Verification (if Math / ML related)
  ├── Add deterministic test vector to mass_vectors.json
  ├── Validate in Python (uv run pytest)
  └── Validate in Flutter (flutter test)

Step 4: Layer Discipline & Architecture Verification
  ├── Run architecture_test.dart to verify import rules
  └── Ensure domain does not import Flutter UI

Step 5: Full Quality Gate Execution
  ├── Run tools/check_all.py (formatting, analysis, tests, licenses, offline checks)
  └── Confirm zero errors and zero warnings before completion
```

---

## 5. Skill Limitations & Out-of-Scope Areas

The skill must explicitly document its boundaries:
- **No Cloud Synchronization**: Tasks requesting backend sync, Firebase Auth, cloud backups, or remote APIs are out-of-scope and violate the core offline invariant.
- **No Video / Real-Time Tracking**: Camera capture is restricted to still-photo inference; continuous multi-object tracking in video is out-of-scope.
- **Android Focus**: Platform-specific hardening rules apply primarily to Android (API 26–36). iOS permission mechanics (Info.plist) are secondary and not currently prioritized in v1.
- **Permissive Licensing Only**: Under no circumstances should the agent recommend or import AGPL-licensed libraries (such as Ultralytics YOLO).
