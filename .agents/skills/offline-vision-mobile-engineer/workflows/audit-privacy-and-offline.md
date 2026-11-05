# Workflow: audit privacy and offline behavior

## 1. Map data flows

For each data type (images, meals, body metrics, activity, sleep, settings), record source, processing location, storage location, retention, deletion, and any transmission.

## 2. Inspect network surface

- App and merged manifests
- Direct/transitive dependencies
- Native SDKs
- WebViews and URL handlers
- Analytics/crash-reporting
- Background jobs
- Model/config update mechanisms

## 3. Inspect storage

- Identify plaintext and encrypted stores.
- Verify key lifecycle and backup rules.
- Check duplicate copies and cache locations.
- Test corruption and deletion.
- Identify hard-coded paths and permission assumptions.

## 4. Inspect image lifecycle

Trace capture/picker → bytes → preprocessing → inference → UI → disposal. Confirm whether images are written to disk, gallery, logs, crash reports, or analytics.

## 5. Inspect the built artifact

Build release and inspect the final merged manifest and package contents. Confirm that the artifact being tested is the artifact being released.

## 6. Report

For each claim, include evidence paths and status:

- Verified in source
- Verified in built artifact
- Runtime-tested
- Partially verified
- Not verified

Do not use "zero data collection" or "100% offline" unless the evidence supports the exact claim.
