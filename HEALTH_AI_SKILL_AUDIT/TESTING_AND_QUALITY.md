# Testing and Quality Assurance: Health-AI

> **Document Type**: Test Architecture, Quality Gates & CI/CD Pipeline Analysis  
> **Source Repository**: `https://github.com/anshuldhiman-ai/Health-AI`  
> **Target Audience**: QA Engineers, AI Agent Skill Developers & Flutter Developers  
> **Date**: 2026-11-03  

---

## 1. Test Architecture & Coverage Summary

Health-AI maintains an exceptionally rigorous automated test suite spanning pure Dart unit tests, Flutter widget and screen interaction tests, architectural boundary scanners, golden UI snapshot tests, Python pipeline unit tests, and cross-language numerical parity validations.

### Test Metrics Overview (Verified Local Execution)
- **Flutter / Dart Test Suite**: 149 tests passing (`app/test/`) across unit, widget, and golden categories.
- **Python ML Pipeline Test Suite**: 42 tests passing (`ml/tests/`) across ingestion, splitting, export, and reference math.
- **Cross-Language Dual Parity**: 100% numerical agreement ($\le 10^{-6}$ relative error) on volumetric mass estimation.
- **Architectural Rules**: 0 import violations across all layers.

---

## 2. Test Categorization & Directory Structure

```
app/test/
├── architecture_test.dart              # Static analysis of imports enforcing Clean Architecture layers
├── model_contract_test.dart            # Validates LiteRT input/output shapes against labels.json
├── route_smoke_test.dart               # Mounts every GoRouter route to verify no build-time crashes
├── startup_guard_test.dart             # Validates corruption tolerance during app startup
├── ui_screens_test.dart                # Smoke tests mounting main navigation views
├── widget_test.dart                    # End-to-end welcome and onboarding gate test
├── app/
│   ├── log_store_test.dart             # StateNotifier day-offset arithmetic and undo tests
│   └── log_store_persistence_test.dart # Concurrent save queue and write-race tests
├── core/error/result_test.dart         # Sealed Result<T> pattern matching tests
├── data/
│   ├── local_storage_test.dart         # SharedPreferences + SecureStorage mirror tests
│   ├── body_metrics_persistence_test.dart # Profile metrics persistence tests
│   └── sensors/capture_tilt_service_test.dart # IMU accelerometer tilt calculation and fusion tests
├── design_system/components_test.dart  # Custom ProgressRing and MeterBar rendering tests
├── domain/services/
│   ├── plate_geometry_calculator_test.dart # RANSAC ellipse fit, tilt θ, scale s, partial plate rejection
│   ├── volumetric_math_test.dart       # Spherical-cap bowl, mound, and piece volume tests
│   ├── mass_estimator_test.dart        # Density priors, calibration, and P10/P50/P90 quantile tests
│   ├── nutrition_calculator_test.dart  # Atwater ±12% sanity tests, variant oil deltas, Monte-Carlo aggregation
│   ├── safety_rules_test.dart          # Clinical nutrition safety floors and warning thresholds
│   ├── activity_ledger_test.dart       # Step accumulation and midnight boundary logic
│   └── day_boundary_test.dart          # Temporal offset calculations and daylight saving transitions
├── features/
│   ├── activity/activity_screen_test.dart # Hourly step chart rendering tests
│   ├── diary/add_to_diary_snackbar_test.dart # Add/undo toast UI interaction tests
│   ├── goals/goals_controller_test.dart # Calorie and macro target calculation tests
│   ├── insights/insights_state_test.dart # Weekly compliance and scorecard calculation tests
│   ├── scan/
│   │   ├── food_pipeline_test.dart     # TopConfidence ratio, margin, and uncertainty tests
│   │   ├── meal_undo_test.dart         # Diary rollback tests
│   │   └── quick_add_sheet_test.dart   # Manual meal logging sheet tests
│   ├── search/food_search_test.dart    # Offline catalog fuzzy query tests
│   ├── settings/theme_mode_controller_test.dart # Light/dark theme toggle tests
│   ├── sleep/sleep_screen_test.dart    # Sleep log modal sheet tests
│   └── today/today_state_test.dart     # Daily ring and summary calculation tests
├── fixtures/
│   └── mass_vectors.json               # Deterministic cross-language test vectors
└── goldens/ui/                         # Visual pixel-comparison baseline PNGs (20+ screens)
```

