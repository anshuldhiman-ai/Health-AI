# ADR 0007: On-device model packaging and integrity (R11)

## Context

The classifier ships as a bundled asset. It must be tamper-evident,
versioned, and its provenance (data, weights licence, metrics) must
be auditable — including by the user, on the About screen.

## Decision

Files in `app/assets/models/`:

- `food_classifier_vN.tflite` — the model
- `labels.json` — ordered class labels with its own hash
- `model_card.json` — the card with required fields (Section 8.11):
  `model_version`, `created_at`, `git_commit`, `data_version` (DVC
  hash), `datasets[]` (name, licence, URL), `pretrained_weights`
  (name, licence), `architecture`, `params`, `input_spec`,
  `quantization`, `size_bytes`, `sha256`, `calibration_temperature`,
  `reject_threshold`, `metrics` (golden test), `latency_ms` per
  device, `known_limitations`, `intended_use`.

The app verifies the `.tflite` SHA-256 at startup (bootstrap order:
keystore → DB → model integrity → runApp). On mismatch or missing
model, the scan feature degrades to a clear "Photo scan unavailable"
state; manual logging keeps working (`ModelIntegrityFailed`).

The About screen shows the model version and a one-line honest
accuracy statement derived from the card. Numbers in the card come
from running the scripts and are pasted with the commit hash (R7).

## Consequences

- A corrupted or tampered asset is caught before it can produce
  wrong predictions.
- Every prediction stores `model_version`, so accuracy can be
  audited later against a specific card.

## Alternatives considered

- **Download model updates** — rejected: violates R1 (no network)
  and R11's tamper-evidence is weaker without signature pinning.
- **Skip the card** — R11 makes it mandatory; it is also the
  honest-AI principle made concrete.
