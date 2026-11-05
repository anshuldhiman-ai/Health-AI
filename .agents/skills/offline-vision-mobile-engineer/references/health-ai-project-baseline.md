# Health-AI project baseline (snapshot: 2026-11-03)

> **Verification warning (2026-11-03):** This is a time-bound summary of the submitted audit snapshot, not a current-state guarantee. Repository facts can change quickly. Before using any item, inspect the target checkout's source, call sites, tests, assets, and CI. Do not copy these conclusions into another project or cite them as current without re-verification. No private source excerpts, model weights, datasets, credentials, or user data belong in this reference.

This reference summarizes the submitted `HEALTH_AI_SKILL_AUDIT.zip` and the curated source files inside it. It is a dated snapshot, not a claim that the live repository has not changed.

## Product and stack observed

- Android-first Flutter wellness/nutrition tracking application.
- FVM pin in `app/.fvmrc`: Flutter `3.47.0`; `app/pubspec.yaml` requires Dart `^3.13.0`.
- Flutter dependencies include Riverpod, go_router, LiteRT, camera/image tooling, SharedPreferences, flutter_secure_storage, Drift, SQLCipher, Health, sensors, and local notifications.
- Python ML source uses PyTorch/timm-oriented classifier training and LiteRT export utilities.
- `app/lib/domain/services/` contains pure-Dart geometry, volume, mass, nutrition, activity, and safety logic.
- Android main manifest removes INTERNET and ACCESS_NETWORK_STATE through manifest-merger directives.

## Verified implementation patterns in the supplied files

- Riverpod application/feature state and go_router navigation.
- A single-dish food-recognition path in `app/lib/features/scan/application/food_recognizer.dart`.
- LiteRT interpreter contract checks for `[1, 224, 224, 3]` input and output dimension matching `labels.json`.
- Dart image preprocessing: EXIF orientation bake, short-side resize to 255, center crop to 224, RGB float32 NHWC values in 0..1.
- Serialized recognizer calls and an `IsolateInterpreter`; preprocessing currently uses `Isolate.run`.
- Flip test-time augmentation is triggered by a top-1/top-2 ratio threshold; uncertain and non-food decisions are explicit.
- Pure-Dart RANSAC ellipse/homography geometry and bowl, mound, and piece volume/mass calculations.
- Nutrition calculations include per-100g scaling, an Atwater check, variant adjustments, and Monte-Carlo meal aggregation.
- Shared numerical fixture `app/test/fixtures/mass_vectors.json` is consumed by both Dart and Python tests.
- Local persistence writes a JSON file with a temporary-file/flush/rename approach, uses SharedPreferences, and attempts a best-effort `flutter_secure_storage` mirror.
- The code has manual/search fallback paths when model inference is unavailable or uncertain.

## Important current-state limitations

The project documentation itself marks several capabilities as incomplete. Do not present these as implemented:

- Multi-dish segmentation, embedding/prototype recognition, mask postprocessing, and the full multi-food pipeline are roadmap items; `docs/PROGRESS.md` shows Phases 3, 4, and 6 gates pending.
- A long-lived worker owning multiple interpreters is planned; the current classifier path is a single recognizer with serialized inference and `IsolateInterpreter`.
- The current image preprocessing decodes with the Dart `image` package. The roadmap proposes native downscaling/transferable buffers to reduce large-image memory costs.
- The `.tflite` model binary and training checkpoints are not in the submitted share package. `food_recognizer.dart` reports a missing model as unavailable; this package cannot independently validate real model accuracy or inference.
- The `ml/` tree contains a classifier-oriented pipeline. Planned segmentation and embedding training/evaluation workflows are not present in the supplied source.
- The weighed-plate CSV contains only a tiny sample in this package; `docs/PROGRESS.md` marks the data foundation gate pending.
- `T5.5` sensor adapter is partial; the progress log says the `sensors_plus` adapter is not wired.
- Personal calibration, backup/restore, full device benchmarks, and final release gate are pending.
- `health` is declared in `pubspec.yaml`, but no Health Connect API use was found in the supplied `app/lib` Dart files.

## Discrepancies and verification warnings

1. **Database plan vs implementation:** Drift and SQLCipher are declared dependencies and described in ADR 0003, but the supplied production data path uses `AppLocalStorage` with JSON, SharedPreferences, and a best-effort secure-storage mirror. Do not claim SQLCipher is protecting current user records.
2. **Plaintext local file:** `app_kv_store.json` is written as ordinary JSON in the app sandbox. The secure-storage mirror does not make the JSON file encrypted. The code also uses hard-coded Android sandbox path fallbacks.
3. **Safety review:** `SafetyRules.lastReviewed` says `NOT YET REVIEWED`; `docs/safety/nutrition_safety.md` is marked DRAFT. Thresholds require qualified professional review before public release.
4. **Model reject thresholds:** `food_recognizer.dart` explicitly labels non-food thresholds provisional and unvalidated on real non-food phone images. Unit tests validate logic, not calibration quality.
5. **Mass-prior placeholders:** `mass_estimator.dart` marks role height/density priors as `PLACEHOLDER(T8.2)`. The roadmap says calibration on weighed plates remains pending.
6. **Parity defaults:** Dart mass estimator defaults and Python reference quantile defaults differ. The shared fixture supplies explicit q-values, so the fixture tests do not prove the defaults are aligned. Test defaults explicitly or centralize them.
7. **Smoke-test wiring:** `ml/src/ml_pipeline/export/smoke_test.py` contains a `NotImplementedError` behind `SMOKE_TEST=true`. The ML workflow invokes the module with `python -m`, but the module has no `__main__` entry point calling the function. The file name also does not match default pytest `test_*.py` discovery. Treat the export smoke test as not operational until fixed and observed in CI.
8. **AAB permission script:** `tools/check_manifest.sh` attempts to extract root-level `AndroidManifest.xml` from an AAB. Standard app bundles store the base manifest at `base/manifest/AndroidManifest.xml`; validate and fix the extraction/inspection path before relying on this release gate.
9. **Offline check scope:** `tools/check_all.py` checks the source manifest and a short list of direct pubspec dependencies; it does not itself prove absence of all transitive/runtime network behavior. Final artifact inspection is required.
10. **Test-count mismatch:** the audit report claims 149 Flutter and 42 Python tests; `docs/PROGRESS.md` records 115 Flutter and 21 Python tests; `CLAUDE.md` has an older 110/110 note. No raw test logs were included. Do not publish any of these counts as current verified results without rerunning.
11. **SDK documentation drift:** the audit summary states Flutter 3.29/Dart 3.7, but the supplied `.fvmrc` pins Flutter 3.47.0 and `pubspec.yaml` requires Dart `^3.13.0`. Update stale documentation.
12. **Dataset/model provenance:** the license registry marks some datasets as non-commercial or pending confirmation. The model README mentions a Kaggle training corpus not clearly identified in the supplied license registry. Resolve provenance and model-training rights before shipping or distributing weights.

## Safe reusable lessons

- Keep a known-good single-model fallback while a more ambitious multi-model pipeline is developed.
- Make model/label contracts fail fast and show a manual fallback.
- Keep geometry and nutrition math in a testable domain layer.
- Use shared test vectors for cross-language calculations, but also test defaults and edge cases.
- Treat placeholders as visible debt and block release while safety-critical or accuracy-critical placeholders remain.
- Validate privacy claims against the built artifact and actual storage implementation.
- Keep project-specific thresholds, class labels, catalogs, and data out of a general skill unless explicitly licensed and intended for redistribution.