---

## 3. Notable Test Implementations & Patterns

### 1. Static Architectural Linter (`app/test/architecture_test.dart`)
Instead of relying on manual code reviews, Health-AI scans Dart import strings using regex during `flutter test`:
- Asserts `app/lib/domain/` contains zero dependencies outside `dart:*`, `meta`, and `collection`.
- Asserts `app/lib/design_system/` contains zero imports from `features/` or `domain/`.
- Asserts feature directories never cross-import each other's internal files.
- Asserts all files follow `snake_case.dart` naming conventions.

### 2. Dual-Language Numerical Parity (`app/test/fixtures/mass_vectors.json`)
To prevent silent divergence between the Python data calibration scripts and Flutter production math:
```json
{
  "vectors": [
    {
      "name": "standard_katori_dal_tadka",
      "mode": "bowl",
      "surface_area_cm2": 50.26548,
      "rim_radius_cm": 5.0,
      "depth_cm": 4.0,
      "density_g_per_ml": 1.04,
      "expected_volume_ml": 113.6272,
      "expected_mass_g": 118.1723
    }
  ]
}
```
- Evaluated by `app/test/domain/services/mass_estimator_test.dart` in Flutter.
- Evaluated by `ml/tests/test_mass_reference.py` in Pytest.
- Both must agree to within $1 \times 10^{-6}$ relative tolerance.

### 3. Startup & Corruption Guard (`app/test/startup_guard_test.dart`)
Simulates corrupt or partially written JSON payloads in `AppLocalStorage`:
```dart
test('loadSavedDayLog survives a corrupt payload', () async {
  await AppLocalStorage.writeString(DayLog.storageKey, 'this is not json');
  final log = await loadSavedDayLog();
  expect(log.hasEntries, isFalse); // Recovers cleanly without uncaught exception
});
```

---

## 4. Build Process & Automated Quality Gates

The repository features automated quality runners that must pass before any commit or release:

### 1. Master Guardrail Runner (`tools/check_all.py`)
Executes the comprehensive 7-step quality gate:
1. `check_offline()`: Verifies `tools:node="remove"` for `INTERNET` and scans `pubspec.yaml` for banned networking packages (`http`, `dio`, `retrofit`, `firebase`).
2. `check_licenses()`: Ensures zero references to banned AGPL libraries (`ultralytics`) and verifies presence of `LICENSES.md` and `THIRD_PARTY.md`.
3. `check_placeholders()`: Scans for `PLACEHOLDER(Txx)` tokens and validates development progress.
4. `dart format`: Enforces zero formatting discrepancies across all Dart files.
5. `flutter analyze`: Enforces zero warnings and zero errors.
6. `flutter test`: Executes all 149 Dart tests.
7. `pytest`: Executes all 42 Python tests.

### 2. Release Merged-Manifest Dump Gate (`tools/check_manifest.sh`)
Executes `aapt2 dump permissions` on the final compiled release bundle (`app-release.aab`):
- Guarantees that third-party native plugins did not silently re-introduce `INTERNET` or `RECORD_AUDIO`.

---

## 5. Identified Gaps & Recommended Improvements

1. **Hardware On-Device Integration Test**:
   - *Current State*: `FoodRecognizer` and `CaptureTiltService` are validated using synthetic tensors and fake sensor streams (`FakeAccelerometerSource`).
   - *Recommendation*: Introduce an automated Android instrumentation test (`integration_test/`) that runs on an actual device or emulator to benchmark real camera latency, peak RAM, and TFLite inference latency.
2. **Golden Test Maintenance for New Multi-Dish Sheets**:
   - Golden tests currently exist for single-dish screens (`scan.png`, `dish_detail.png`).
   - *Recommendation*: Generate visual goldens for the multi-item scan breakdown sheet (`multi_scan_result_sheet.dart`) and the region editing interface.
3. **Automated Coverage Reporting in Local Runner**:
   - `flutter test --coverage` is executed in CI, but `tools/check_all.py` currently runs `flutter test` without computing and printing line coverage percentages.
   - *Recommendation*: Integrate `lcov` parsing in `tools/check_all.py` to enforce a $\ge 90\%$ coverage threshold on `domain/services/`.
