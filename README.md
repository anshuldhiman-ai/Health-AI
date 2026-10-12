# README — {{APP_NAME}}

> Offline-first, privacy-first calorie, macro, activity and sleep tracker for Android.
> Every AI feature runs on the user's phone. No account, no server, no data leaves the device.

**Status: pre-alpha (M0 — foundation in progress).** See `CLAUDE.md` for the full
product definition, hard rules (R1–R16) and the milestone plan.

## What this is

A Flutter app whose headline feature is **photo-based meal logging with our own
on-device classifier**, tuned first for Indian food (dal, sabzi, roti, rice,
paratha, thali, snacks). Rule-based coaching only — no LLM in v1.

## Repository layout

| Area | Contents |
|---|---|
| `app/` | Flutter application (offline-only Android app) |
| `ml/` | Python training/export pipeline (PyTorch → LiteRT) |
| `docs/` | ADRs, dependencies, safety rules, design tokens, store assets |
| `tools/` | Repo scripts (manifest check, size budget) |

The three top-level areas never import from each other.

## Bootstrap (M0)

Prerequisites: [FVM](https://fvm.app) and a Flutter SDK it can install, Android
SDK with the `android-36` platform, Java 17+.

```bash
# --- App ---
cd app
fvm install            # reads .fvmrc
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs   # freezed/drift/riverpod codegen
fvm flutter gen-l10n
fvm flutter analyze
fvm flutter test

# Generate the Android/iOS platform folders if this clone lacks them
# (does not overwrite the files tracked in this repo):
fvm flutter create --platforms android,ios .

# --- ML ---
cd ../ml
uv sync
uv run ruff check . && uv run pytest
```

## Hard rules that shape everything

- **R1** — no network in release builds; the merged release manifest must not
  contain `INTERNET`. `tools/check_manifest.sh` enforces it.
- **R2** — no telemetry, no analytics, no crash-reporting SDKs.
- **R3** — user data encrypted at rest (SQLCipher, key in Android Keystore).
- **R4** — AI never writes silently; every model output needs user confirmation.
- **R12** — Python and Dart preprocessing must produce identical tensors
  (parity tests).

The full list is in `CLAUDE.md` Section 2.

## Open decisions (must be made before first release)

- [ ] App name, `{{APPLICATION_ID}}`, brand direction (Section 0)
- [ ] App licence (MIT vs Apache-2.0 vs proprietary) — no `LICENSE` file yet
- [ ] First v1 class list (the 40 most common dishes you actually eat)
- [ ] UI font family (M0 comparison)
- [ ] Reference devices (low / mid / flagship)

## Licence

To be decided — see open decisions above. Do not add a `LICENSE` file until
decided; the choice interacts with dataset and model licences (Section 14).
