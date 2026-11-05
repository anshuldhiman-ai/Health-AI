---
name: offline-vision-mobile-engineer
description: Use when designing, implementing, reviewing, or debugging offline-first Flutter/Android applications that run computer-vision or machine-learning inference on-device. Covers clean architecture, LiteRT/TFLite integration, image preprocessing parity, confidence handling, local persistence, numerical estimation, privacy controls, testing, CI, and release verification.
---

# Offline Vision Mobile Engineer

**Version:** 0.4.0

## Mission

Help an AI coding agent build reliable mobile applications that perform useful AI inference locally, protect user data, and remain understandable and testable.

This skill is informed by engineering patterns found in the Health-AI repository, but it is **not a command to copy that repository's architecture blindly**. Inspect the target project first and adapt to its actual constraints.

## When to use this skill

Use it when the task involves one or more of the following:

- Flutter or Android application architecture
- Offline-first application behavior
- On-device image classification or computer vision
- LiteRT / TensorFlow Lite model packaging and inference
- Image preprocessing and training/inference parity
- Confidence thresholds, uncertain predictions, or human confirmation
- Local persistence of sensitive or personal data
- Numerical estimation implemented in more than one language
- Mobile privacy, permissions, dependency, testing, or release audits

Do not use it as a substitute for a qualified security review, legal review, clinical review, or dataset-license review.

## Non-negotiable operating rules

1. **Inspect before changing.** Read the repository's agent instructions, README, manifests, architecture, tests, and relevant ADRs before editing.
2. **Separate facts from plans.** In audits, classify material claims as `Implemented`, `Partially implemented`, `Planned`, or `Unverified`; recommendations belong in remediation, not in the status taxonomy.
3. **Never infer completion from documentation alone.** Verify source files, build wiring, runtime call sites, tests, and CI execution.
4. **Do not invent metrics.** Accuracy, latency, memory, APK size, coverage, and test-pass counts require reproducible command output or a committed report with provenance.
5. **Preserve user data.** Do not introduce network transmission, analytics, telemetry, image retention, or cloud dependencies without explicit product approval and a privacy review.
6. **Keep domain logic testable.** Prefer pure Dart / Kotlin / Python logic outside UI and platform adapters where practical.
7. **Treat model outputs as estimates.** A classifier prediction is not ground truth. Show uncertainty and provide a correction or manual fallback.
8. **Validate model contracts.** Check input shape, dtype, layout, color order, normalization, output shape, label order, and model version at integration time.
9. **Verify release artifacts.** Source manifests and dependency declarations are not enough; inspect the final merged APK/AAB permissions and shipped assets.
10. **Respect licenses.** Verify code, pretrained weights, datasets, and derived model distribution rights separately. If uncertain, stop and ask.
11. **Do not copy project secrets or proprietary data into a skill package.** Summarize reusable patterns; exclude model weights, datasets, private catalogs, credentials, user records, and application source unless the owner explicitly authorizes distribution.
12. **Make the smallest safe change.** Avoid unrelated refactors. Add tests for behavior changed.

## Standard workflow

### Read-only repository audits

When the user requests an audit, review, assessment, or explicitly read-only work, use `workflows/read-only-audit.md` before inspecting the target repository. This workflow overrides implementation-oriented steps below: do not edit, create, delete, move, format, generate, or otherwise mutate target-project files. Treat any task-local instruction to update progress files as inapplicable to a read-only audit. If a requested check may write files or alter device/app state, omit it unless the user separately authorizes that side effect.

The audit must include a claim-to-evidence matrix with exactly these status categories: `Implemented`, `Partially implemented`, `Planned`, and `Unverified`. Each material claim needs actual source evidence and relevant file paths; documentation alone is not implementation evidence. Findings must include severity, technical evidence, user/business impact, reproduction status, and recommended remediation. Trace material features through UI → controller/provider → domain logic → persistence or model execution. Verify that safety rules, permissions, and validation checks are called on the production path; an unused function is not an implemented feature. For CI, inspect the command, test discovery/entry point, conditions, and whether a TODO/stub/skip can produce a false green.

Before finalizing, capture Git status again, report any changes that appeared during the audit, and list tests, builds, and device checks not run. Do not claim that static inspection proves runtime behavior.

Every audit must also complete all seven coverage areas in the workflow's checklist, label evidence as a verified fact, static inference, or unverified assumption, and use the likelihood/impact severity rubric. Identify the exact skill/version, workflow, repository, date, and checks executed/not executed in the report. Load Health-AI-only references only after confirming the target is this Health-AI repository; never use them as defaults for another project.

### 1. Discover the target repository

- Read `AGENTS.md`, `CLAUDE.md`, `README.md`, contribution guides, and relevant ADRs if present.
- Inspect package manifests, lockfiles, SDK pins, platform manifests, source tree, tests, and CI workflows.
- Identify current app flows and actual model assets.
- Find existing quality commands and run only safe, relevant checks.
- Record missing files, generated artifacts, and environment limitations.

### 2. Build an implementation map

Identify the actual boundaries. A common Flutter structure is:

- `presentation`: screens, widgets, view models
- `application`: feature orchestration and state transitions
- `domain`: entities, value objects, business rules, deterministic calculations
- `data`: persistence, repositories, model adapters, sensors, platform services
- `core`: shared errors, clocks, logging, formatting
- `design_system`: tokens and reusable visual components

