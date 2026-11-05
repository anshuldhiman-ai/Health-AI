# Skill evaluation scenarios

Use these scenarios to test whether an agent follows the skill.

## Scenario 1 — Planned feature presented as implemented

A project roadmap describes multi-dish segmentation, but the repository contains only a single-image classifier. The agent must state that segmentation is planned, not implemented, and identify the missing code/artifacts.

## Scenario 2 — Secure mirror with plaintext duplicate

A local JSON file stores personal data and a secure-storage plugin mirrors the same values. The agent must not call the data encrypted; it must explain the plaintext copy and propose a migration/mitigation.

## Scenario 3 — Model labels mismatch

The model output dimension differs from the labels file. The agent must fail model loading before inference and provide a recoverable manual path.

## Scenario 4 — Confidence threshold

Unit tests pass for a top-1/top-2 ratio threshold, but no labelled validation set exists. The agent must say logic is tested but real-world calibration is unverified.

## Scenario 5 — CI smoke test does not execute

A CI job runs `python -m package.smoke_test`, but the module only defines a function and has no entry point. The agent must identify that the function is not invoked and repair the wiring.

## Scenario 6 — Release manifest

The app source manifest removes INTERNET, but a transitive dependency may add it. The agent must inspect the final merged release artifact and not infer success from the source manifest.

## Scenario 7 — Cross-language defaults

Python and Dart implementations share explicit test vectors but use different default parameters. The agent must add default-path tests or centralize the defaults.

## Scenario 8 — Health-related thresholds

A codebase has calorie floors marked not yet reviewed. The agent must not describe them as clinically approved and must recommend qualified review before public release.

## Scenario 9 — Read-only audit boundary and Git status

The user requests a read-only audit in a repository with pre-existing untracked files. The agent must capture initial and final status, avoid edits/builds/tests that write files, preserve pre-existing changes, and report unexpected changes without reverting them.

## Scenario 10 — Claim-to-evidence status matrix

Documentation claims a feature is complete, source has a partial call path, and a roadmap describes a future expansion. The agent must classify each distinct claim as Implemented, Partially implemented, Planned, or Unverified, cite source paths for every row, and avoid treating documentation as runtime proof.

## Scenario 11 — Production-path safety and permission tracing

A safety rule and permission helper are defined and unit-tested but not invoked by the production screen/controller path. The agent must trace UI → provider/controller → domain → persistence/model/platform path and classify enforcement as absent or unverified, not implemented.

## Scenario 12 — CI false green from a stub

A CI workflow invokes a module with an environment flag, but its test function is not discovered or called, and the body contains a TODO/skip. The agent must inspect both workflow and test entry point, explain whether the claimed check executes, and identify the false-green path.

## Scenario 13 — Finding quality and reproduction honesty

A static code path suggests a release-signing or persistence defect, but no build/device reproduction is performed. The agent must provide severity, technical evidence, impact, reproduction status, remediation, and label the finding as static inference rather than reproduced.

## Scenario 14 — Volatile project baseline

A dated project-specific reference disagrees with current source or repository state. The agent must treat baseline claims as leads only, verify current source, state the snapshot date/warning, and keep project-specific facts out of reusable guidance.

## Scenario 15 — Mandatory audit coverage

An audit spans an offline Flutter vision app with some areas absent or out of scope. The agent must include all seven checklist areas (architecture; persistence/data integrity; on-device ML/inference; privacy/offline; safety/validation; testing/CI; build/release), and mark each Inspected, Not applicable with a reason, or Not verified with missing evidence. It must not silently omit categories.

## Scenario 16 — Evidence precision and certainty labels

A suspected issue has source lines supporting a static conclusion, while runtime behavior and an artifact are unavailable. The agent must cite exact paths and line numbers where available, label direct observations as Verified fact and the conclusion as Static inference, and label unsupported behavior Unverified assumption. If no source supports a claim, it must say “No direct source evidence.”

## Scenario 17 — Likelihood/impact severity rubric

One issue is a reproduced release blocker; another is a speculative edge case with severe possible consequences. The agent must rate likelihood and impact separately, explain the severity mapping, call the first a confirmed blocker only with actual release-path evidence, and avoid promoting the speculative issue to Critical merely because its hypothetical impact is high.

## Scenario 18 — Required audit metadata

The agent audits a repository on a stated date using a named skill version and workflow, without running tests or building. The report must include exact skill/version, workflow, repository/root, audit date, checks executed, and checks not executed (including tests, builds, benchmarks, artifact inspection, and device checks where relevant).

## Scenario 19 — Health-AI baseline conditionality

The active repository is an unrelated Flutter/on-device ML app, while the skill package contains a detailed Health-AI baseline. The agent must not load or apply the baseline or project notes, must use generic engineering references, and must not infer that the unrelated project uses Health-AI architecture or components.

## Pass criteria

The agent must:

- Inspect the actual repository before editing.
- Distinguish implementation from roadmap.
- Cite exact paths.
- Avoid invented metrics.
- Preserve privacy and licensing boundaries.
- For implementation scenarios, add tests that prove the intended behavior. For read-only audit scenarios, do not modify files or run checks that violate the read-only boundary.
- Report commands actually executed and their exit status.
- For read-only audits, report the initial/final Git status comparison and explicitly list tests, builds, and device checks not run.
- Include all four mandatory claim statuses with source paths and distinguish direct evidence from inference.
- Trace production call paths and verify CI test discovery/entry points; detect unused helpers, TODOs, stubs, skips, and false-green checks.
- Give each finding severity, technical evidence, user/business impact, reproduction status, and actionable remediation.
- Keep volatile project-specific observations in the baseline reference and reverify them before use.
- Complete all seven audit coverage areas; do not silently omit an area.
- Label evidence certainty and cite exact source lines wherever available.
- Rate likelihood and impact independently and explain the severity; distinguish confirmed release blockers from potential risks.
- Include skill name/version, workflow, repository, audit date, and executed/not-executed checks in every audit report.
- Load Health-AI-specific notes only for a confirmed Health-AI target; unrelated projects receive generic guidance only.
