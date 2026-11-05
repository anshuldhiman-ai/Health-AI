# Health AI

Health AI is a privacy-first, offline Android wellness app designed for everyday nutrition, activity, and recovery tracking. The product focuses on practical daily health decisions without requiring an account, cloud sync, or internet access.

At its core, Health AI combines:
- on-device food recognition for Indian meals
- daily calorie and macro tracking
- hydration, sleep, and step monitoring
- simple, premium mobile UX tailored for Android users

> Privacy-first by design: every AI feature runs locally on the user's device. No account, no cloud backend, no telemetry, and no data leaves the device.

## Product status

- Current release: v1.7.0+7
- Status: Active development
- App configuration: Android-focused Flutter app
- Quality gate: 110/110 tests passing
- Last reviewed: 2026-10-25

For the complete product definition, non-negotiable engineering rules, and roadmap context, refer to `CLAUDE.md`.

---

## Why Health AI

Health AI is built for people who want a lightweight but capable health companion that stays private and useful offline.

It is designed around three principles:

1. Privacy by default
   - All personal health data remains on-device.
   - No remote account is required.
   - No network dependency in release builds.

2. Real-world nutrition tracking
   - Indian meals are the primary target use case.
   - Food detection is trained for familiar dishes and regional cuisine patterns.
   - Nutrition tracking includes calories, protein, carbs, and fats.

3. Simple, trustworthy user experience
   - The app avoids unnecessary complexity.
   - Each AI output is user-confirmed rather than silently accepted.
   - Designed for local-first reliability and testability.

---

## Core features

### Food recognition and logging
- On-device food recognition powered by a local model for mobile inference
- Optimized for Indian dishes, including common meals and regional varieties
- Real scan results with confidence-based reasoning and user confirmation flow
- Nutrition breakdown for calories, protein, carbohydrates, and fats
- Serving-size selection for realistic meal portions
- Food diary with meal-level tracking and deletion workflows
- Manual food catalog lookup for dishes not detected by camera

### Daily wellness tracking
- Calorie and macro progress monitoring
- Water intake tracking with adjustable daily goals
- Sleep logging with goal controls and deletion support
- Activity and step tracking with local persistent goal settings
- Daily dashboard with actionable progress summaries

### Data privacy and local persistence
- Encrypted local storage
- Local background data handling with safe persistence rules
- Corruption-tolerant data loading and recovery
- No analytics or telemetry SDKs in production builds

### Premium UX
- Clean, polished Android-first interface
- Light and dark theme support
- Responsive dashboards and progress views
- Built with a modern Flutter architecture and design system

---

## Technology stack

### Mobile application
- Flutter + Dart
- Riverpod for state management
- go_router for navigation
- Freezed + json_serializable for immutable models
- Drift/SQLite for local persistence
- flutter_secure_storage and Android Keystore-backed security primitives
- Health Connect integration paths for fitness data inputs
- fl_chart for visual analytics

### AI and inference
- Python ML pipeline for dataset processing and model training
- PyTorch + timm-based training workflow
- LiteRT/TFLite export for on-device inference
- Local inference runtime on the handset
- Model output and nutrition catalog kept aligned to prevent mismatches

### Architecture principles
- Offline-first design
- Clean architecture boundaries
- Testable code paths and local-only execution
- User-controlled AI outputs
- Accessibility-conscious interface design

---

## Repository layout

| Area | Purpose |
| --- | --- |
| `app/` | Flutter Android application |
| `ml/` | Python training, export, and model pipeline |
| `docs/` | Design notes, architecture documentation, and repo guidance |
| `tools/` | Repository maintenance and validation scripts |

The repository is intentionally organized into clear domains so the mobile app, ML pipeline, and supporting tooling remain loosely coupled.

---

## Getting started

### Prerequisites
- Flutter SDK via FVM is recommended
- Android SDK with the required platform support
- Java 17+
- Python 3.12+ for ML tooling

### App setup

```bash
cd app
fvm install
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter gen-l10n
fvm flutter analyze
fvm flutter test
fvm flutter build apk --release
```

### ML pipeline setup

```bash
cd ml
uv sync
uv run ruff check . && uv run pytest
```

### Training the food classifier

The ML pipeline includes the training flow for the food recognition model. The notebook at `ml/notebooks/train_on_colab.ipynb` is the main training driver for the dataset preparation and model fine-tuning workflow.

Current model notes:
- Mobile architecture: `mobilenetv4_conv_medium`
- Focus: Indian food recognition
- Dataset is organized around a curated class set and aligned nutrition catalog
- Model export is designed for on-device deployment

---

## Privacy and product guardrails

Health AI follows a strict privacy and safety model:

- No internet access in release builds
- No telemetry, analytics, or crash-reporting SDKs
- User data stays encrypted at rest
- AI decisions are surfaced for confirmation, not silently accepted
- The app is not intended as a medical device and does not make diagnostic claims

The full set of product constraints and implementation rules is defined in `CLAUDE.md`.

---

## Roadmap and priorities

### Recently completed
- Improved local persistence and data recovery behavior
- Fixed dashboard metrics and real macro progress rendering
- Corrected hydration and sleep tracking flows
- Added daily goal customization and improvements to activity tracking
- Enhanced food recognition feedback and deletion flows in the diary

### Current priorities
- Improve food classification accuracy for visually similar Indian dishes
- Add offline barcode support for packaged groceries
- Support custom foods and manual nutrition entry
- Refine onboarding and biometric UX
- Expand diary, insights, and profile experiences to match product design targets

---

## License status

A license decision is still pending. The project intentionally delays adding a `LICENSE` file until the legal and dataset/model compatibility considerations are finalized.

---

## Final note

Health AI is intended to be a premium, privacy-preserving health companion for Android users who want local-first intelligence without sacrificing usability. It is designed to deliver a polished, trustworthy experience while keeping sensitive health data under the user's control.

*Built for privacy, practicality, and long-term everyday health tracking.*
