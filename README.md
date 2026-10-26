# 🍃 Health AI

**Health AI** is a premium, offline-first health and wellness application for Android. Its flagship feature is an intelligent, photo-based meal logger powered by a custom on-device ML classifier specifically fine-tuned for recognizing and analyzing Indian cuisine.

> **Privacy-First Design:** Every AI feature runs on the user's phone. No account, no server, no data leaves the device. Your health data stays yours.

**Status:** Alpha (M1 — MVP UI/UX complete, M2/M3 in progress — bug fixes and data persistence implemented). See `CLAUDE.md` for the full product definition, hard rules (R1–R16) and the milestone plan.

---

## ✨ Key Features

### 📸 Smart Meal Scanning & Logging
- **On-Device AI Classifier:** Point your camera at your meal for instant recognition. The model is specifically trained on complex Indian foods, including *Dal, Sabzi, Roti, Rice, Paratha, Thalis, and various snacks*.
- **Real-time Detection:** Shows actual scan results with confidence scores only after real image analysis (no hardcoded predictions).
- **Instant Nutritional Breakdown:** Once the food is categorized, the app provides accurate macronutrient estimates (Protein, Carbs, Fat, Fiber) and total calories based on a comprehensive Indian food database.
- **Portion Estimation:** Select serving sizes from realistic Indian meal portions (Katori, Bowl, Plate, Piece) to log accurate calorie counts.
- **Manual Food Search:** Search and log from a curated catalog of 80+ Indian dishes with complete nutrition data (expanding to 200+).
- **Quick Add (Planned):** Barcode/QR scanner for packaged foods (coming soon).

### 🌙 Sleep & Recovery Tracking
- **Smart Sleep Logging:** Manual entry with bedtime/wake time inputs.
- **Snooze Tracking:** Track snooze button usage and correlate with sleep quality.
- **Sleep Quality Insights:** Correlate sleep patterns with daily energy levels and nutrition intake.
- **Health Connect Integration:** Planned for automatic sleep data import.

### 📊 Holistic Wellness Dashboard
- **Step & Activity Counter:** Track daily steps, total distance, and active minutes with visual daily streaks (Health Connect integration).
- **Hydration Tracker:** Quick and easy logging for daily water intake goals with visual glass grid.
- **Macro & Calorie Diary:** A beautifully designed timeline view of your Breakfast, Lunch, Dinner, and Snacks.
- **Weekly Insights:** Deep-dive analytics into your macro-nutrient balance and calorie trends over 7, 30, or 90 days.
- **Goal Planning:** Choose from weight loss, maintenance, or muscle gain goals with automatic calorie and macro targets.
- **Body Metrics & BMI:** Track height, weight, and activity level with automatic BMI calculation and color-coded health indicators (Green = healthy, Yellow = edge, Red = under/over).

### 🎨 Premium UI / UX Design
- **Elegant Light/Dark Theme:** A luxurious interface utilizing a bespoke color palette (Emerald, Deep Sage, Gold, and Obsidian).
- **Glassmorphic Elements:** Smooth, translucent UI cards and fluid animations for a highly polished, SaaS-grade user experience.
- **Localisation Support:** Full support for English, Hindi, and Punjabi with more languages planned.
- **Accessibility First:** WCAG AA contrast, 48dp touch targets, TalkBack labels, and text scaling to 200%.

---

## 🛠 Tech Stack

### Frontend (Flutter / Dart)
- **Framework:** Flutter 3.47+ (stable, pinned with FVM)
- **State Management:** Riverpod with code generation
- **Navigation:** go_router with typed routes and deep linking
- **Models:** freezed + json_serializable for immutable entities
- **Database:** drift (SQLite) + SQLCipher for encrypted storage
- **Local Storage:** flutter_secure_storage (Android Keystore)
- **Health Data:** `health` package → Health Connect (Android)
- **Charts:** fl_chart styled through design tokens
- **Notifications:** flutter_local_notifications
- **Localisation:** flutter_localizations + intl (ARB format)

### Machine Learning
- **Training:** PyTorch + timm (MobileNetV4, EfficientNet-Lite)
- **Config:** Hydra / OmegaConf (YAML configs)
- **Export:** LiteRT Torch converter → TFLite
- **Runtime:** flutter_litert (on-device inference)
- **Dataset:** Khana 80-class Indian food dataset (currently 80 dishes, expanding to 200+)

### Architecture
- **Clean Architecture:** Domain-driven design with strict layer discipline
- **Offline-Only:** No network access in release builds (enforced by manifest checks)
- **Privacy-First:** All data encrypted at rest, no telemetry, no analytics
- **Testable:** Comprehensive unit, widget, and integration tests

