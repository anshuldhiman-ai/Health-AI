# Flutter Engineering: Health-AI

> **Document Type**: Mobile Client Implementation Analysis & Coding Standards  
> **Source Repository**: `https://github.com/anshuldhiman-ai/Health-AI`  
> **Target Audience**: Flutter Engineers & AI Coding Agents  
> **Date**: 2026-11-03  

---

## 1. Flutter Code Conventions & Formatting Standards

The Flutter codebase adheres to strict engineering rules detailed in `CLAUDE.md`:

### General Principles
- **Target Flutter & Dart**: Dart 3.7+ / Flutter 3.29.x pinned via `app/.fvmrc`.
- **Naming Conventions**:
  - File names: Strictly `snake_case.dart` (enforced by `app/test/architecture_test.dart`).
  - Classes and Enums: `PascalCase`.
  - Providers, variables, and methods: `camelCase`.
  - Constants: `kCamelCase` or `_kCamelCase` for private constants (e.g. `kFoodModelAsset`, `_kImageSize`).
- **Formatting**: Standard `dart format` with line-length 80 columns. Zero tolerance for unformatted code in CI (`dart format --set-exit-if-changed`).
- **Linter Rules (`app/analysis_options.yaml`)**: Built on `package:flutter_lints/flutter.yaml` with strict checks:
  - `prefer_const_constructors: true`
  - `prefer_const_declarations: true`
  - `unawaited_futures: true`
  - `avoid_redundant_argument_values: true`
  - `avoid_dynamic_calls: true`
  - `use_build_context_synchronously: true`

---

## 2. State Management Implementation (Riverpod)

The application utilizes `flutter_riverpod` (`^2.6.1`) for reactive dependency injection and state management.

### Architectural Patterns
1. **Global Domain State (`StateNotifier`)**:
   - `DayLog` (`app/lib/app/log_store.dart`) manages meal history across days as a `StateNotifier<Map<int, List<LogEntry>>>`.
   - Exposes clean mutating methods: `add()`, `addAndSave()`, `removeNewest()`, `removeAt()`, `removeMeal()`, and `clearDay()`.
   - Dispatches serialized background writes through an asynchronous chain (`_saveQueue`) to guarantee write order and eliminate file race conditions.
2. **Feature UI State (`AsyncValue` & Custom Unions)**:
   - Feature controllers manage asynchronous actions (e.g. `TodayStateNotifier`, `DiaryStateNotifier`, `ProfileStateNotifier`).
   - UI views consume state via `ref.watch(provider)`.
   - Every async screen explicitly handles all variants: `data`, `loading`, and `error` states.
3. **Provider Invalidation & Dependency Graph**:
   - Updates to `dayLogProvider` automatically invalidate derived providers such as `todayTotalsProvider` and `insightsHistoryProvider`.
   - UI components rebuild selectively down to the leaf widget level.

### Example: Serialized Mutation Pattern (`log_store.dart`)
```dart
void add(LogEntry entry, {int dayOffset = 0}) {
  if (dayOffset < 0 || dayOffset >= maxDays) return;
  _commit({
    ...state,
    dayOffset: [...entriesFor(dayOffset), entry],
  });
}

void _commit(Map<int, List<LogEntry>> next) {
  state = next;
  final payload = jsonEncode({
    'baseDate': _dateOnly(DateTime.now()).toIso8601String(),
    'days': {
      for (final entry in next.entries)
        '${entry.key}': [for (final row in entry.value) row.toJson()],
    },
  });
  _saveQueue = _saveQueue.then((_) async {
    try {
      await AppLocalStorage.writeString(storageKey, payload);
    } catch (e) {
      debugPrint('[DayLog] Save error: $e');
    }
  });
}
```

---

## 3. Navigation and Routing (`go_router`)

Routing is managed declaratively via `go_router` (`^14.6.2`) in `app/lib/app/router.dart`.

### Features & Structure
- **Root Shell Navigation**: Uses `ShellRoute` with an app-level bottom navigation scaffold (`AppShell`) providing persistent navigation tabs across `TodayScreen`, `DiaryScreen`, `InsightsScreen`, and `ProfileScreen`.
- **Full-Screen Feature Routes**:
  - `/scan`: Opens the on-device camera viewfinder (`ScanScreen`).
  - `/activity`: Detailed step counter and hourly charts (`ActivityScreen`).
  - `/water`: Hydration logging interface (`WaterScreen`).
  - `/sleep`: Sleep duration and goal tracking (`SleepScreen`).
  - `/search`: Offline catalog search and manual entry (`SearchFoodScreen`).
  - `/welcome`: First-launch onboarding gate (`WelcomeScreen`).
