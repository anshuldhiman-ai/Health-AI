# CLAUDE.md — Health AI

> Offline-first, privacy-first SaaS-grade fitness and nutrition app for Android, built with Flutter.
> Every AI feature runs on the user's phone. No account, no server, no data leaves the device.

- Status: v1.7.0+7 (Active development, release 1.7 compiled, 110/110 tests passing). Last reviewed: 2026-10-25.
- App Name: Health AI
- Owner: Anshul Dhiman. Solo developer. Prefer simple, robust, testable solutions over clever ones.
- This file is read at the start of every session. Rules marked **MUST / NEVER** are not negotiable. If a task seems to require breaking one, stop and ask first.

---

## 0. Current Requirements & Further Fix Roadmap

### 0.1 Recently Completed in v1.7 (Verified with 110/110 Tests & Release APK Built)
- **Local Persistence & Data Wipe Resolution**:
  - Authoritative `SharedPreferences` reads/writes with unawaited non-blocking KeyStore background mirror.
  - Test mode memory isolation (`Platform.environment['FLUTTER_TEST']`) preventing cached mock pollution.
  - Automatic purging of corrupted payloads (`FormatException` drops malformed JSON rather than looping).
  - Safe router redirect (`/welcome` -> `/today` for returning users).
- **Dashboard Upgrades (`TodayScreen`)**:
  - Replaced fake dummy metrics with real `caloriesConsumed`, `caloriesTarget`, and `caloriesRemaining`.
  - Restored real macronutrient progress bars: **Protein**, **Carbs**, and **Fat** with live grams, percentages, and progress ratios from `state.macros` navigating to `/macro-breakdown`.
  - Removed "Active Cal" ring and inline micro-trends link (trends live exclusively in Insights).
  - Reduced quick stats to strictly 3 tiles: **Steps**, **Water**, and **Sleep**.
  - Fixed dark mode transition: dynamic canvas and typography tokens replacing hardcoded light-mode hexes.
- **Hydration Tracker (`WaterScreen`)**:
  - Displays real intake volume (removed fake 2.1L fallback).
  - Added interactive **Daily Water Goal** setting bottom sheet (presets: 2.0L, 2.5L, 3.0L, 3.5L, 4.0L + fine tuning).
  - Added **"Remove Last Glass"** (-250ml) and **"Reset Today"** with confirmation dialog.
  - Adaptive light/dark theme styling.
- **Sleep Tracker (`SleepScreen`)**:
  - Standout midnight theme with real logged duration or `'No log'` (removed fake 7h 20m fallback).
  - Added **Daily Sleep Goal** adjustment sheet (7h, 7.5h, 8h, 8.5h, 9h).
  - Added **"Delete Today's Log"** action with confirmation dialog.
- **Activity & Step Goal (`ActivityScreen`)**:
  - Added persistent step goal customizer backed by local storage.
  - Connected hero progress ring to real dynamic step goal.
- **Scanning & Food Diary Deletions**:
  - Balanced food recognition thresholds (`_kFoodTop1Floor = 0.15`, `_kFoodTop3MassFloor = 0.48`) to eliminate false "Not a food item" rejections on real Indian dishes.
  - Added top-3 alternative candidate dish chips in `ScanResultSheet` allowing 1-tap correction if top guess is mistaken (e.g. kulfi vs sweet vs dish).
  - Added individual meal item viewing/deletion and meal clearing options to `DiaryScreen`.

---

### 0.2 What We Need to Fix & Build Further (Next Priority Tasks)

