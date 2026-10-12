# ADR 0008: Android permissions — least privilege, with a merged-manifest gate

## Context

A health app with camera, health-data and notification access is a
high-trust surface. Play policy and user trust both demand we
request the minimum, and prove the release build never gained a
network permission from a transitive dependency.

## Decision

**Allowed in v1** (each justified):

- `CAMERA` — photo meal scan (the headline feature)
- `ACTIVITY_RECOGNITION` — only if using the raw `TYPE_STEP_COUNTER`
  fallback
- Health Connect **read** permissions for exactly: steps, sleep,
  weight, exercise
- `POST_NOTIFICATIONS` — requested contextually, opt-in
- `USE_BIOMETRIC` — if the optional app lock ships

**Forbidden in v1:** INTERNET, location, contacts, broad
storage/media access (use the system Photo Picker), microphone,
`SCHEDULE_EXACT_ALARM`, foreground-service types, advertising ID.

**Manifest hardening:**

```xml
<uses-permission android:name="android.permission.INTERNET" tools:node="remove"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" tools:node="remove"/>
<application
    android:allowBackup="false"
    android:usesCleartextTraffic="false"
    android:dataExtractionRules="@xml/data_extraction_rules"
    android:fullBackupContent="false" ... >
```

**Gate:** `tools/check_manifest.sh` dumps the **final merged**
manifest of the release APK/AAB (e.g. `aapt2 dump permissions`)
and fails on any permission not on the allow-list. Runs in CI and
before every upload. After ANY dependency change, the release
bundle is rebuilt and the script re-run (Section 9.5) — native
plugins can silently add permissions.

Target API: Android 16 (API 36) per the Aug 31, 2026 Play
requirement; `minSdk` 26. Re-check the requirement page before
each release (Section 17) — these change yearly.

## Consequences

- Debug/profile builds legitimately contain INTERNET for tooling;
  they are never evidence of offline behaviour.
- Every permission must survive a "why do we need this" test on
  the Profile → permissions screen, which lists each permission and
  its reason.

## Alternatives considered

- **Request broad storage access** — rejected; the system Photo
  Picker covers gallery picks with no permission.
- **Skip the merged-manifest check** — a transitive dependency
  adding INTERNET is exactly the failure R1 exists to prevent.
