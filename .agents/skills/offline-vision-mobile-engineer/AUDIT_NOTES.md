# Source audit notes

Snapshot reviewed: `HEALTH_AI_SKILL_AUDIT.zip`, submitted 2026-11-03. This note and the project-baseline reference are volatile leads, not reusable engineering rules or verified facts about a later checkout. Recheck source and runtime call sites before citing any claim.

## Strong reusable ideas

- Keep deterministic geometry/nutrition calculations in pure Dart.
- Use a shared fixture for Python/Dart numerical regression tests.
- Validate model input/output shape and label cardinality before inference.
- Serialize interpreter access and dispose native resources.
- Make uncertain predictions explicit and provide manual correction.
- Remove unnecessary Android permissions and inspect release artifacts.
- Keep a known-good single-classifier fallback while multi-model work is incomplete.

## Findings that must not be marketed as completed capabilities

- SQLCipher/Drift production persistence
- Multi-dish segmentation and embedding pipeline
- Full capture worker and mask postprocessing
- Measured mass calibration
- Sensor adapter for tilt
- Real-device ML integration benchmarks
- Clinically reviewed nutrition safety thresholds
- Completed final release gate

See `references/health-ai-project-baseline.md` for paths and detailed caveats.
