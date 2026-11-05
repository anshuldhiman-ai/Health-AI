# Reusable Engineering Patterns: Health-AI

> **Document Type**: Architecture & Engineering Playbook  
> **Source Repository**: `https://github.com/anshuldhiman-ai/Health-AI`  
> **Target Audience**: AI Agent Skill Developers & Software Architects  
> **Date**: 2026-11-03  

---

## 1. Pattern: 100% Offline Manifest Hardening

### The Problem
When building an offline-first or privacy-critical mobile application, transitive Android dependencies (e.g. camera, scanner, or local storage plugins) often declare `android.permission.INTERNET` or `ACCESS_NETWORK_STATE` in their own `AndroidManifest.xml`. During compilation, the Android Gradle Plugin merges all plugin manifests, silently granting network access to the final APK without the developer's explicit consent.

### The Solution (`app/android/app/src/main/AndroidManifest.xml`)
Use the `tools:node="remove"` directive in the primary application manifest. This instructs the manifest merger to strip the specified permission from the final merged artifact, regardless of which third-party dependency requested it:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <!-- Strips network capabilities even if added by transitive plugins -->
    <uses-permission android:name="android.permission.INTERNET" tools:node="remove" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" tools:node="remove" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" tools:node="remove" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" tools:node="remove" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" tools:node="remove" />

    <application
        android:allowBackup="false"
        android:usesCleartextTraffic="false"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:fullBackupContent="false" ... >
    </application>
</manifest>
```

### Automated Gate Verification (`tools/check_manifest.sh`)
Never trust source files alone. Dump the **final binary manifest** of the release APK/AAB in CI:
```bash
PERMISSIONS=$(aapt2 dump permissions "$RELEASE_AAB" | grep -oE "android\.permission\.[A-Za-z0-9_.]+")
if echo "$PERMISSIONS" | grep -q "android.permission.INTERNET"; then
  echo "FAIL: INTERNET permission present in release build" >&2
  exit 1
fi
```

---

## 2. Pattern: Pure-Dart Domain Layer Isolation

### The Problem
Business logic and physics/geometry formulas frequently become intertwined with Flutter UI widgets (`BuildContext`, `Color`, `Widget`), state management frameworks, or platform plugins. This destroys testability, makes headless unit testing slow, and prevents code reuse.

### The Solution (`app/lib/domain/`)
1. **Zero External Dependencies**: All domain entities and services import only `dart:*`, `package:meta`, and `package:collection`.
2. **Automated Architectural Linter (`app/test/architecture_test.dart`)**:
   A unit test scans every import statement in `lib/` and fails if any domain file imports Flutter or external packages:
   ```dart
   if (area == 'domain') {
     final ok = imported.startsWith('dart:') ||
                imported.startsWith('package:meta') ||
                imported.startsWith('package:collection') ||
                imported.startsWith('domain/');
     if (!ok) {
       violations.add('$rel imports $imported (domain must be pure Dart)');
     }
   }
   ```
3. **Benefit**: Domain unit tests (`volumetric_math_test.dart`, `plate_geometry_calculator_test.dart`) execute in less than 50 milliseconds without initializing the Flutter engine.

---

## 3. Pattern: Functional Sealed `Result<T>` Error Handling

### The Problem
Traditional Dart code relies on `throw Exception()`. Uncaught exceptions crash the app, and callers have no compile-time enforcement to handle failure cases.

### The Solution (`app/lib/core/error/result.dart`)
Define a sealed algebraic data type representing either success (`Ok`) or failure (`Err`):

```dart
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

class Failure {
  const Failure(this.kind, this.message, {this.cause});
  final FailureKind kind;
  final String message;
  final Object? cause;
}
```

### Usage Pattern
```dart
Result<PlateGeometry> result = PlateGeometryCalculator.calculateRoundPlate(...);

// Dart 3 exhaustive pattern matching forces handling both outcomes:
switch (result) {
  case Ok(:final value):
    _renderPlateOverlay(value);
  case Err(:final failure):
    _showFallbackErrorBanner(failure.message);
}
```

---

## 4. Pattern: Ratio & Margin Confidence Handling in Multi-Class ML

### The Problem
Developers often use an arbitrary fixed probability threshold (e.g., `confidence >= 0.70`). In multi-class models (e.g. 239 classes), probability mass spreads across plausible related classes (e.g. Dal Tadka vs. Dal Makhani vs. Sambar). A fixed floor causes correct predictions to be rejected as "uncertain", while assigning false confidence to out-of-domain images.

### The Solution (`TopConfidence` in `food_recognizer.dart`)
Evaluate the **relative margin** between the top two candidates and the **concentration of probability mass** in the top 3:

```dart
class TopConfidence {
  const TopConfidence({
    required this.top1,
    required this.top2,
    required this.ratio,
    required this.top3Mass,
  });