- **Onboarding Redirect Guard**:
  ```dart
  redirect: (context, state) {
    final hasCompletedOnboarding = ref.read(onboardingCompletedProvider);
    final isGoingToWelcome = state.matchedLocation == '/welcome';
    if (!hasCompletedOnboarding && !isGoingToWelcome) {
      return '/welcome';
    }
    if (hasCompletedOnboarding && isGoingToWelcome) {
      return '/today';
    }
    return null;
  }
  ```

---

## 4. Local Persistence Architecture

Health-AI implements a custom, highly resilient, multi-tiered local persistence layer in `app/lib/data/local_storage.dart`:

```
┌────────────────────────────────────────────────────────┐
│               AppLocalStorage.writeString()            │
└───────────────────────────┬────────────────────────────┘
                            │
         ┌──────────────────┼──────────────────┐
         ▼                  ▼                  ▼
┌──────────────────┐ ┌──────────────┐ ┌──────────────────┐
│  Tier 1: Atomic  │ │   Tier 2:    │ │  Tier 3: Secure  │
│  File IO         │ │ SharedPrefs  │ │  Keystore Mirror │
│  (app_kv_store)  │ │ (Platform)   │ │ (Best-effort)    │
└──────────────────┘ └──────────────┘ └──────────────────┘
```

### 1. Tier 1: Atomic File I/O (`app_kv_store.json`)
- Writes full key-value payload to a temporary file (`app_kv_store.json.tmp`) with `flush: true`.
- Renames `.tmp` over the target file atomically via file system rename.
- Prevents file truncation and corruption if the app process is terminated or killed by Android low-memory killer during a write.
- Fallback paths check both `/data/user/0/com.anshuldhiman.app/files` and `/data/data/com.anshuldhiman.app/files`.

### 2. Tier 2: `SharedPreferences`
- Serves as the authoritative platform-standard cache for rapid key lookups during warm app execution.

### 3. Tier 3: `FlutterSecureStorage` Mirror
- Hardware-backed Android Keystore storage used for sensitive user profiles, body metrics, and secure keys.
- Serialized with strict timeout guards (`timeout(const Duration(seconds: 2))`) to prevent app deadlocks on buggy OEM Keystore implementations.

### Corruption-Tolerant Bootstrap (`loadSavedDayLog()`)
```dart
Future<DayLog> loadSavedDayLog() async {
  try {
    return await _loadSavedDayLog();
  } catch (e) {
    debugPrint('[DayLog] Error in loadSavedDayLog: $e');
    return DayLog(); // Fails open to empty diary; never crashes app startup
  }
}
```

---

## 5. Functional Error Handling (`Result<T>`)

The project completely replaces raw unchecked exception throwing in business logic with a sealed functional Result type located in `app/lib/core/error/result.dart`:

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

enum FailureKind {
  modelMissing,
  modelCorrupt,
  inferenceFailed,
  invalidInput,
  storageUnavailable,
}

class Failure {
  const Failure(this.kind, this.message, {this.cause});
  final FailureKind kind;
  final String message;
  final Object? cause;
}
```

### Benefits
- **Exhaustive Pattern Matching**: Dart 3 switch expressions force callers to handle both `Ok` and `Err` branches at compile time.
- **Graceful UI Degradation**: If model inference fails, the pipeline returns `Err(Failure(FailureKind.inferenceFailed, ...))` which allows the UI to show a clean fallback sheet ("Photo scan unavailable, search food manually") rather than crashing.

---

## 6. Design System & Theming

Located in `app/lib/design_system/`:
- **Tokens (`tokens/tokens.dart`)**:
  - Pure constants for spacing (`Space.s4`, `Space.s8`, `Space.s12`, `Space.s16`, `Space.s24`, `Space.s32`).
  - Border radii (`RadiusToken.r8`, `RadiusToken.r12`, `RadiusToken.r16`, `RadiusToken.r24`, `RadiusToken.full`).
  - Typography matching Plus Jakarta Sans with semantic scales (display, title, body, caption).
- **Theme Support (`theme/app_theme.dart`)**:
  - Full support for Light and Dark modes.
  - High-contrast, accessible text colors adhering to WCAG AA guidelines.
- **Custom Components (`components/`)**:
  - `ProgressRing`: Multi-arc circular progress indicator for calories and macro ratios.
  - `MeterBar`: Linear segmented macro progress bar.
  - `AppCard`: Elevated container with surface tokens and border styling.
  - `StatTile`: Compact numeric overview tile.
  - `AppSheet`: Standardized modal bottom sheet container with drag handle.