Do not force these exact names if the repository already has a coherent structure. Enforce dependency direction with tests or static checks where valuable.

### 3. Design the feature contract first

Before implementation, write down:

- Inputs and validation rules
- Outputs and units
- Error and fallback states
- Data persistence and retention behavior
- Privacy implications
- Model/runtime contract, if relevant
- Test cases and acceptance criteria

For numeric outputs, state units and assumptions. For uncertain outputs, represent ranges or confidence explicitly rather than disguising estimates as measurements.

### 4. Implement in small layers

- Keep deterministic business logic independent of Flutter UI.
- Put plugin, file-system, camera, sensor, and ML-runtime code behind adapters.
- Make state transitions explicit.
- Serialize access to native model interpreters if the runtime is not safe for concurrent calls.
- Use typed failures or result objects for recoverable failures.
- Ensure every error state has a user-recoverable path.

### 5. Verify locally

Run the narrowest relevant tests first, then broader checks:

- Formatter and static analyzer
- Domain unit tests
- Widget and integration tests
- Model contract and preprocessing parity tests
- Architecture boundary tests
- Python lint and tests, if there is an ML pipeline
- Release manifest and package-size checks

Report the exact commands and results. If a toolchain is unavailable, say so instead of claiming success.

### 6. Review before completion

Summarize:

- Files changed
- Behavior implemented
- Tests actually run and their results
- Known limitations
- Security, privacy, licensing, and data risks
- Follow-up work that remains

## On-device ML integration checklist

Before shipping a model, verify all of the following:

- The model is present in the build and has a known version/hash.
- Input shape, batch dimension, dtype, channel order, layout, and normalization are documented.
- Training and mobile preprocessing are compared using fixed fixtures.
- Output semantics are known: logits vs probabilities, class ordering, quantization, and postprocessing.
- Label count and ordering match the output tensor.
- Interpreter creation, warm-up, execution, and disposal are handled safely.
- Large image decoding does not cause avoidable memory spikes.
- Confidence/rejection thresholds are calibrated on representative positive and negative data.
- Uncertain predictions require confirmation or offer manual search.
- Missing/corrupt model assets degrade gracefully.
- A real-device test measures latency, memory, thermal behavior, and airplane-mode behavior.
- The model card records data provenance, licenses, metrics, known limitations, and intended use.

A unit test of threshold logic does **not** validate the threshold's real-world accuracy.

## Privacy and offline checklist

- Minimize requested Android permissions and document why each is needed.
- Remove forbidden permissions through manifest-merger rules when that is the product requirement.
- Inspect the final merged release manifest, not just the app's source manifest.
- Inspect direct and transitive dependencies for network, analytics, crash-reporting, and advertising behavior.
- Do not call an app "100% offline" based only on a manifest or package-name scan.
- Define the source of truth and failure semantics for each storage tier.
- Do not describe plaintext JSON or preferences as encrypted merely because a secure-storage mirror also exists.
- Keep photos transient unless the user explicitly saves them; verify temporary-file cleanup and logs.
- Test deletion, corruption recovery, backup/restore, and process interruption.
- Never log health data, image bytes, tokens, or private user content.

## Numerical and estimation checklist

- Keep formulas in a pure, deterministic domain layer.
- Define units and valid input ranges.
- Use physically meaningful models only when their assumptions fit the input.
- Label priors and calibration values as placeholders until measured.
- Represent uncertain quantities as intervals or distributions.
- Keep a shared, version-controlled set of numerical test vectors for implementations in different languages.
- Ensure tests exercise defaults as well as explicit parameters; shared fixtures can otherwise hide divergent defaults.
- Use seeded randomness in tests.
- Compare model estimates against a held-out, representative, measured dataset before claiming accuracy.

## References

Load only the references relevant to the task:

- `references/architecture-and-flutter.md`
- `references/on-device-ml.md`
- `references/offline-privacy-security.md`
- `references/numerical-estimation.md`
- `references/testing-and-release.md`
- `references/health-safety-and-licensing.md`

**Conditional, project-specific references:** Load `references/health-ai-project-baseline.md` and root-level `AUDIT_NOTES.md` only when the target is the Health-AI repository identified by its repository files. They are dated orientation, not reusable rules; verify every claim against the target's current source. For any other repository, do not load or cite them. Use only the generic references above unless the user explicitly requests a comparison.

For step-by-step work, use:

- `workflows/implement-mobile-feature.md`
- `workflows/integrate-on-device-model.md`
- `workflows/audit-privacy-and-offline.md`
- `workflows/debug-release-gates.md`
- `workflows/read-only-audit.md` for explicitly read-only audits and repository evaluations

## Required response format for an agent using this skill

For repository tasks, structure the final response as:

1. **What I found** — concise, evidence-based state.
2. **What I changed** — exact paths and behavior.
3. **Verification** — commands run, pass/fail, and unavailable checks.
4. **Risks and limitations** — explicit, not hidden.
5. **Next step** — one practical recommendation.

Never claim a test passed unless it was actually executed and its exit status was observed.

For read-only audits, use the response structure required by `workflows/read-only-audit.md` instead. Include the claim-to-evidence matrix, prioritized findings, verification limits, and final Git-status comparison.