  factory TopConfidence.fromProbabilities(List<double> probs) {
    // Single-pass extraction of top 3 probabilities
    var first = 0.0, second = 0.0, third = 0.0;
    for (final p in probs) {
      if (p > first) {
        third = second; second = first; first = p;
      } else if (p > second) {
        third = second; second = p;
      } else if (p > third) {
        third = p;
      }
    }
    final ratio = second <= 0 ? 1e9 : first / second;
    return TopConfidence(
      top1: first,
      top2: second,
      ratio: ratio,
      top3Mass: first + second + third,
    );
  }

  /// True when top-1 doesn't clearly dominate runner-up
  bool get isUncertain => ratio < 1.35 || top1 < 0.12;

  /// Distinguishes food from non-food (e.g. keyboards, walls)
  bool get isLikelyFood =>
      top1 >= 0.15 && (top3Mass >= 0.48 || ratio >= 2.4);
}
```

---

## 5. Pattern: Multi-Tier Atomic Persistence with Synchronous Flush

### The Problem
`SharedPreferences` in Flutter is asynchronous and holds data in an in-memory cache before flushing to disk asynchronously. If Android terminates the process (e.g. during a low-memory event or when swiped away), writes in flight can be lost. Conversely, SQLite adds significant binary size.

### The Solution (`app/lib/data/local_storage.dart`)
1. **Staged Atomic File Swapping**:
   Write the full serialized state to `app_kv_store.json.tmp`. Flush bytes synchronously (`flush: true`), then execute an atomic filesystem rename over `app_kv_store.json`.
2. **Crash & Corruption Resilience**:
   On startup, if the JSON is malformed, catch the `FormatException` and fallback to an empty state without throwing an uncaught exception (`startup_guard_test.dart`).

```dart
static void _saveDurable() {
  final file = _getFile();
  if (file == null) return;
  try {
    final tmp = File('${file.path}.tmp');
    tmp.writeAsStringSync(jsonEncode(_memCache), flush: true);
    if (tmp.existsSync()) {
      tmp.renameSync(file.path);
    }
  } catch (e) {
    debugPrint('[AppLocalStorage] Durable write error: $e');
  }
}
```

---

## 6. Pattern: Cross-Language Numerical Parity Guard

### The Problem
Machine learning models are trained and calibrated in Python (PyTorch, NumPy, SciPy), but inference math (geometry, spherical-cap volume, density scaling) runs on mobile in Dart. Slight differences in floating point rounding, trigonometry, or coordinate axes cause silent discrepancies in estimated grams and calories.

### The Solution (`app/test/fixtures/mass_vectors.json`)
1. Maintain a shared JSON test fixture containing representative inputs and expected outputs.
2. Implement the math twice:
   - Python reference: `ml/src/ml_pipeline/mass/reference.py`
   - Dart production: `app/lib/domain/services/mass_estimator.dart`
3. Execute automated parity tests in both languages:
   - Dart test: `app/test/domain/services/mass_estimator_test.dart`
   - Pytest: `ml/tests/test_mass_reference.py`
4. Assert numerical agreement to within $1 \times 10^{-6}$ relative tolerance.

---

## 7. Common Mistakes to Avoid

| Anti-Pattern | Why It Breaks Health AI Invariants | Correct Engineering Practice |
| :--- | :--- | :--- |
| **Using HTTP Client Packages** | Pulling in `http`, `dio`, or `firebase` triggers CI build failure (`tools/check_offline.sh`). | Use bundled offline assets (`rootBundle.loadString`) or local database storage. |
| **Hardcoding Single-Point Calories** | Presenting "Dal Tadka = 150 kcal" produces false accuracy; real food varies with oil, portion, and mound depth. | Always compute and present $P_{10} / P_{50} / P_{90}$ percentile ranges (`Range`). |
| **Importing Flutter in Domain** | Importing `package:flutter/material.dart` in `domain/` breaks testability and violates Clean Architecture rules. | Keep `domain/` pure Dart; let presentation mappers convert entities to UI view models. |
| **Using AGPL Libraries** | Bundling Ultralytics YOLO or AGPL dependencies creates severe copyright/licensing blockers for commercial distribution. | Use permissive backbones (`timm`, MobileNetV4, Apache-2.0 / MIT models). |
| **Uncaught JSON Deserialization** | Calling `jsonDecode()` directly in UI code without try/catch crashes the app on corrupted files. | Encapsulate deserialization in domain factory constructors and sanitize inputs defensively. |