1. **Food Recognition & Accuracy Push (High Priority)**:
   - **Tuning & Class Disambiguation**: Improve classification on visually similar Indian dishes (e.g., Dal Tadka vs Dal Makhani vs Sambar; Kulfi vs Rasmalai vs Ice Cream).
   - **Offline Barcode Scanner**: Integrate offline barcode scanning for packaged Indian groceries (AMUL, Mother Dairy, Britannia, Haldiram's, etc.) mapped to local nutrition database without network access.
   - **Custom Food Creation**: Allow manual recipe/food entry with custom macros and serving sizes for unlisted dishes.

2. **Auth & Biometric Screen Polish (`WelcomeScreen`)**:
   - Replicate `ref_ui_updated.png` Screen 1:
     - Center app logo (green 'H' blending with leaf and scanning frame).
     - Biometric prompt (Face ID / Fingerprint) area using `local_auth`.
     - Premium pill-shaped "Continue with Apple" (Black) and "Continue with Google" (White with subtle shadow) visual buttons.

3. **Meal Diary & Timeline Polish (`DiaryScreen`)**:
   - Replicate `ref_ui_updated.png` Screen 3:
     - Sleek horizontal weekly calendar picker with dot indicators for logged meals.
     - Semi-circle or circular daily goal tracker gauge.
     - Timeline-style vertical list of meals (Breakfast, Lunch, Dinner, Snacks) with food thumbnails and mini horizontal progress bars for protein/carbs/fats.

4. **Interactive Insights & Target Goals (`InsightsScreen`)**:
   - Replicate `ref_ui_updated.png` Screen 4:
     - Curved, gradient-filled `fl_chart` line graphs for calorie & macro trends across toggles: Week / Month / 3M.
     - Custom thick-track goal sliders for Weight Loss, Macros, Water, and Sleep with segmented category switching.

5. **Account & Profile SaaS Upgrades (`ProfileScreen`)**:
   - Replicate `ref_ui_updated.png` Screen 6:
     - Profile picture with Level/Streak badge using `#D4AF37` gold accent.
     - Cupertino-style switches (emerald green when active) for Health Connect / HealthKit.
     - "Premium Subscription" showcase section with soft gold glowing border.

6. **Continuous Quality & Theme Polish**:
   - Ensure all secondary sheets and dialogs strictly follow `#F7F9FB` / `#0F1512` dark mode tokens.
   - Maintain 100% test pass rate across the full Flutter test suite.

---

## 0. Placeholders (decide later, change in ONE place)

The product name is undecided. Never hard-code it.

| Placeholder | Where it lives | Notes |
|---|---|---|
| `{{APP_NAME}}` | `app/lib/app/app_identity.dart` + `app/lib/l10n/*.arb` + Android `strings.xml` | Display name only |
| `{{APPLICATION_ID}}` | `app/android/app/build.gradle.kts` (`applicationId`) | Format `com.<yourname>.<app>`. **Cannot be changed after the first Play release**, so decide before the first upload |
| Brand colours / font | `app/lib/design_system/tokens/` | Section 10. A rebrand must be a one-folder change |
| App icon / splash | `app/assets/brand/` | Generate with `flutter_launcher_icons` and `flutter_native_splash` |

Until the name exists, use the working codename `app` in paths and `{{APP_NAME}}` in docs.

---

## 1. Product definition

**What it is:** A calorie, macro, activity and sleep tracker where the headline feature is **photo-based meal logging using our own on-device model**, tuned first for Indian food (dal, sabzi, roti, rice, paratha, thali, snacks), which Western apps recognise poorly.

**Core principles (in priority order)**
1. **Safety and privacy over features.** Health data is sensitive. If a feature needs a network or an account, it does not ship in v1.
2. **Honest AI.** The model proposes, the user decides. Show confidence, show ranges, allow correction. Never present an estimate as a measurement.
3. **Works everywhere, offline.** Airplane mode is the normal case, not an error state.
4. **Premium feel.** Looks and behaves like a paid SaaS product: fast, calm, consistent, accessible.
5. **Measurable.** Every claim about accuracy, speed or size is backed by a number from a script in this repo.

**Target platform:** Android first (phone, portrait). iOS is a later milestone; keep platform code isolated so it stays possible.

**v1 scope (ships)**
- Onboarding with profile and goal setup, with safety checks.
- Food diary: manual search, quick-add, custom foods, meals, water.
- Photo meal scan (on-device classifier), top-3 suggestions, serving-size picker, user confirmation.
- Barcode scan for packaged food (offline lookup against a bundled subset), if it fits the milestone.
- Steps and activity (Health Connect and/or the hardware step counter).
- Sleep: read from Health Connect or manual entry. Anything we infer is labelled "estimate".
- Rule-based coach: calorie and macro targets, weekly insights. **No LLM in v1.**
- Insights and trends, reminders (local notifications), light/dark theme, English first, Hindi and Punjabi next.
- Data tools: export, import (encrypted backup), delete everything.

**Explicitly out of scope for v1:** accounts, cloud sync, social features, ads, analytics, subscriptions, cloud LLM chat, on-device LLM, multi-item thali segmentation, portion estimation from depth. Some are roadmap items (Section 14).

---

## 2. HARD RULES (read before every task)

| # | Rule |
|---|---|
| R1 | **No network in release builds.** The release merged manifest MUST NOT contain `android.permission.INTERNET` (or `ACCESS_NETWORK_STATE`). The app manifest explicitly removes it with `tools:node="remove"` so a transitive dependency cannot add it. CI fails if it appears. |
| R2 | **No telemetry.** NEVER add analytics, crash-reporting SDKs, ad SDKs, Firebase, remote config, or any package that phones home (this includes `google_fonts` runtime fetching; fonts are bundled assets). |
| R3 | **User data is encrypted at rest** (SQLCipher database, key in Android Keystore). Plain-text health data on disk is a bug. |
| R4 | **AI never writes silently.** Every model output that becomes a diary entry requires an explicit user confirmation. Low-confidence results are flagged, never auto-saved. |
| R5 | **Not a medical device.** No diagnosis, treatment or disease claims in code, copy, store listing or screenshots. Calorie-target safety floors in Section 9.4 are enforced in the domain layer and covered by tests. |
| R6 | **Dependencies need justification.** Before adding any package: check maintenance (last release, open issues), licence (must be permissive: MIT, BSD, Apache-2.0, MPL), size impact, and that it makes no network calls. Record it in `docs/dependencies.md`. Prefer fewer. |
| R7 | **NEVER fabricate numbers.** Accuracy, latency, size and coverage figures come from running the scripts and are pasted into model cards with the commit hash. If you did not run it, say so. |
| R8 | **No secrets exist in this project** (there are no API keys). Signing keystores and `key.properties` are gitignored. NEVER commit them, datasets, or model checkpoints. |
| R9 | **Layer discipline.** `domain/` is pure Dart (no Flutter, no packages except `meta`/`collection`). Widgets contain no business logic. Dependencies point inward only (Section 5). An architecture test enforces this. |
| R10 | **Database migrations are append-only.** NEVER edit a shipped migration. Every schema change gets a new version, a migration test, and a note in `docs/adr/`. |
| R11 | **Every shipped model has a model card** (`model_card.json`) with data sources, licences, metrics, input spec, SHA-256, and training commit. The app verifies the SHA-256 at startup. |
| R12 | **Preprocessing parity.** Python training/export preprocessing and Dart inference preprocessing MUST produce the same tensor (within tolerance). Enforced by a parity test (Section 8.8). This is the most common cause of "great in the notebook, bad on the phone". |
| R13 | **No user-facing string is hard-coded.** Everything goes through `l10n` ARB files. |
| R14 | **Accessibility is a requirement,** not polish: 48dp touch targets, WCAG AA contrast, TalkBack labels, text scaling to 200%, no colour-only meaning. |
| R15 | **Never run heavy work on the UI isolate.** Image decode, resize, inference and DB bulk operations run in background isolates. |
| R16 | **Ask before large changes.** For anything touching the DB schema, permissions, ML model format, navigation structure, or adding a dependency, present a short plan first and wait for approval. |

---

## 3. Technology stack

Versions are intentionally not hard-coded here. Pin them in `pubspec.yaml`, `pubspec.lock`, `.fvmrc`, and `ml/uv.lock`. Run `flutter pub outdated` monthly.

### 3.1 App (Flutter / Dart)

| Concern | Choice | Why / notes |
|---|---|---|
| Framework | **Flutter** stable, pinned with **FVM** | At the time of writing (Oct 2026) stable is the 3.47 line with Dart 3.13. Do not float on `beta`. Upgrade deliberately, one release behind latest is fine |
| Language | **Dart** with null-safety, sealed classes, records, pattern matching | Strict analysis (Section 11) |
| Native glue | **Kotlin** (platform channels, WorkManager, step sensor) | Keep native code small and tested |
| State management | **Riverpod** (`flutter_riverpod`, code-gen via `riverpod_generator`) | Compile-safe DI + state, easy to test with overrides |
| Navigation | **go_router** | Typed routes, deep links, redirect guards (onboarding gate) |
| Models / immutability | **freezed** + **json_serializable** (`build_runner`) | Immutable entities, unions for UI state |
| Local DB | **drift** (SQLite) + **SQLCipher** (`sqlcipher_flutter_libs`) | Typed queries, migrations, reactive streams, encryption at rest. Two databases: `nutrition.db` (read-only, bundled) and `user.db` (encrypted) |
| Secrets/keys | **flutter_secure_storage** (Android Keystore) | Holds the DB encryption key only |
| Health data | **`health`** package → Health Connect (Android), HealthKit later | Read-only, minimum data types. Fallback: native `TYPE_STEP_COUNTER` via platform channel |
| ML runtime | **`flutter_litert`** (LiteRT; maintained successor to `tflite_flutter`) | Before adopting, verify current maintenance, Android ABI coverage and licence on pub.dev. If it stalls, fall back to a thin Kotlin platform channel around the official LiteRT Android runtime |
| Camera / images | `camera`, `image_picker` (system Photo Picker), `image` (Dart, in isolates) | No broad storage permissions |
| Barcode | An **offline** scanner (bundled ML Kit variant or equivalent) | Verify in airplane mode and in the merged manifest that it adds no INTERNET permission |
| Charts | `fl_chart` | Styled through design tokens |
| Notifications | `flutter_local_notifications` + exact-alarm avoidance | Opt-in, inexact scheduling where possible |
| Biometric lock (optional) | `local_auth` | App lock toggle in settings |
| Localisation | `flutter_localizations` + `intl` (ARB) | en, then hi, pa. Bundle Noto fonts for Devanagari/Gurmukhi if shipping those |
| Logging | Small in-house `AppLogger` (no PII, ring buffer in memory, optional user-triggered export) | No third-party logging service |
| Testing | `flutter_test`, `mocktail`, `integration_test`, golden tests | Section 12 |
| Lints | `flutter_lints` strict mode or `very_good_analysis`, plus `riverpod_lint` | Warnings are errors in CI |
| Tooling | FVM, `build_runner`, `flutter_launcher_icons`, `flutter_native_splash` | |

### 3.2 ML / training (Python)

| Concern | Choice |
|---|---|
| Language | **Python** (pin a version in `.python-version`), env/lock with **uv** |
| Core | **PyTorch**, **timm** (model zoo), **torchvision**, **albumentations** or torchvision v2 transforms |
| Config | **Hydra / OmegaConf** (YAML configs, every run reproducible) |
| Tracking | **Weights & Biases** (free personal tier) or **MLflow** / TensorBoard locally |
| Data versioning | **DVC** with a private remote (Google Drive, or a private Hugging Face dataset repo) |
| Data QA | `imagehash`/`cleanvision` (duplicates), **cleanlab** (label errors), **FiftyOne** (inspection) |
| Metrics | `torchmetrics`, `scikit-learn` |
| Export | **LiteRT Torch converter** (`litert-torch`, formerly `ai-edge-torch`) → `.tflite`; **AI Edge Quantizer** for INT8/FP16; fallback ONNX → `onnx2tf`. Validate with `ai-edge-litert` in Python |
| Quality | `ruff`, `pytest`, `pyright`/`mypy`, pre-commit |

### 3.3 Optional backend (NOT part of v1)

v1 has **no backend**. The "backend" of this app is the on-device data layer (Section 6). If a cloud feature is ever added (opt-in LLM coach, encrypted sync), it goes in a separate `backend/` folder as a thin stateless proxy (for example a Cloudflare Worker in TypeScript) and ships behind a separate Android product flavor named `connected`, so the default `offline` flavor keeps R1 intact. Do not create this folder until the roadmap reaches it.

---

## 4. Repository structure

Monorepo. Three top-level areas that never import from each other: `app/` (Flutter), `ml/` (training), `docs/`.

```
{{app}}/
├── CLAUDE.md                      # this file
├── README.md
├── LICENSE
├── .gitignore                     # datasets, checkpoints, keystores, build/ ignored
├── .github/
│   └── workflows/
│       ├── app-ci.yml             # format, analyze, test, goldens, manifest check, size budget
│       ├── ml-ci.yml              # ruff, pytest, export smoke test (tiny model)
│       └── release.yml            # signed .aab on tag (secrets in GitHub, never in repo)
├── docs/
│   ├── architecture.md
│   ├── adr/                       # Architecture Decision Records: 0001-offline-first.md, ...
│   ├── dependencies.md            # every package + licence + reason (R6)
│   ├── privacy/                   # privacy policy source, data-safety answers
│   ├── play-store/                # listing text, screenshots plan, review checklist
│   ├── model-cards/               # one JSON/MD per released model
│   ├── design/                    # tokens, component inventory, screen flows
│   └── safety/                    # nutrition safety rules + references
├── app/                           # ---------- Flutter application ----------
│   ├── pubspec.yaml
│   ├── analysis_options.yaml
│   ├── .fvmrc
│   ├── l10n.yaml
│   ├── android/                   # Kotlin: step sensor, WorkManager, manifest, signing config
│   ├── assets/
│   │   ├── models/                # food_classifier_v1.tflite, labels.json, model_card.json
│   │   ├── nutrition/             # nutrition.db (built by ml/scripts, versioned + checksum)
│   │   ├── fonts/                 # bundled fonts (OFL licences included)
│   │   ├── brand/                 # icon, splash, logo
│   │   └── illustrations/         # empty states (SVG or Lottie, optional)
│   ├── lib/
│   │   ├── main.dart              # entry: runs bootstrap()
│   │   ├── bootstrap.dart         # init order: keystore → DB → model integrity check → runApp
│   │   ├── app/
│   │   │   ├── app.dart           # MaterialApp.router, theme, locale
│   │   │   ├── app_identity.dart  # {{APP_NAME}}, ids (single source)
│   │   │   ├── router/            # go_router config, route names, guards
│   │   │   └── shell/             # bottom-nav shell, scan action
│   │   ├── design_system/         # NO business logic, NO feature imports
│   │   │   ├── tokens/            # colors, typography, spacing, radii, elevation, motion
│   │   │   ├── theme/             # light/dark ThemeData built from tokens
│   │   │   └── components/        # buttons, cards, rings, chips, sheets, skeletons, states
│   │   ├── core/                  # cross-cutting, framework-free where possible
│   │   │   ├── error/             # AppException, Failure, Result<T>
│   │   │   ├── logging/
│   │   │   ├── security/          # key management, model integrity, app lock
│   │   │   ├── time/              # clock abstraction, day-boundary logic, timezone handling
│   │   │   ├── units/             # kg/lb, cm/ft-in, kcal/kJ conversions
│   │   │   └── utils/
│   │   ├── domain/                # PURE DART. The heart of the app
│   │   │   ├── entities/          # UserProfile, Goal, Food, MealLog, MealItem, ActivityDay, SleepSession...
│   │   │   ├── value_objects/     # Grams, Kcal, Macros, Confidence, Serving
│   │   │   ├── repositories/      # abstract interfaces only
│   │   │   ├── services/          # TdeeCalculator, MacroPlanner, SafetyGuard, InsightEngine
│   │   │   └── usecases/          # LogMeal, ConfirmScanResult, ComputeDailyTotals, ...
│   │   ├── data/                  # implements domain interfaces
│   │   │   ├── db/                # drift: tables, DAOs, migrations, SQLCipher setup
│   │   │   ├── nutrition/         # read-only nutrition.db access, search (FTS5)
│   │   │   ├── repositories/      # *_repository_impl.dart
│   │   │   ├── sensors/           # health connect, step counter, platform channels
│   │   │   ├── storage/           # secure storage, photo files (app-private dir)
│   │   │   └── mappers/           # DB row <-> entity
│   │   ├── ml/                    # on-device AI, behind a domain interface
│   │   │   ├── food_recognizer.dart        # abstract + impl
│   │   │   ├── model_registry.dart         # loads model, verifies SHA-256, reads model_card
│   │   │   ├── preprocessing/              # decode, EXIF rotate, resize, normalise (mirrors Python)
│   │   │   ├── postprocessing/             # softmax, temperature, top-k, reject option
│   │   │   └── inference_isolate.dart      # long-lived worker isolate
│   │   ├── features/              # feature-first; each feature has the same shape
│   │   │   ├── onboarding/
│   │   │   ├── today/             # dashboard
│   │   │   ├── diary/             # day log, add food, search, custom foods, meal detail
│   │   │   ├── scan/              # camera, analysing, result sheet, barcode
│   │   │   ├── activity/          # steps, workouts
│   │   │   ├── sleep/
│   │   │   ├── insights/          # trends, weekly review
│   │   │   ├── coach/             # rule-based plan + tips (no LLM in v1)
│   │   │   └── settings/          # goals, units, theme, language, data tools, privacy ledger, about
│   │   │       └── (each feature) presentation/{screens,widgets}/ + application/{controllers,providers}/
│   │   └── l10n/                  # app_en.arb, app_hi.arb, app_pa.arb
│   ├── test/                      # mirrors lib/ ; includes architecture_test.dart
│   ├── integration_test/          # end-to-end flows, airplane-mode checks
│   └── test_goldens/              # golden images for design-system components
├── ml/                            # ---------- Training & export (Python) ----------
│   ├── pyproject.toml / uv.lock / .python-version
│   ├── dvc.yaml / .dvc/           # data pipeline stages
│   ├── DATA_LICENSES.md           # every dataset: source URL, licence, date, allowed use
│   ├── configs/                   # hydra: data/, model/, train/, export/
│   ├── data/                      # GITIGNORED: raw/, interim/, processed/, splits/
│   ├── taxonomy/                  # canonical label set + mapping to nutrition codes (YAML)
│   ├── src/{{ml_pkg}}/
│   │   ├── data/                  # loaders, cleaning, dedupe, split, augmentations
│   │   ├── models/                # timm wrappers, heads, distillation wrapper
│   │   ├── train/                 # train loop, losses, EMA, schedulers
│   │   ├── eval/                  # metrics, calibration, robustness, error analysis
│   │   ├── export/                # to_litert.py, quantize.py, parity_test.py, model_card.py
│   │   └── utils/
│   ├── scripts/                   # build_nutrition_db.py, prepare_dataset.py, make_splits.py
│   ├── notebooks/                 # exploration only; nothing in notebooks is the source of truth
│   ├── reports/                   # eval outputs (confusion matrices, per-class tables) per run
│   └── tests/
└── tools/                         # repo scripts: check_manifest.sh, size_budget.sh, release helper
```

**Naming:** files `snake_case.dart`; classes `PascalCase`; providers `camelCaseProvider`; one public class per file where practical; tests end `_test.dart`.

---

## 5. Architecture and the on-device "backend"

### 5.1 Layers and the dependency rule

```
presentation (screens, widgets)
      │  watches / calls
application  (Riverpod controllers, providers; UI state as freezed unions)
      │  calls
domain       (entities, value objects, services, use cases, repository INTERFACES)   ← pure Dart
      ▲  implemented by
data         (drift DAOs, nutrition DB, sensors, storage, repository impls)
      ▲  uses
ml           (FoodRecognizer impl, behind a domain interface)
```

- Imports only point **inward/downward**. `domain` imports nothing from Flutter, `data`, `ml`, `features`.
- `features/*` may import `domain`, `design_system`, `core`, and `application` of their own feature. Features NEVER import each other's internals. Shared needs go through `domain` or a provider.
- `design_system` imports only `core`. It knows nothing about food, users or models.
- `test/architecture_test.dart` scans `import` lines and fails on violations. Keep it passing. Do not weaken it.

### 5.2 Feature module template

```
features/diary/
├── application/        # diary_controller.dart (AsyncNotifier), diary_providers.dart
├── presentation/
│   ├── screens/        # diary_screen.dart
│   └── widgets/        # meal_section.dart, food_row.dart
└── diary.dart          # public barrel: exports the route + whatever other features may use
```

- Controllers expose `AsyncValue<State>` with explicit **loading / empty / error / data** variants. Every screen renders all four.
- Controllers call use cases, never DAOs.
- Side effects (navigation, snackbars) happen through listeners in the screen, not inside controllers.

### 5.3 Error handling

- Domain/data code returns `Result<T>` (sealed: `Ok` / `Err(Failure)`) for expected failures (permission denied, model missing, invalid input). Exceptions are for bugs.
- `Failure` types are user-meaningful (`PermissionDenied`, `ModelIntegrityFailed`, `StorageFull`, `InvalidInput`). UI maps each to a specific message that says what happened **and what to do next**.
- A top-level guard (`runZonedGuarded` + `FlutterError.onError`) writes to the local ring-buffer logger only. No remote reporting (R2).

### 5.4 Data flow for the headline feature (photo → diary)

```
Camera frame / gallery pick
   → (isolate) decode + EXIF-rotate + resize + normalise        [ml/preprocessing]
   → (isolate) LiteRT inference → logits                         [ml/inference_isolate]
   → softmax(logits / T) → top-k + reject check                  [ml/postprocessing]
   → map label → food codes (nutrition.db)                       [data/nutrition]
   → ResultSheet: top-3 chips, serving picker, nutrient preview  [features/scan]
   → user taps Confirm  (R4)
   → ConfirmScanResult use case → MealLog + MealItem (snapshot nutrients) → user.db
   → prediction_feedback row (chosen label vs predicted; local only)
```

If confidence is below the reject threshold, show "Not sure what this is" with search and top-3, never a confident wrong answer.

---

## 6. Local data layer (the real backend)

### 6.1 Two databases

| DB | Contents | Encrypted | Mutable | Lifecycle |
|---|---|---|---|---|
| `nutrition.db` | Public food composition data, labels→food mapping, serving sizes, barcode subset | No (public data) | Read-only | Shipped as an asset; replaced on app update; version + checksum in `meta` table |
| `user.db` | Everything personal | **Yes (SQLCipher)** | Yes | Key generated on first run (256-bit random), stored via Android Keystore-backed secure storage |

Separating them means a nutrition-data update never touches user data, and only the sensitive DB pays the encryption cost.

### 6.2 `user.db` schema (v1)

All timestamps are stored as **UTC epoch milliseconds plus `tz_offset_min`**, because "what day was this meal" must stay stable when the user travels or DST changes.

| Table | Key columns |
|---|---|
| `user_profile` | id (=1), sex (`male`/`female`/`unspecified`), birth_year, height_cm, activity_level, unit_system, created_at |
| `goal` | id, type (`lose`/`maintain`/`gain`), start_weight_kg, target_weight_kg, weekly_rate_kg, kcal_target, protein_g, carbs_g, fat_g, effective_from |
| `custom_food` | id, name, kcal_100g, protein_100g, carbs_100g, fat_100g, fibre_100g, serving_g, serving_label |
| `meal_log` | id, eaten_at_utc, tz_offset_min, meal_type, note, created_at |
| `meal_item` | id, meal_log_id, food_ref (`source:code`), display_name, grams, **kcal, protein, carbs, fat (snapshot values)**, input_method (`manual`/`scan`/`barcode`/`quick`), model_version, predicted_label, confidence, user_corrected |
| `meal_photo` | id, meal_log_id, rel_path (app-private dir), width, height |
| `activity_day` | local_date, steps, active_minutes, kcal_est, source |
| `workout` | id, started_at_utc, tz_offset_min, duration_s, type, kcal_est, source |
| `sleep_session` | id, start_utc, end_utc, quality_est (nullable), source (`health_connect`/`manual`/`estimate`) |
| `weight_log` | id, measured_at_utc, tz_offset_min, kg |
| `water_log` | id, at_utc, tz_offset_min, ml |
| `prediction_feedback` | id, image_sha256, model_version, top_k_json, chosen_label, created_at |
| `app_setting` | key, value |

**Rules**
- **Snapshot nutrients into `meal_item`.** Later updates to `nutrition.db` must never rewrite history.
- Foreign keys ON; indices on `eaten_at_utc`, `local_date`; FTS5 index for food search lives in `nutrition.db`.
- Migrations: drift `schemaVersion` + stepwise `onUpgrade`; generate schema dumps and run migration tests from every prior version (R10).
- A "Delete all my data" action wipes `user.db`, the photo directory, secure-storage keys and settings in one transaction-like flow, then restarts onboarding. Test it.
- Photos: stored only in the app-private directory, downscaled (max ~1280 px, JPEG). Optional per-meal. NEVER written to shared storage or the gallery.

### 6.3 `nutrition.db` (built by `ml/scripts/build_nutrition_db.py`)

Reproducible build; the output file is versioned and its SHA-256 is recorded in `docs/model-cards/`. Sources, in priority order for Indian foods:
1. **INDB (Indian Nutrient Databank)**: open access, about 1,095 raw foods and 1,014 recipes, derived mainly from ICMR-NIN IFCT 2017. Primary source for Indian dishes.
2. **USDA FoodData Central** (public domain) for global and generic foods.
3. **Open Food Facts** (ODbL) India subset for packaged-product barcodes. If used, comply with ODbL attribution/share-alike and show attribution in the About screen.
4. IFCT 2017 directly only if its terms allow redistribution. Check before bundling; INDB already covers most of it.

Schema essentials: `food(id, source, source_code, name_en, name_hi, name_pa, kcal_100g, protein_100g, carbs_100g, fat_100g, fibre_100g, default_serving_g, is_recipe)`, `serving(food_id, label, grams)` (katori, roti, piece, glass, tbsp, tsp, cup), `label_map(model_label, food_id, weight)`, `barcode(code, food_id)`, `meta(key, value)`.

Data quality rules: per-100g values only; sanity checks (kcal ≈ 4P + 4C + 9F within tolerance, flag outliers); duplicates merged; every row keeps its source and licence tag.

### 6.4 Repositories and use cases

- One repository interface per aggregate in `domain/repositories/` (`MealRepository`, `FoodRepository`, `ProfileRepository`, `ActivityRepository`, `SleepRepository`, `SettingsRepository`).
- Repositories return `Stream`s for reactive UI (diary totals update live) and `Future<Result<T>>` for commands.
- Use cases are small, single-purpose, unit-tested without Flutter.

### 6.5 Domain services (pure Dart, heavily tested)

- `TdeeCalculator`: Mifflin-St Jeor. BMR = 10·kg + 6.25·cm − 5·age + 5 (male) or − 161 (female); for `unspecified`, use the mean of the two constants. TDEE = BMR × activity factor (1.2 / 1.375 / 1.55 / 1.725 / 1.9).
- `MacroPlanner`: protein per kg bodyweight band, fat floor, carbs as remainder. Constants live in one file with citations in `docs/safety/`.
- `SafetyGuard`: Section 9.4. Every goal passes through it; it can block, clamp, or warn.
- `InsightEngine`: deterministic rules (for example "protein under target 4 of last 7 days"). Rule IDs are stable so copy can be localised.
- `DayBoundary`: single place that decides which local day a timestamp belongs to.

### 6.6 Background work

- **WorkManager** (Kotlin) for periodic step snapshots and reminders. Be conservative: Android OEMs aggressively kill background work; design so that opening the app always reconciles state (read cumulative counters, fill gaps).
- No foreground service unless proven necessary (it triggers heavy Play policy review).

---

## 7. Android platform notes (areas to be careful)

### 7.1 Manifest and permissions (least privilege)

Allowed: `CAMERA`, `ACTIVITY_RECOGNITION` (only if using the raw step counter), Health Connect **read** permissions for only the types actually used (steps, sleep, weight, exercise; add others only with justification), `POST_NOTIFICATIONS` (requested contextually, opt-in), `USE_BIOMETRIC` if app lock ships.

Forbidden in v1: INTERNET, location, contacts, broad storage/media access (use the system Photo Picker), microphone, `SCHEDULE_EXACT_ALARM`, foreground-service types, advertising ID.

Required manifest hardening:
```xml
<uses-permission android:name="android.permission.INTERNET" tools:node="remove"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" tools:node="remove"/>
<application
    android:allowBackup="false"
    android:usesCleartextTraffic="false"
    android:dataExtractionRules="@xml/data_extraction_rules"
    android:fullBackupContent="false" ... >
```
`tools/check_manifest.sh` dumps the **final merged** manifest of the release APK/AAB (for example with `aapt2 dump permissions`) and fails on any permission not on the allow-list. Run it in CI and before every upload. Debug/profile builds legitimately contain INTERNET for tooling, so NEVER use a debug build as evidence of offline behaviour.

### 7.2 Play Store platform requirements (verify at release time, they change yearly)

- New apps and updates must target **Android 16 (API 36)** or higher as of the Aug 31, 2026 deadline. Set `compileSdk`/`targetSdk` to 36, `minSdk` 26 (raise only with a reason). Re-check the requirement page before each release.
- Targeting a new API changes behaviour: edge-to-edge is enforced, predictive back must be handled, and health/fitness permission handling changed. Test on an Android 16 emulator and real devices before bumping.
- Upload an **Android App Bundle (.aab)**, not an APK, to Google Play. Use Play App Signing.
- Health apps must complete the Play Console **Health apps declaration** and, for Health Connect, the Health Connect permissions declaration. Declare only the data types you read.
- Provide a privacy policy URL (required for health apps even if you collect nothing) and fill the **Data safety** form truthfully. If the app is genuinely offline, the honest answer is "no data collected, no data shared". Keep it true (R1, R2).
- New personal developer accounts may have to run a closed test with a minimum number of testers for a minimum number of days before production access. Check the current rule in Play Console when you create the account. The registration fee is a one-time cost.

### 7.3 Steps and activity

- **Primary:** read steps from **Health Connect**. It aggregates and de-duplicates sources, and works with any wearable the user already owns. Handle all three states: available, not installed (Android 9 to 13 may need the Health Connect app), unsupported.
- **Fallback:** hardware `TYPE_STEP_COUNTER` via platform channel. Pitfalls to handle explicitly and cover with unit tests: the counter is **cumulative since boot and resets on reboot**; store a baseline and boot-time delta; handle midnight rollover and time-zone/DST changes; permission denial (`ACTIVITY_RECOGNITION`); the sensor missing on some low-end devices.
- Never claim precise "calories burned" from steps. Label as an estimate and keep it out of the calorie budget unless the user opts in.

### 7.4 Sleep

- v1 sources: Health Connect sessions (from a wearable or another app) and manual entry. Anything inferred without a wearable is labelled **"estimate"** and never drives goals.
- Microphone-based sleep sensing is out of scope (privacy cost, low accuracy, policy risk).

### 7.5 Camera, images, memory

- Handle EXIF orientation, front/back camera mirroring, and device rotation. This is a classic source of wrong predictions.
- Downsample while decoding; never decode a 12 MP image at full size on a 3 GB phone. Run decode/resize/inference in the long-lived inference isolate (R15).
- Prefer the XNNPACK CPU path in LiteRT by default. Make the GPU delegate optional behind a runtime capability test with automatic CPU fallback, because GPU support is fragmented across devices. Do not depend on NNAPI (deprecated by Google).

### 7.6 Device matrix (test on real devices, not only emulators)

Minimum: one low-end (3–4 GB RAM, older Android, slow storage), one mid-range, one recent flagship; at least one Samsung and one Xiaomi/Redmi/realme/Oppo-family device for battery-optimisation behaviour. Include a small-screen phone and a large font/display scale. Record results in `docs/device-matrix.md`.

### 7.7 Build hardening

- Release: R8 minify + resource shrinking, Dart `--obfuscate --split-debug-info=build/symbols` (store symbols privately for stack-trace decoding), ABI splits via the app bundle.
- Keystore: upload key stored outside the repo (password manager + offline backup). Losing it is painful; document the recovery path (Play App Signing makes upload-key reset possible).
- Generate and display an **Open-source licences** screen from the dependency list (many licences require attribution).

---

## 8. Machine learning: data, training, export, on-device inference

### 8.1 Problem framing and honesty about accuracy

| Stage | Task | Ships in |
|---|---|---|
| 1 | Single-label classification of the main dish in a photo (about 100–150 classes + `other_food` + `not_food`), top-3 shown to the user | v1 |
| 1.5 | Barcode lookup for packaged food (no ML needed) | v1 or v1.1 |
| 2 | Multi-item detection/segmentation for thalis and mixed plates | v2 |
| 3 | Portion estimation (grams) | research track |

**Reality check, keep in mind in every design decision:** calorie error comes mostly from **portion size and hidden fat** (oil, ghee, cream), not from the class label. A 95% accurate classifier still gives poor calories if the portion is guessed. So v1 pairs the classifier with a **serving picker** (katori, roti count, piece, glass, tbsp) and shows calories as a **range**. Report class accuracy and calorie error separately. Never advertise "X% accurate calorie tracking".

### 8.2 Datasets (verify each licence before use; log in `ml/DATA_LICENSES.md`)

| Dataset | What it is | Use here |
|---|---|---|
| **Khana** (arXiv 2509.06006, khana.omkar.xyz) | About 131K images, 80 Indian-dish labels, 500×500, plus segmentation/retrieval tasks | Main training data for the Indian classifier. Read its licence and the paper's baselines first |
| **Kaggle "Indian Food Classification"** (user `l33tc0d3r`) | Smaller Indian dish image set | Extra data / sanity baseline. Check licence and class overlap with Khana |
| **IndianFoodNet** (about 5.5K images, 30 classes, detection annotations) | Object-detection style annotations | Stage 2 detector experiments |
| **Food-101** (101K images, 101 classes) | General international food classification | Pre-training, hard negatives, `other_food` class. Check its terms |
| **UEC-FOOD256** | 256 categories with bounding boxes, Japan-centric | Optional, detector pre-training |
| **Nutrition5k** (Google Research) | Plates with measured weights/nutrition and depth | Portion/calorie research only. Cafeteria food, not Indian |
| **Non-food images** (for example subsets of COCO / Open Images with no food) | Negatives | Train the `not_food` class and reject option |
| **Self-collected phone photos** | Your own consented photos, real conditions | **The most valuable data. Drives the real-world accuracy.** Section 8.3 |

Licence rules:
- Record for each dataset: URL, licence text, date accessed, what use it permits (research vs commercial), attribution required.
- If a licence forbids commercial use and the app might ever be monetised, either exclude it, or use it only for experiments and never for the shipped model.
- **NEVER scrape Google Images, Instagram, Zomato, Swiggy or recipe sites for training images.** Copyright and terms-of-service problems. Collect your own or use properly licensed datasets.
- Pretrained backbone weights also carry licences (some are non-commercial or research-only). Log the exact weights used in the model card.

### 8.3 Self-collection protocol (the biggest accuracy lever)

- Target as a starting point: 300+ photos per class for the 40 most common classes, 100+ for the rest. Adjust after error analysis shows which classes need more.
- Sources: home cooking, hostel/mess meals, friends and family, restaurants. **Written/recorded consent** from anyone whose meals or surroundings appear; no faces, no personal documents in frame; strip EXIF GPS.
- Diversity on purpose: lighting (daylight, tube light, yellow bulb, night flash), angles (top-down and about 45°), containers (steel thali, katori, ceramic plates, tiffin boxes), partly eaten, mixed plates, different phones.
- Per-image metadata CSV: `class, photographer_id, device, session_id, setting (home/mess/restaurant), date`.
- Labelling: folder-per-class for a first pass, then CVAT or Label Studio (both free, self-hostable) when boxes are needed. Ambiguous images get a second reviewer.
- **Splits are by `photographer_id`/`session_id`, never random by image.** Otherwise near-duplicate photos of the same plate leak into validation and inflate accuracy.
- **Golden test set:** at least 50 real phone photos per class from people NOT in the training pool. Frozen, versioned, stored privately, never used for tuning or early stopping. Release decisions are made on this set only.

### 8.4 Label taxonomy

- `ml/taxonomy/labels.yaml` is the single source of truth: `id`, English/Hindi/Punjabi names, mapped `food_ids` in `nutrition.db`, default serving, group tags.
- Define classes by **nutritional distinguishability, not just names.** Merge visually identical dishes whose nutrition is similar; split dishes that look alike but differ a lot (plain roti vs paratha vs butter naan; dal tadka vs dal makhani; paneer butter masala vs palak paneer).
- Include `other_food` and `not_food`. Changing the label set means a new model version and a new `label_map` version in `nutrition.db` (a test checks they match).

### 8.5 Data pipeline (DVC stages, all reproducible)

`ingest → validate (corrupt/tiny images) → EXIF-normalise → dedupe (perceptual hash across ALL splits) → label audit (cleanlab on a first model's predictions, then manual review of the worst) → group-aware stratified split → freeze (DVC hash)`.

Look at the data with FiftyOne before training. Keep a `reports/data_report.md` per dataset version: class counts, imbalance, duplicates removed, suspected label errors fixed.

### 8.6 Where to train

| Option | Good for | Notes |
|---|---|---|
| **Kaggle Notebooks** | Main free option. Free GPU with a weekly quota (verify current limits) | Upload data as a private Kaggle dataset; save outputs/checkpoints as notebook output |
| **Google Colab (free)** | Quick experiments | Sessions disconnect; checkpoint often to Drive |
| **Lightning AI Studios** | Persistent free-tier workspace with monthly credits (verify) | Good for longer-lived environments |
| **Student credits** | GitHub Student Developer Pack, Google Cloud / Azure / AWS student programmes (check eligibility and current offers) | Use for the big teacher run |
| **Rented GPUs** (RunPod, Vast.ai, Lambda) | Pay by the hour for a few serious runs | Check current prices. A teacher fine-tune on about 130K images typically needs hours, not days |
| **College GPU lab / local NVIDIA GPU (8 GB+ VRAM)** | Ask your department | |

Rules for any environment:
- The same `ml/` code and Hydra configs run everywhere. No environment-specific code paths.
- **Checkpoint every epoch** to persistent storage (Drive, Hugging Face private repo, Kaggle output) and support `--resume`, because free sessions die.
- Log every run (config, git commit, data hash, seed, metrics, time per epoch) to W&B or MLflow.
- Fix seeds, record library versions, commit `uv.lock`.

### 8.7 Training recipe and the accuracy playbook (highest impact first)

1. **Data quality and coverage.** Clean labels, balanced classes, your own phone photos. This beats any architecture change.
2. **Strong pretrained backbone, fine-tuned.** Start from `timm` pretrained weights. Run **day-1 baseline** with a small model to get an end-to-end number fast.
3. **Teacher → student distillation.** Fine-tune a large teacher (examples to evaluate via `timm.list_models`: ConvNeXt-Base/Large, EVA02, ViT-B with DINOv2/SigLIP-style weights; mind weight licences) at higher resolution (320–448 px) with test-time augmentation. Then train the mobile student with soft-label KD (temperature 2–4, mixed with hard-label loss), including **pseudo-labels on unlabeled phone photos**. This is the standard way to get near-teacher accuracy inside an on-device size budget.
4. **Augmentation:** RandomResizedCrop (scale 0.5–1), horizontal flip, TrivialAugment/RandAugment, colour jitter (white balance and brightness matter for kitchen lighting), blur/JPEG compression/noise to mimic phone cameras, random erasing, MixUp + CutMix.
5. **Regularisation:** label smoothing 0.1, stochastic depth, weight decay, **EMA of weights** (export the EMA model).
6. **Class imbalance:** class-balanced sampling or logit-adjusted loss. Track per-class recall, not just accuracy.
7. **Resolution:** train at the deployment size or slightly above; choose the on-device input size from the latency/accuracy table (typically 224–288).
8. **Calibration + reject option:** temperature scaling on a held-out validation set; a confidence threshold plus the `not_food`/`other_food` classes so the app can say "not sure".
9. **Error-analysis loop (data-centric):** after each run, list top confusion pairs and lowest-recall classes, collect more of exactly those photos, retrain. Repeat. Expect more gain here than from tuning hyperparameters.

**Starting hyperparameters (tune, do not trust blindly):** AdamW, weight decay 0.05, lr about 1e-3 for a fresh head and 1e-4 to 3e-4 for the backbone, layer-wise lr decay about 0.75 for ViTs, cosine schedule with 3–5 warmup epochs, 30–60 epochs, bf16/fp16 AMP, batch 64–128, gradient clipping 1.0.

**Student candidates (mobile-friendly):** MobileNetV4 (`mobilenetv4_conv_medium` family), EfficientNet-Lite (`tf_efficientnet_lite0–2`), MobileNetV3-Large. **Day-1 rule:** export a *randomly initialised* copy of every candidate through the converter and run it in the app before investing GPU hours. Some architectures or ops convert poorly or run slowly on phones; discover that first.

### 8.8 Export, quantisation, and the parity test (R12)

1. Wrap the trained EMA model in an export module that **bakes input normalisation into the graph** and outputs **logits** (temperature and softmax applied in Dart, so the calibration constant can change without re-exporting).
2. Convert with the **LiteRT Torch converter** (`litert-torch`) to FP32 `.tflite`. Fallback path: ONNX → `onnx2tf`.
3. Optimise with **AI Edge Quantizer**: try (a) FP16 weights, (b) dynamic INT8, (c) static INT8 with a calibration set of 500–1000 representative training-distribution images. If INT8 loses more than about 1 point of top-1, try quantisation-aware fine-tuning or keep FP16.
4. Produce an **export table** in `reports/`: size, accuracy on the golden test set, p50/p95 latency on each reference device, for FP32 / FP16 / INT8. Pick the model by this table, not by habit.
5. **Python parity test** (`ml/src/*/export/parity_test.py`): the same 200 images through the PyTorch model and the `.tflite` via `ai-edge-litert`. Required: top-1 agreement at least 99% for FP32/FP16 (at least 98% for INT8) and logit differences within tolerance.
6. **Dart parity test** (`app/integration_test/ml_parity_test.dart`): about 20 fixed images with expected logits stored in `app/test/fixtures/parity/`. The Dart preprocessing (decode, EXIF rotate, resize, colour order, dtype) must reproduce the expected output within tolerance on a device/emulator.
7. **Resize-interpolation trap:** Pillow, OpenCV and Dart's `image` package resize differently. Either (a) use the same algorithm in training and in the app (for example bilinear with area/antialias on downscale), or (b) measure the accuracy gap on the validation set when the Dart pipeline is used and require it to be under 0.5 point. Record the choice in an ADR.

### 8.9 Evaluation and release gates

Report on the **golden test set** (real phone photos): top-1, top-5, macro-F1, per-class recall table, top confusion pairs, **ECE** (calibration), reject-option precision/recall, and a **robustness suite** (low light, motion blur, JPEG, rotation, partial crop, occlusion). On device: p50/p95 latency on 3 reference phones, peak memory, model size.

Initial release gates (targets to revise after the first baseline; they are goals, not promises):

| Metric | Gate |
|---|---|
| Top-1 on golden test | at least 85% |
| Top-5 on golden test | at least 95% |
| Worst class recall | at least 60% (otherwise document or merge the class) |
| ECE after calibration | at most 0.05 |
| p95 inference latency, mid-range reference phone | at most 150 ms (model only) |
| Model file size | at most 25 MB |
| Quantised vs FP32 top-1 drop | at most 1 point |
| Python and Dart parity tests | pass |

A model that misses a gate does not ship. The failure goes into the model card under "known limitations".

### 8.10 On-device inference service

- One **long-lived worker isolate** owns the interpreter. UI sends bytes/paths, receives `RecognitionResult(topK, modelVersion, latencyMs, rejected)`.
- Load lazily on the first scan and release after an idle period if memory is tight. Warm up with one dummy inference after loading.
- Fixed input shape, 2–4 CPU threads, XNNPACK default; optional GPU delegate with capability probe and automatic CPU fallback.
- If the model is missing or its SHA-256 does not match, the scan feature degrades to a clear "Photo scan unavailable" state; manual logging keeps working (`ModelIntegrityFailed`).
- Every prediction stores `model_version`, so accuracy can be audited later.

### 8.11 Model packaging and versioning

Files in `app/assets/models/`: `food_classifier_vN.tflite`, `labels.json` (ordered, with hash), `model_card.json`.

`model_card.json` required fields: `model_version`, `created_at`, `git_commit`, `data_version` (DVC hash), `datasets[]` (name, licence, URL), `pretrained_weights` (name, licence), `architecture`, `params`, `input_spec` (size, colour order, normalisation baked), `quantization`, `size_bytes`, `sha256`, `calibration_temperature`, `reject_threshold`, `metrics` (golden test), `latency_ms` per device, `known_limitations`, `intended_use`.

The About screen shows the model version and a one-line honest accuracy statement derived from the card.

### 8.12 Later models (not v1)

- **Activity recognition** from accelerometer: public datasets include UCI HAR, WISDM, PAMAP2 and MotionSense. Small 1D-CNN/GRU, on-device.
- **Phone-only sleep staging:** no good public phone-sensor dataset exists (Sleep-EDF and MESA are polysomnography/actigraphy). Treat as research; v1 reads wearable data or manual entry.
- **Portion estimation:** reference-object scaling and small monocular-depth models, trained/evaluated with Nutrition5k-style signals. Evaluate in grams (MAE/MAPE), not classification accuracy.
- **Multi-item detector:** use a permissively licensed detector (for example MediaPipe Object Detector / EfficientDet-Lite, or Apache-2.0 detector code). **Ultralytics YOLO code is AGPL-3.0**: fine for private experiments, but shipping it inside the app would obligate open-sourcing the app unless a commercial licence is bought. Decide consciously.

---

## 9. Safety, security, privacy, compliance

### 9.1 Threat model (what we defend against)

| Threat | Mitigation |
|---|---|
| Lost or stolen unlocked/rooted phone, other apps reading app storage | SQLCipher DB, key in Android Keystore, photos in app-private dir, optional biometric app lock |
| Data leaking through cloud backup or adb backup | `allowBackup=false`, explicit `dataExtractionRules`; user-driven **encrypted** export instead |
| Accidental data exfiltration by a dependency | R1 (no INTERNET), R2 (no telemetry), merged-manifest check, dependency review (R6) |
| Supply-chain compromise of a package | Lockfiles, pinned versions, changelog review on upgrade, vulnerability scan in CI, no unpinned `git:` dependencies |
| Reverse engineering the APK | No secrets exist to steal. R8 + Dart obfuscation raise the effort; do not rely on it for security |
| Tampered or corrupt model/asset | SHA-256 verification at startup (R11); Play-signed bundle |
| Harmful health guidance | `SafetyGuard`, conservative defaults, clear disclaimers (Section 9.4) |

### 9.2 Data protection controls

- Database encryption key: random 256-bit, generated once, stored through `flutter_secure_storage`. NEVER derive it from a hard-coded string. NEVER log it.
- Optional **app lock** (biometric/device credential through `local_auth`), re-lock on background after a timeout. Optional `FLAG_SECURE` on sensitive screens to block screenshots and the recents preview.
- Logs contain no health values, no food names tied to dates, no file paths with user content. The logger is an in-memory ring buffer; export is manual and user-initiated.
- Clipboard: never copy sensitive data automatically.
- Secure delete: "Delete all my data" removes DB, photos, keys, settings and cached model outputs, then returns to onboarding. Covered by an integration test.

### 9.3 Encrypted export and import (backup without a cloud)

- Export bundle: versioned header + JSON/CSV data + optional photos, compressed, then **encrypted with AES-256-GCM**, key derived from a user passphrase with **Argon2id** (or scrypt/PBKDF2 with high cost if a vetted Argon2id implementation is unavailable).
- Use a vetted library (for example the pure-Dart `cryptography` package, after R6 review). **NEVER invent your own crypto.** Random nonce per file, authenticated header, constant-time comparisons.
- Import validates version, authenticity and schema before touching existing data, and is atomic (all or nothing).
- Test: round-trip, wrong passphrase, tampered file, truncated file, old format version.

### 9.4 Nutrition and health safety rules (`SafetyGuard`, enforced and unit-tested)

These constants live in one file (`domain/services/safety_rules.dart`) with sources and a "last reviewed" date in `docs/safety/`. Review them with a qualified nutrition professional before public release.

- **Age gate in onboarding.** Under 18: no calorie-deficit or weight-loss targets; offer maintenance / healthy-habits mode only.
- **BMI below 18.5:** no weight-loss goal. Show a supportive message and allow tracking only.
- **Calorie floor:** never set a daily target below a configured minimum (commonly cited unsupervised floors are about 1,200 kcal for women and 1,500 kcal for men; confirm against current guidance). The planner clamps and explains.
- **Rate cap:** default weight-change rate at most 0.5 kg per week; hard cap about 1 kg per week or about 1% of body weight per week, whichever is lower.
- **Medical flags in onboarding** ("Does any of this apply: pregnancy or breastfeeding, diabetes, kidney disease, a history of eating disorders, under medical supervision?"): if yes, no automatic deficit plan; tracking only plus a clear "talk to your doctor or a dietitian" message. Do not store the answers beyond what is needed to enforce this.
- **Eating-disorder-aware design:** no "earn it / burn it off" framing, no shaming or red alarms for a single high-calorie meal, no celebration of extreme restriction, streaks optional and gentle, option to hide calorie numbers and weight, option to disable weight tracking. If logged intake is far below the floor for several consecutive days, show a calm check-in message, not a lecture. Do not invent helpline numbers; point to "a doctor or a registered dietitian".
- **Estimates are labelled estimates:** food from photos, steps-to-calories, inferred sleep. Show calorie ranges where the portion is uncertain.
- Onboarding stores a timestamped acknowledgement of the "not medical advice" screen.

### 9.5 Dependency and supply-chain hygiene

- Commit `pubspec.lock` and `ml/uv.lock`. Upgrade in dedicated PRs with changelog review.
- CI runs a vulnerability scan (for example OSV-Scanner against both lockfiles) and `flutter pub outdated` report.
- After ANY dependency change, rebuild the release bundle and re-run `tools/check_manifest.sh`. Native plugins can silently add permissions.
- No `git:` or path dependencies in `main` unless pinned to a commit hash and documented in `docs/dependencies.md`.

### 9.6 Privacy, legal, and store compliance (not legal advice)

- Plain-language **privacy policy** hosted at a stable public URL (GitHub Pages is enough). It must match reality: nothing collected, nothing shared, everything on-device, how to delete data.
- Play **Data safety** form: answer truthfully; revisit after every release (R1, R2).
- India's **Digital Personal Data Protection Act, 2023** and the EU **GDPR** (if you distribute there) matter mainly if you ever collect data. An offline app that collects nothing is the simplest compliance posture. If a cloud feature is added later, redo the privacy design: consent, purpose limitation, deletion, and a legal review.
- Choosing the name: check Google Play for collisions and search the trademark registry (for example IP India) before committing to a name and a `{{APPLICATION_ID}}`.
- Show third-party licence texts (Flutter and packages, fonts, datasets that require attribution, Open Food Facts ODbL notice if used).
- Store listing: no medical claims, no "lose X kg in Y days", screenshots without real personal data, honest description of the AI ("estimates, always confirm").

---

## 10. UI and UX: premium SaaS-grade, production hierarchy

### 10.1 Design intent

Calm, precise and trustworthy: "clinical clarity with warmth". Think of a well-made paid productivity app, not a gamified calorie counter. **One memorable moment: the scan.** The viewfinder, the fast result sheet and the calorie ring settling into its new value are where the polish budget goes. Everything else stays quiet, consistent and fast.

All values below are a **proposal until the brand name exists.** They live in `design_system/tokens/` so a rebrand is a one-folder change.

### 10.2 Colour tokens (named, semantic, light and dark)

| Token | Light | Dark | Role |
|---|---|---|---|
| `canvas` | `#F4F6F3` | `#0D1412` | App background |
| `surface` | `#FFFFFF` | `#141E1B` | Cards, sheets |
| `surfaceRaised` | `#FFFFFF` + hairline | `#1B2723` | Modals, popovers |
| `ink` | `#13201C` | `#E8F0EC` | Primary text |
| `inkMuted` | `#55645E` | `#9DB0A8` | Secondary text |
| `primary` (moss) | `#1E6B57` | `#5CC4A3` | Main actions, selected states |
| `primaryWash` | `#DDEFE8` | `#16322B` | Tinted backgrounds |
| `accent` (turmeric) | `#D99A00` | `#F0B429` | Energy/calorie highlight. Fills and graphics only, not small text |
| `danger` | `#B3392A` | `#F08A7B` | Errors, destructive actions |
| `line` | `#DCE3DF` | `#25332E` | Hairline borders, dividers |

Rules: every text/background pair is checked by a unit test for **WCAG AA** (4.5:1 body, 3:1 large text and graphics). Do not use colour alone to convey state. This palette deliberately avoids the common "cream + terracotta" and "near-black + acid green" looks. No decorative gradients; the only gradient allowed is inside the calorie ring/scan highlight.

### 10.3 Typography

- Bundle **one** UI family as an asset (OFL-licensed; include the licence file). It must support **tabular figures** (verify with `FontFeature.tabularFigures()`), because nutrition numbers must align. Candidates to compare in M0: Manrope, Figtree, Hanken Grotesk, Instrument Sans. Record the decision in an ADR.
- If shipping Hindi/Punjabi, bundle Noto Sans Devanagari and Noto Sans Gurmukhi as fallbacks.
- Scale (sp / line-height): Display 36/42, Title L 28/34, Title M 22/28, Body L 17/26, Body M 15/22, Label 13/18. Weights 400, 500, 600, 700 only. Sentence case everywhere. Body line length under about 70 characters. Layouts must survive 200% text scale.
- Avoid: ALL-CAPS eyebrow labels above headings, accenting a single word in a headline, decorative numbering (use numbers only for real sequences like onboarding steps).

### 10.4 Space, shape, elevation

- 4 pt grid. Spacing tokens: 4, 8, 12, 16, 24, 32, 48. Screen horizontal padding 20.
- **Radii by hierarchy, not one radius for everything:** 8 (inputs, chips), 14 (cards), 24 (bottom sheets, hero surfaces), pill (buttons, segmented controls).
- Depth comes from tonal surfaces and 1 px `line` borders. At most two soft shadow levels, used only for floating elements (bottom sheet, scan button).
- Don't chop every screen into identical cards. Group with spacing and dividers first; use a card only when it is an object the user can act on.

### 10.5 Information architecture and navigation

```
Onboarding (first run only)
  Welcome → What stays on your device → Profile (sex, age, height, weight)
  → Goal → Health check (medical flags, Section 9.4) → Your plan → Permissions (just-in-time)
Main shell: bottom bar  [ Today | Diary | ( Scan ) | Insights | Profile ]
  Today      dashboard: calories ring, macros, steps, water, sleep, next best action
  Diary      date strip → meals → add food (search / scan / barcode / custom / quick add) → meal detail
  Scan       camera → analysing → result sheet (top-3, serving picker, nutrients) → confirm
  Insights   week/month trends, weight, adherence, rule-based tips
  Profile    goals, units, reminders, appearance, language, data (export/import/delete),
             privacy ledger, model info, licences, help, about
```

- The centre **Scan** action is the primary button of the app. Always one tap from anywhere.
- Back behaviour follows platform predictive-back. Deep links only for internal routes.
- Onboarding redirect guard in `go_router`; no way to reach the shell without a valid profile.

### 10.6 Key screen specs

- **Today:** one hero (calorie ring with remaining kcal as the biggest number), macro bars beneath, then a quiet list of steps / water / sleep tiles. Empty day shows one clear call to action: "Log your first meal".
- **Scan result sheet:** top-3 labels as selectable chips with a confidence indicator (words plus shape, not just colour), serving picker with household measures, live calories and macros as a range, "Not this? Search" link, one primary button "Add to lunch". After saving: a toast with "Added to lunch. Undo".
- **Diary:** meals grouped by type, swipe to delete with undo, long-press to duplicate to another day.
- **Insights:** a small number of meaningful charts (calories vs target, protein, weight trend, steps), each with a one-sentence plain-language takeaway from `InsightEngine`.
- **Privacy ledger (trust feature):** a screen that states, and verifies where possible, that the app has no internet permission, lists the permissions it holds and why, and shows what is stored on the device and how big it is. Premium trust signal that costs nothing.
- Every screen defines **loading (skeleton), empty, error, and data** states. Offline is never an error state.

### 10.7 Design-system component inventory (`design_system/components/`)

`AppScaffold`, `AppTopBar`, `AppBottomBar`, `PrimaryButton`, `SecondaryButton`, `TextActionButton`, `IconActionButton`, `AppCard` (+ `FlatSection`), `MetricTile`, `CalorieRing`, `MacroBar`, `MealRow`, `FoodRow`, `ConfidenceChip`, `SegmentedControl`, `NumberStepper`, `ServingPicker`, `AppTextField`, `SearchField`, `AppBottomSheet`, `AppDialog`, `AppSnackbar/Toast` (with Undo), `SkeletonLoader`, `EmptyState`, `ErrorState`, `SectionHeader`, `ListDivider`, `TrendChart` wrapper, `PermissionPrimer`, `ScanViewfinder`.

Each component: tokens only (no raw hex or magic numbers), light and dark golden tests, accessibility semantics, documented in `docs/design/components.md`.

### 10.8 Motion and haptics

- Motion answers an action: sheet open, item added, ring value change, chip selection. No staggered fade-and-slide entrance on every list item, no hover-style effects on every card.
- Durations 120–240 ms, standard easing tokens. Respect system "reduce motion" (swap animations for instant changes).
- Light haptic on confirm and on successful scan; none elsewhere.

### 10.9 Copy and tone

- Plain verbs, sentence case, active voice, specific button labels ("Add to lunch", "Save changes", never "Submit"). The same action keeps the same name across button, toast and history.
- Errors say what happened and what to do next, without apologising or blaming: "Couldn't read this photo. Try again in better light, or search for the dish."
- Empty states invite an action. No filler, no cleverness, no emoji in structural UI text. Every string in ARB (R13).

### 10.10 Accessibility checklist (R14)

48×48 dp minimum targets; AA contrast (tested); `Semantics` labels on every icon button and chart (charts get a text summary); logical focus order; TalkBack pass on every main flow; text scaling to 200% without clipped or overlapping text; no information by colour alone; captions for any audio/video (none planned); respect system font size, bold text, reduce motion, and high contrast where possible.

### 10.11 Adaptive and platform behaviour

Portrait phone is the primary layout. Content is constrained to a maximum width on tablets/foldables and large-screen layouts must not break. Edge-to-edge drawing with correct insets; predictive back supported; dark mode follows the system by default with a manual override; test at 1.0×, 1.3× and 2.0× font scale and small/large display sizes.

### 10.12 UI definition of done

A screen is done when: it uses only design-system components and tokens; all four states render; light and dark goldens exist; TalkBack labels are set; it works at 200% text scale; strings are localised; no logic lives in the widget; and it runs smoothly (no jank) on the low-end reference phone.

---

## 11. Code conventions

### 11.1 Dart / Flutter
- `analysis_options.yaml`: strict lints, `strict-casts`, `strict-inference`, `strict-raw-types`; warnings fail CI. No `// ignore:` without a comment explaining why.
- Immutable by default (`freezed`, `final`, `const`). No mutable global state. No singletons outside Riverpod providers.
- No `print`, no `debugPrint` in committed code. Use `AppLogger`.
- No `BuildContext` across async gaps; no business logic or I/O in `build()`.
- Money-like and unit-bearing values use value objects (`Grams`, `Kcal`), never raw doubles passed around.
- Time: always go through the `Clock` abstraction so tests can control it. Never call `DateTime.now()` in domain or data code.
- Files stay small (aim under about 300 lines). One responsibility per file.
- Public APIs documented with `///` when not obvious. Comments explain **why**, not what.

### 11.2 Kotlin
- Only for things Dart cannot do (step sensor, WorkManager, any LiteRT fallback). Keep it small, null-safe, covered by instrumentation or unit tests where practical.

### 11.3 Python (ML)
- `ruff` format + lint, type hints on public functions, `pytest` for data transforms, metrics, export and parity logic.
- Everything is run from configs (`python -m <pkg>.train +experiment=...`). Notebooks are for exploration only; any result worth keeping is reproduced by a script.
- Every script prints and saves its config, git commit and data hash.

### 11.4 Git
- Trunk-based with short branches. **Conventional Commits** (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`, `ml:`).
- Small commits, one concern each. Never commit generated code if it can be regenerated, except where build tooling requires it (decide once and document).
- `.gitignore` covers: `ml/data/`, checkpoints (`*.pt`, `*.ckpt`), keystores, `key.properties`, `.env`, `build/`, `.dart_tool/`, DVC cache.
- Large files (models, nutrition.db) are committed only as the released artifacts under `app/assets/` (use Git LFS if repo size becomes a problem).
- Decisions that are hard to reverse get an ADR in `docs/adr/` (context, options, decision, consequences).

---

## 12. Testing and quality gates

### 12.1 Test types

| Type | Scope | Tooling |
|---|---|---|
| Unit | domain services (TDEE, macros, SafetyGuard, day boundary, step-counter reboot logic), use cases, mappers | `flutter_test`, `mocktail` |
| Repository/DB | drift queries, FTS search, **migration tests from every old schema version**, encryption actually enabled | in-memory/real SQLCipher in tests |
| Widget | each screen's four states, interactions | `flutter_test` |
| Golden | every design-system component, light + dark, 1.0× and 2.0× text scale | golden tests |
| Integration | onboarding → log meal → today totals; scan flow with a fixture image; delete-all-data; export/import round trip | `integration_test` on emulator + real device |
| Architecture | import rules (Section 5.1) | `test/architecture_test.dart` |
| ML parity | Python vs `.tflite`, and Dart pipeline vs expected logits (Section 8.8) | pytest + integration_test |
| Offline | run key flows in airplane mode; assert release merged manifest has no INTERNET | `tools/check_manifest.sh` + manual checklist |
| Accessibility | `meetsGuideline` checks, contrast unit tests, manual TalkBack pass | `flutter_test`, manual |
| Performance | cold start, scan latency, jank on low-end phone, memory | profile mode, `integration_test` traces |
| Monkey/soak | random input for crashes | `adb shell monkey` on a release-like build |

### 12.2 CI gates (all must pass before merge)

1. `dart format --set-exit-if-changed .`
2. `flutter analyze` with zero issues
3. Unit, widget, golden and architecture tests; coverage thresholds: **domain at least 90%, data at least 80%, overall at least 75%**
4. Release build + `tools/check_manifest.sh` (permission allow-list, no INTERNET)
5. Size budgets: release AAB/APK size within the budget in `tools/size_budget.sh` (set after M2; track the trend)
6. Vulnerability scan on lockfiles
7. ML CI: `ruff`, `pytest`, tiny-model export smoke test

### 12.3 Performance budgets (targets, measured on the low-end reference phone, revise with data)

- Cold start to interactive Today screen: under 2 s.
- Scan: shutter to result sheet under 1.5 s end-to-end, model inference under 150 ms.
- Scrolling diary and charts: no dropped-frame spikes in profile mode.
- No ANRs; no memory growth across 50 consecutive scans.

### 12.4 Release checklist (copy into each release PR)

- [ ] All CI gates green on the release commit
- [ ] Merged manifest permissions reviewed; no INTERNET
- [ ] Model card present, gates met, SHA-256 matches asset
- [ ] Nutrition DB version/checksum recorded
- [ ] Migration tested from all prior versions with real prior-version data
- [ ] Full offline run-through in airplane mode on a real device
- [ ] TalkBack, 200% font scale, dark mode, small screen pass
- [ ] Device matrix results updated
- [ ] SafetyGuard rules re-reviewed; disclaimers present
- [ ] Privacy policy and Data safety form match the build
- [ ] Target API level and Play policies re-checked on the day
- [ ] Obfuscation symbols archived privately; upload keystore backed up
- [ ] Release notes written in plain language

---

## 13. Build and release

- Versioning: `MAJOR.MINOR.PATCH+BUILD` in `pubspec.yaml`. Build number strictly increasing.
- Release build: `fvm flutter build appbundle --release --obfuscate --split-debug-info=build/symbols` (plus the signing config from `key.properties`).
- Distribution path: internal testing → closed testing (friends, classmates, people from your target cuisines) → production with staged rollout. Keep a changelog.
- Flavors: only `offline` exists in v1 (the default). A `connected` flavor is added only if the roadmap reaches cloud features, and it must never change what `offline` ships.
- Crash diagnosis without telemetry: local ring-buffer logs the user can export and send you, plus Play Console's built-in Android vitals (ANRs/crashes reported by the platform). Do not add third-party crash SDKs (R2).

---

## 14. Roadmap and milestones

Order matters; dates are yours. Each milestone has an exit criterion.

| Milestone | Scope | Exit criterion |
|---|---|---|
| **M0 Foundation** | Repo + CI, FVM, lints, architecture test, tokens + design-system skeleton, drift + SQLCipher, manifest check, ADRs. **ML smoke test:** a random-weights model exported with the converter and running inside the app via the inference isolate | CI green; offline manifest check passes; random-weights model runs on a real phone |
| **M1 Offline logging MVP** | Onboarding with SafetyGuard, profile/goals, `nutrition.db` from INDB (+USDA), search, manual and quick logging, Today and Diary screens, settings, encrypted export, delete-all | A friend can use it daily for a week without scan; all four UI states everywhere |
| **M2 ML baseline** | Taxonomy v1, data pipeline, first model on Khana, in-app scan with top-3 + serving picker + confirm, parity tests, model card, golden-test collection started | Baseline numbers on a real phone-photo golden set, reported honestly |
| **M3 Accuracy push** | Own-data collection, cleaning, teacher → student distillation, calibration + reject option, FP16/INT8 selection | Release gates in Section 8.9 met (or limitations documented) |
| **M4 Activity, sleep, insights** | Health Connect + step-counter fallback, sleep reading/manual, InsightEngine, reminders | Reconciliation correct across reboot/midnight/time-zone tests |
| **M5 Hardening** | Device matrix, performance budgets, accessibility audit, security review, privacy policy, store listing, closed test | Release checklist (Section 12.4) fully ticked |
| **M6 v1.0** | Production release, staged rollout | Stable for two weeks; post-release review |

**After v1 (candidates, each needs its own plan and ADR):** Hindi/Punjabi UI, iOS (HealthKit), thali multi-item detection, portion estimation, barcode coverage growth, activity recognition model, opt-in cloud features under a `connected` flavor, optional on-device small language model for a coach (feature-flagged, separate size budget, never default).

**Open decisions (fill in, then delete from this list):**
- [ ] App name, `{{APPLICATION_ID}}`, brand direction
- [ ] First cuisine focus and the v1 class list (start with the 40 most common dishes you actually eat)
- [ ] App licence (MIT/Apache-2.0 vs proprietary) given dataset and model licences
- [ ] UI font family (M0 comparison)
- [ ] Barcode scanner package (offline verified)
- [ ] Reference devices (low / mid / flagship)
- [ ] Whether to include Open Food Facts data (ODbL obligations)

---

## 15. Working agreements for Claude Code

1. **Read first, then plan.** For any task touching more than one file, outline the plan (files, tests, risks) and wait for approval on anything covered by R16.
2. **Tests with the code.** Domain logic gets tests first (TDEE, SafetyGuard, day boundary, step reboot handling, export crypto). A change without tests for new behaviour is not done.
3. **Definition of done for any change:** formatted, analyzer clean, tests pass (paste the real output), no new permission or network capability, docs/ADR updated if a decision changed, strings localised, UI states complete.
4. **Never guess facts that change:** Play Store requirements, target API level, package maintenance status, dataset licences, free-tier quotas, GPU prices, safety guideline numbers. Check the current official source, say what you checked, and flag uncertainty.
5. **Never invent results.** If an experiment was not run, say "not run". Report numbers exactly as the scripts produced them, with the run ID and commit.
6. **ML work:** use configs, not edited constants; save checkpoints and resume support; do not download or add datasets without recording their licence; never commit data or checkpoints; keep the golden test set untouched.
7. **If a request conflicts with a hard rule (R1 to R16),** name the rule, explain the conflict in one or two sentences, and propose a compliant alternative instead of silently complying or silently refusing.
8. **Prefer boring technology.** Choose the simplest solution that meets the requirement; justify any new abstraction or dependency in the PR description.
9. **Keep this file accurate.** When a decision changes, edit CLAUDE.md in the same PR. This file is already long. Do not let it grow further: move detail into `docs/` and reference it with `@docs/<file>.md` imports, keeping the hard rules (Section 2) and structure (Section 4) here.

---

## 16. Command cheat-sheet (adjust as scripts get created)

```bash
# --- Flutter app (run from app/) ---
fvm install && fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter gen-l10n
fvm flutter run --flavor offline            # debug (has INTERNET for tooling only)
fvm dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test --coverage
fvm flutter test integration_test            # on a connected device/emulator
fvm flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
../tools/check_manifest.sh build/app/outputs/bundle/release/app-release.aab
../tools/size_budget.sh

# --- ML (run from ml/) ---
uv sync
dvc pull                                     # fetch versioned data
uv run python scripts/prepare_dataset.py +data=khana
uv run python scripts/make_splits.py +data=khana
uv run python -m <ml_pkg>.train +experiment=baseline_mobilenetv4
uv run python -m <ml_pkg>.train +experiment=teacher_convnext resume=true
uv run python -m <ml_pkg>.train +experiment=student_kd teacher_ckpt=...
uv run python -m <ml_pkg>.eval.run +ckpt=... +split=golden
uv run python -m <ml_pkg>.export.to_litert +ckpt=... +quant=fp16
uv run python -m <ml_pkg>.export.parity_test +tflite=...
uv run python -m <ml_pkg>.export.model_card +tflite=...
uv run python scripts/build_nutrition_db.py
uv run ruff check . && uv run ruff format --check . && uv run pytest
```

---

## 17. References and things to re-verify before relying on them

| Topic | Where to look | Why re-verify |
|---|---|---|
| Play target API level and policies | developer.android.com/google/play/requirements/target-sdk and Play Console policy centre | Changes every year; Health Connect and Health apps declarations have been evolving |
| Flutter / Dart stable | docs.flutter.dev/release | Pin deliberately |
| `flutter_litert` (LiteRT for Flutter) | pub.dev/packages/flutter_litert | Community-maintained successor to `tflite_flutter`; check maintenance before adopting |
| LiteRT, LiteRT Torch converter, AI Edge Quantizer | github.com/google-ai-edge/LiteRT | Tool names and APIs are still moving (`ai-edge-torch` became `litert-torch`) |
| Khana dataset | arxiv.org/abs/2509.06006, khana.omkar.xyz | Check licence and download terms |
| Kaggle Indian Food Classification | kaggle.com/datasets/l33tc0d3r/indian-food-classification | Check licence |
| IndianFoodNet | iieta.org (paper "IndianFoodNet: Detecting Indian Food Items Using Deep Learning") | Check dataset availability and licence |
| INDB (Indian Nutrient Databank) | github.com/lindsayjaacks/Indian-Nutrient-Databank-INDB- ; paper in *Current Developments in Nutrition*, 2024 | Open access; read the repo licence and attribution terms |
| USDA FoodData Central | fdc.nal.usda.gov/download-datasets | Public domain; check bulk download format |
| Open Food Facts | world.openfoodfacts.org/data | ODbL: attribution and share-alike obligations |
| Nutrition5k | github.com/google-research-datasets/nutrition5k | Research use; check licence |
| Food-101, UEC-FOOD256 | official dataset pages | Check terms before any commercial use |
| Free GPU quotas | Kaggle, Colab, Lightning AI pages | Quotas and limits change often |
| Calorie floors / weight-change guidance | national dietary guidance, clinical references (cite in `docs/safety/`) | Safety-critical numbers; review with a nutrition professional |

**End of CLAUDE.md**
