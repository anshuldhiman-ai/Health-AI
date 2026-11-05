# Testing, CI, and release verification

## Test pyramid

Use the narrowest appropriate test first:

- Pure unit tests for domain calculations and validation
- Repository/storage tests for persistence, migrations, and corruption
- Widget tests for states and user interactions
- Integration tests for camera, sensors, platform APIs, and ML runtime
- Device tests for real latency, memory, thermal, and lifecycle behavior

Mock platform boundaries for fast tests, but keep at least a small number of real-device tests for critical hardware/runtime paths.

## Test what the product promises

Examples:

- App opens and core diary flows work in airplane mode.
- Missing/corrupt model still permits manual logging.
- Wrong model/label dimensions fail before inference.
- Uncertain prediction cannot be silently committed.
- Storage survives malformed data and process interruption.
- Delete-all clears all stores and mirrors.
- Domain code does not import UI/plugin packages.
- Python and Dart numerical calculations match shared vectors.
- Preprocessing parity holds on fixed images.
- Release manifest has no forbidden permission.
- Model version and checksum match the shipped asset.

## CI wiring must execute the test

A file existing in a repository does not mean CI runs it. Verify:

- The workflow command reaches the intended function/test.
- The filename matches the test runner's discovery convention, or the runner explicitly targets it.
- Feature flags/environment variables activate the intended branch.
- The test fails when a deliberate defect is introduced.
- The job waits for and reports the real exit code.

A module invocation that merely imports a function is not a test run unless the module has an entry point that invokes it.

## Release gates

Before release:

- Format and static analysis pass.
- Unit/widget/integration tests pass.
- Python lint/tests pass.
- Model contract and export/parity tests pass.
- Dependency and license checks pass.
- Final merged release manifest is inspected.
- Release asset and model checksums are verified.
- Size, latency, memory, and thermal budgets are measured on named devices.
- Safety and privacy review is current.
- All placeholders blocking release are removed or formally approved.

## Reporting discipline

Include exact commands, environment versions, commit hash, timestamps, and test summaries. Never convert an expected gate or a test file into a claim that it passed.
