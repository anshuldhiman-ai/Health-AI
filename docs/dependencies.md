# Dependencies (R6)

Every package needs justification before it is added: maintenance
(last release, open issues), licence (must be permissive: MIT, BSD,
Apache-2.0, MPL), size impact, and that it makes **no network calls**.

> **Status: M0 draft.** The packages below are the planned set from
> CLAUDE.md Section 3. Before the first `pub get`, verify each one's
> current maintenance status, licence and changelog on pub.dev, and
> fill in the "Verified" columns. Record any new dependency here in
> the same PR (Section 11.4).

## App (Flutter / Dart)

| Package | Purpose | Licence | Maintenance (verify) | Network? | Size impact | Verified |
|---|---|---|---|---|---|---|
| `flutter_riverpod` | State management / DI | MIT | check pub.dev | None known | small | ☐ |
| `riverpod_generator` + `riverpod_annotation` | Code-gen providers | MIT | check pub.dev | None | dev only | ☐ |
| `go_router` | Typed navigation, deep links | BSD-3 | check pub.dev | None known | small | ☐ |
| `freezed` + `freezed_annotation` | Immutable models, unions | MIT | check pub.dev | None | dev only | ☐ |
| `json_serializable` + `json_annotation` | JSON codec codegen | MIT | check pub.dev | None | dev only | ☐ |
| `drift` + `drift_dev` | Typed SQLite, migrations, reactive streams | MIT/Apache-2.0 (check) | check pub.dev | None | moderate | ☐ |
| `sqlcipher_flutter_libs` | SQLCipher native libs | Apache-2.0 (check) | check pub.dev | None | ~3-5 MB native | ☐ |
| `flutter_secure_storage` | Android Keystore-backed key storage | MIT | check pub.dev | None | small | ☐ |
| `health` | Health Connect (read-only) | BSD-3 (check) | check pub.dev | None | small | ☐ |
| `flutter_litert` | LiteRT runtime | Apache-2.0 (check) | **verify carefully — community-maintained** | None | ~5-10 MB | ☐ |
| `camera` | Camera for photo scan | BSD-3 | Google-maintained | None | small | ☐ |
| `image_picker` | System Photo Picker | BSD-3 | Google-maintained | None | small | ☐ |
| `image` | Dart image decode/resize in isolates | BSD-3 | check pub.dev | None | small | ☐ |
| `fl_chart` | Charts, styled via tokens | MIT | check pub.dev | None | moderate | ☐ |
| `flutter_local_notifications` | Local reminders | BSD-3 | check pub.dev | None | small | ☐ |
| `local_auth` | Optional biometric app lock | BSD-3 | Google-maintained | None | small | ☐ |
| `flutter_localizations` + `intl` | l10n (ARB) | BSD-3 / BSD-3 | Google / Dart team | None | small | ☐ |
| `mocktail` | Test mocks | MIT | check pub.dev | None | dev only | ☐ |
| `golden_toolkit` | Golden tests | MIT | check pub.dev | None | dev only | ☐ |

**Explicitly rejected (R2):** `google_fonts` (runtime fetching),
Firebase/analytics/crash SDKs, ad SDKs, remote config.

## ML (Python)

Pinned via `ml/uv.lock` (Section 3.2). Verify licences before
adopting: PyTorch, timm, torchvision, albumentations, hydra/omegaconf,
litert-torch, ai-edge-litert, torchmetrics, scikit-learn, imagehash,
cleanvision, cleanlab, fiftyone, ruff, pytest, pyright.

## Rules

- Commit `pubspec.lock` and `ml/uv.lock`. Upgrades happen in
  dedicated PRs with changelog review (Section 9.5).
- No `git:` or path dependencies on `main` unless pinned to a commit
  hash and documented here.
- After ANY dependency change: rebuild the release bundle and re-run
  `tools/check_manifest.sh` — native plugins can silently add
  permissions.
- CI runs a vulnerability scan (e.g. OSV-Scanner) against both
  lockfiles.
