# THIRD_PARTY.md — Third-Party Code & Dependency Audit

> **Locked Decision D-02**: All shipped code, libraries, and runtime dependencies must be under permissive licenses (Apache-2.0, MIT, BSD, CC0, CC-BY with attribution).
> GPL / AGPL / Non-Commercial libraries are strictly prohibited from shipped artifacts.
> Release manifest must have **no `INTERNET` permission** (D-01).

---

## 1. Shipped Flutter Dependencies (`app/pubspec.yaml`)

| Package | Purpose | License | Network Access? | Shipped in Release APK? | Verified Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `flutter_riverpod` | State management / DI | MIT | None | Yes | Verified (v2.6.1) |
| `riverpod_annotation` | Annotation for code generation | MIT | None | Yes | Verified (v2.6.1) |
| `go_router` | Declarative routing & navigation | BSD-3-Clause | None | Yes | Verified (v14.8.1) |
| `freezed_annotation` | Data class annotations | MIT | None | Yes | Verified (v2.4.4) |
| `json_annotation` | JSON serialization annotations | MIT | None | Yes | Verified (v4.9.0) |
| `drift` | Local SQLite database | MIT | None | Yes | Verified (v2.28.2) |
| `sqlcipher_flutter_libs` | Encrypted SQLite native binary | BSD-3-Clause / Apache-2.0 | None | Yes | Verified (v0.6.8) |
| `flutter_secure_storage` | Android Keystore / Keychain storage | BSD-3-Clause | None | Yes | Verified (v9.2.4) |
| `health` | Health Connect sensor bridge | BSD-3-Clause | None (Local Health Connect API) | Yes | Verified (v13.3.1) |
| `flutter_litert` | Google LiteRT runtime (TFLite) | Apache-2.0 | None | Yes | Verified (v0.1.16) |
| `camera` | Camera capture hardware driver | BSD-3-Clause | None | Yes | Verified (v0.11.4) |
| `image_picker` | Local gallery photo picker | Apache-2.0 | None | Yes | Verified |
| `image` | Pure Dart image manipulation | Apache-2.0 | None | Yes | Verified |
| `fl_chart` | Data visualization & charts | MIT | None | Yes | Verified (v0.69.2) |
| `flutter_local_notifications` | Local scheduled reminders | BSD-3-Clause | None | Yes | Verified (v19.5.0) |
| `local_auth` | Local biometric authentication | BSD-3-Clause | None | Yes | Verified (v2.3.0) |
| `shared_preferences` | Key-value disk persistence | BSD-3-Clause | None | Yes | Verified |
| `sensors_plus` | Accelerometer / IMU tilt sensor | BSD-3-Clause | None | Yes | Planned (T5.5) |

### Explicitly Prohibited in Shipped App:
- `http`, `dio`, `fetch`, `socket_io_client` (Banned in release).
- `firebase_core`, `firebase_analytics`, `firebase_crashlytics` (Banned — privacy-first offline).
- `google_fonts` (Banned — requires internet font downloading; fonts are bundled locally in `assets/fonts/`).

---

## 2. ML & Training Dependencies (`ml/pyproject.toml`)

| Library | Role in Pipeline | License | Permitted Use |
| :--- | :--- | :--- | :--- |
| `torch` / `torchvision` | Model training & tensor operations | BSD-3-Clause | Permissive (Training only) |
| `timm` | PyTorch Image Models (MobileNetV4 backbone) | Apache-2.0 | Permissive |
| `segmentation_models_pytorch` | Semantic segmentation decoders (FPN/UNet-lite) | MIT | Permissive |
| `litert-torch` (ai-edge-torch) | PyTorch to LiteRT/TFLite export | Apache-2.0 | Permissive (Google AI Edge) |
| `ai-edge-quantizer` | INT8 model quantization | Apache-2.0 | Permissive (Google AI Edge) |
| `albumentations` | Data augmentations | MIT | Permissive |
| `scikit-learn` | Clustering & evaluation metrics | BSD-3-Clause | Permissive |
| `segment-anything-2` (SAM 2) | Offline teacher segmentation pre-annotator | Apache-2.0 | Permissive (Teacher only, never shipped) |
| `ultralytics` (YOLO) | **BANNED from shipped artifacts (AGPL-3.0)** | AGPL-3.0 | Research/experiments only in `ml/experiments/` |

---

## 3. Auditing Process
- `tools/check_licenses.sh` scans `pubspec.lock` and Python environment against the forbidden license list before every release gate.
