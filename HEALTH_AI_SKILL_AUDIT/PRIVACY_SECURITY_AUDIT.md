# Privacy & Security Audit: Health-AI

> **Document Type**: Comprehensive Security Assessment & Privacy Controls Audit  
> **Source Repository**: `https://github.com/anshuldhiman-ai/Health-AI`  
> **Auditor**: Senior Privacy & Security Engineer  
> **Date**: 2026-11-03  

---

## 1. Security & Privacy Posture Overview

Health-AI operates under one of the strictest privacy models in mobile consumer software: **Zero-Knowledge, Zero-Network, 100% On-Device Architecture**. The application does not collect, transmit, sync, or monetize personal health data.

| Security Property | Architectural Implementation | Verification Status |
| :--- | :--- | :--- |
| **Network Capability** | Stripped from merged release manifest via `tools:node="remove"`. | **Verified Implemented** (`AndroidManifest.xml`, `tools/check_manifest.sh`) |
| **Telemetry & Analytics** | Zero tracking SDKs (no Firebase, Sentry, Mixpanel, Segment, or Datadog). | **Verified Implemented** (Audited in `pubspec.yaml`) |
| **Remote Authentication** | No user account, OAuth, or credentials; app functions immediately upon install. | **Verified Implemented** |
| **Local Data Storage** | Multi-layer local file IO, SharedPreferences, and Android Keystore-backed secure storage. | **Verified Implemented** (`app/lib/data/local_storage.dart`) |
| **Secret & Key Hygiene** | Zero API keys, client secrets, or private tokens committed or required in runtime code. | **Verified Implemented** |
| **Camera & Image Security** | Captured meal images are processed in-memory / temporary cache and never saved to the public MediaStore. | **Verified Implemented** (`food_recognizer.dart`) |

---

## 2. Android Manifest & Permission Hardening (ADR 0008)

The root Android manifest (`app/android/app/src/main/AndroidManifest.xml`) implements defensive permission stripping using Android build tool attributes:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
    
    <!-- R1: Explicit removal of network capabilities from merged manifest -->
    <uses-permission android:name="android.permission.INTERNET" tools:node="remove" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" tools:node="remove" />
    
    <!-- ADR 0008: Explicit removal of invasive transitive plugin permissions -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" tools:node="remove" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" tools:node="remove" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" tools:node="remove" />
    <uses-permission android:name="android.permission.READ_PHONE_STATE" tools:node="remove" />
    <uses-permission android:name="android.permission.VIBRATE" tools:node="remove" />
    <uses-permission android:name="android.permission.USE_FINGERPRINT" tools:node="remove" />

    <!-- Allowed permissions with explicit functional justification -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
    <uses-permission android:name="com.google.android.gms.permission.ACTIVITY_RECOGNITION" />
```

### Application Sandbox Configuration
```xml
<application
    android:allowBackup="false"
    android:usesCleartextTraffic="false"
    android:dataExtractionRules="@xml/data_extraction_rules"
    android:fullBackupContent="false" ... >