---

## 📁 Repository Layout

| Area | Contents |
|---|---|
| `app/` | Flutter application (offline-only Android app) |
| `ml/` | Python training/export pipeline (PyTorch → LiteRT) |
| `docs/` | ADRs, dependencies, safety rules, design tokens, store assets |
| `tools/` | Repo scripts (manifest check, size budget) |

The three top-level areas never import from each other.

---

## 🚀 Getting Started

### Prerequisites
- [FVM](https://fvm.app) and a Flutter SDK it can install
- Android SDK with the `android-36` platform
- Java 17+
- Python 3.12+ (for ML pipeline)

### App Setup

```bash
cd app
fvm install            # reads .fvmrc
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs   # freezed/drift/riverpod codegen
fvm flutter gen-l10n
fvm flutter analyze
fvm flutter test
fvm flutter build apk --release
```

### ML Pipeline Setup

```bash
cd ml
uv sync
uv run ruff check . && uv run pytest
```

### Training the Food Classifier

`ml/notebooks/train_on_colab.ipynb` is the end-to-end training driver:
downloads the Khana dataset, builds the validated/deduped manifest,
makes splits, and fine-tunes `mobilenetv4_conv_medium` with AMP + EMA,
checkpointing every epoch into Google Drive. Open the notebook in
Google Colab with a T4 GPU runtime and run the cells top-to-bottom.

**Current Status:**
- Student: `mobilenetv4_conv_medium` (timm, ImageNet pretrain), **80 classes** (Khana), image size 224
- **Smoke checkpoint (2 epochs, code `bdee652`):** test top-1 **0.8098**, top-5 **0.9618** (19,424 images, seed 42)
- **Expanded model (239 classes, 4 epochs):** Training in progress
- Export: `scripts/export_tflite.py` → `baseline.tflite` + `labels.json`
- Dish catalog: 80+ Indian dishes with complete nutrition data, expanding to 200+

---

## 🛡️ Hard Rules

These rules shape every decision in the project:

- **R1** — No network in release builds; the merged release manifest must not contain `INTERNET`
- **R2** — No telemetry, no analytics, no crash-reporting SDKs
- **R3** — User data encrypted at rest (SQLCipher, key in Android Keystore)
- **R4** — AI never writes silently; every model output needs user confirmation
- **R5** — Not a medical device; no diagnosis, treatment or disease claims
- **R12** — Python and Dart preprocessing must produce identical tensors (parity tests)
- **R13** — No user-facing string is hard-coded; everything goes through l10n ARB files
- **R14** — Accessibility is a requirement, not polish
- **R15** — Never run heavy work on the UI isolate

The full list is in `CLAUDE.md` Section 2.

---

## 📊 Milestone Progress

- ✅ **M0 — Foundation:** Project setup, architecture, build pipeline
- ✅ **M1 — MVP UI/UX:** Complete design system, all major screens, localisation, nutrition catalog
- 🔄 **M2 — ML Integration:** Model training (239-class model in progress), export, on-device inference UI improvements
- 🔄 **M3 — Data Layer:** Encrypted database, preferences, persistence (SharedPreferences implemented, SQLCipher planned)
- ⏳ **M4 — Testing & Polish:** Comprehensive tests, accessibility audits, performance optimization
- ⏳ **M5 — v1 Release:** Play Store submission, model cards, documentation

**Recent Fixes (Oct 2026):**
- Fixed data persistence for food diary entries
- Fixed water section showing hardcoded empty values
- Fixed camera showing hardcoded predictions without scan
- Improved scan UI to show real detection results only

---

## 🔮 Future Scope

- Integration with Apple Health, Google Fit, and Garmin
- Automated grocery list generation based on weekly meal planning
- Expanded dish catalog (200+ Indian dishes across all regional cuisines)
- Deeper insights correlating sleep patterns with late-night food intake
- Healthy substitute suggestions based on scanned meals
- Voice logging for meals and activities
- Meal planning and recipe suggestions

---

## 📄 Licence

To be decided — choice interacts with dataset and model licences. Options under consideration:
- MIT (permissive, allows commercial use)
- Apache-2.0 (permissive with patent protection)
- Proprietary (closed-source)

Do not add a `LICENSE` file until decided; the choice interacts with dataset and model licences (Section 14 of CLAUDE.md).

---

*Designed with a focus on premium aesthetics, privacy, and frictionless health tracking.*
