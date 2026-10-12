# ADR 0001: Offline-first, no network in release builds

## Context

The product is a calorie, macro, activity and sleep tracker whose headline
feature is photo-based meal classification. The founder's core principles
(CLAUDE.md Section 1) put safety and privacy over features, and the
target users will often be offline (airplane mode, low connectivity,
campus/hostel networks).

The obvious shortcut — a thin cloud backend for sync, model updates and
analytics — would:

- require accounts, servers, and ongoing cost;
- expose sensitive health data (meals, weight, sleep) to a server;
- break the app exactly where users need it most.

## Decision

v1 has **no backend and no network capability at all**. Specifically:

1. The release merged manifest MUST NOT contain `android.permission.INTERNET`
   or `ACCESS_NETWORK_STATE`. The app manifest removes both with
   `tools:node="remove"` so no transitive dependency can re-add them
   (R1). `tools/check_manifest.sh` fails the build otherwise.
2. No telemetry, analytics, crash-reporting, remote-config or ad SDKs (R2).
3. The ML model is bundled as an asset and verified by SHA-256 at startup
   (R11); model updates ship through app-store updates only.
4. Data lives in two local databases: a read-only bundled `nutrition.db`
   and an encrypted `user.db` (SQLCipher, key in Android Keystore) (R3).
5. If a cloud feature is ever added, it ships behind a separate
   `connected` Android flavor so the default `offline` flavor keeps rule 1
   intact (CLAUDE.md Section 3.3). Do not create that folder until the
   roadmap reaches it.

## Consequences

- No sync, no backup to cloud; backup is a user-driven encrypted file
  (Section 9.3).
- No remote model updates: fixing a model means an app update. Accepted.
- Play Store Data-safety form has the simplest honest answer: no data
  collected, no data shared.
- Debug/profile builds legitimately contain INTERNET for tooling; they are
  NEVER evidence of offline behaviour.

## Alternatives considered

- **Cloud sync from day one** — rejected: privacy posture, cost, and it
  breaks offline-first.
- **Optional opt-in sync** — deferred to the roadmap; requires a full
  privacy redesign (consent, purpose limitation, deletion).