```
- `android:allowBackup="false"`: Disables ADB backups and Google Drive automatic backups, preventing physical extraction of the user's health logs via USB debugging.
- `android:usesCleartextTraffic="false"`: Disables cleartext HTTP traffic at the OS level.
- `data_extraction_rules.xml`: Disables cloud and device-to-device data migration.

### Automated CI Gate (`tools/check_manifest.sh`)
In GitHub Actions CI (`.github/workflows/app-ci.yml`), every release build executes `tools/check_manifest.sh` against the compiled `app-release.aab`. It runs `aapt2 dump permissions` on the final merged binary:
- Fails the build immediately if `android.permission.INTERNET` is detected.
- Fails the build if any permission outside the strict allow-list (`CAMERA`, `ACTIVITY_RECOGNITION`, `POST_NOTIFICATIONS`, `USE_BIOMETRIC`) is present.

---

## 3. Local Data Storage & Encryption Audit

### Storage Mechanics (`app/lib/data/local_storage.dart`)
1. **`AppLocalStorage`**:
   - Manages key-value pairs representing the user's food diary (`food.log.v2`), profile metrics (height, weight, age, sex), activity goals, water intake, and sleep records.
   - Saves to internal application sandboxes: `/data/user/0/com.anshuldhiman.app/files/app_kv_store.json`.
   - Uses atomic file swaps with `flush: true` to prevent corruption during OS termination.
2. **`FlutterSecureStorage` (Android Keystore Mirror)**:
   - Sensitive profile metrics are mirrored to `FlutterSecureStorage`, which utilizes Android Keystore-backed AES-GCM encryption.
   - All secure read/write calls are wrapped in 2-second timeout guards to mitigate device-specific Keystore deadlocks.

### Discrepancy Analysis: Drift + SQLCipher vs. Actual Implementation
- **Documented Decision (ADR 0003)**: Proposed two SQLite databases: an unencrypted `nutrition.db` and an encrypted `user.db` via SQLCipher.
- **Actual Verified Codebase**:
  - `drift` and `sqlcipher_flutter_libs` are present in `pubspec.yaml`.
  - However, the actual application does NOT use Drift or SQLCipher. All data is persisted through `AppLocalStorage` (`app_kv_store.json` + `SharedPreferences` + `FlutterSecureStorage`).
- **Security Assessment**: `app_kv_store.json` lives within the application's private sandbox (`/data/user/0/com.anshuldhiman.app/`). On non-rooted Android devices, this is protected by Linux UID/GID sandboxing. However, on rooted devices or via hardware dumps, plain JSON is readable. Full database encryption via SQLCipher remains a documented goal that is not yet implemented.

---

## 4. Sensitive Information Handling & Image Lifecycle

### Camera Meal Images
- **Capture**: Images are captured via `CameraController.takePicture()` as transient `XFile` instances in the app cache directory.
- **Inference**: Image bytes are processed immediately by `FoodRecognizer` in a background isolate.
- **Retention**: Food images are **never** committed to the user's permanent SQLite/JSON log. The app records only semantic metadata: `dishId`, `name`, `kcal`, `protein`, `carbs`, `fat`, `grams`, and `timestamp`.
- **Media Gallery Protection**: The app never requests `READ_MEDIA_IMAGES` or `WRITE_EXTERNAL_STORAGE`. Pictures taken within Health-AI never leak into Google Photos or the public Android Gallery.

---

## 5. Third-Party Dependency & License Audit (D-02)

The project enforces an automated license hygiene policy (`tools/check_licenses.sh`):

### Permissive-Only License Policy
- All shipped code, libraries, and model weights must carry permissive licenses: Apache-2.0, MIT, BSD-3-Clause, or CC-BY.
- **Strict Prohibition on AGPL**: The Ultralytics YOLO codebase is licensed under AGPL-3.0. Under Locked Decision D-02, **Ultralytics YOLO is strictly banned** from shipped code and models.
- `tools/check_licenses.sh` scans `app/lib/` and `ml/src/ml_pipeline/export/` for references to `ultralytics` and fails if detected.
- Every dataset is cataloged with its license in `ml/data/LICENSES.md` (e.g. Khana: CC-BY 4.0; Nutrition5k: Apache-2.0).
- Every dependency is audited in `docs/THIRD_PARTY.md`.

---

## 6. Security Risks, Weaknesses & Recommended Improvements

### Identified Risks
1. **Unencrypted File Storage on Rooted Hardware**:
   - *Risk*: `app_kv_store.json` is stored in plaintext JSON inside the app sandbox.
   - *Impact*: Low for ordinary users, but a user on a rooted Android device could inspect or tamper with their health diary.
   - *Recommendation*: Complete the migration to SQLCipher (`user.db`) as originally specified in ADR 0003, or encrypt the contents of `app_kv_store.json` using an AES-256 key generated in Android Keystore.
2. **Hardcoded Internal Path Fallbacks**:
   - In `app/lib/data/local_storage.dart`, lines 38-41 hardcode `/data/user/0/com.anshuldhiman.app/files` and `/data/data/com.anshuldhiman.app/files`.
   - *Risk*: If the application package name is modified or if Android Work Profiles / Multi-User spaces are active (e.g. user 10), these hardcoded paths fail and require fallback.
   - *Recommendation*: Use `path_provider` (`getApplicationDocumentsDirectory()`) to resolve sandbox paths dynamically.
3. **Dead Native Dependencies**:
   - `sqlcipher_flutter_libs` and `drift` are compiled into the native Android binary, adding ~5–8 MB of unutilized native `.so` libraries to the APK.
   - *Recommendation*: Either implement the SQLCipher database or remove the dependencies from `pubspec.yaml` to reduce binary attack surface and APK footprint.
