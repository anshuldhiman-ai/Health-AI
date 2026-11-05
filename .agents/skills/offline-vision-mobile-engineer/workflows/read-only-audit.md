# Read-only repository audit

Use this workflow when the user asks for an audit, review, evaluation, or inspection without implementation. It applies to offline-first Flutter/Android apps and on-device AI projects; adapt the evidence sources to the target repository.

## Required audit metadata

At the top of every audit report, state:

- **Skill:** exact skill name and version (for example, `offline-vision-mobile-engineer` `0.4.0`)
- **Workflow:** `workflows/read-only-audit.md` (include any additional workflow actually used)
- **Repository audited:** repository name and root/path
- **Audit date:** date used for this audit
- **Checks executed:** exact inspection/check commands actually executed and observed results
- **Checks not executed:** relevant tests, builds, benchmarks, artifact inspections, or device checks not run, with reason

Do not report only “no tests run” when builds, benchmarks, or device checks also apply. Do not imply a command passed unless its exit status/output was observed.

## 1. Establish the boundary and baseline

- Confirm the requested scope and any explicit write restrictions. A read-only request prohibits changes even when repository guidance normally asks agents to update a checklist or progress file.
- Record the repository root and capture `git status --short` before inspection. If the tree is already dirty, distinguish pre-existing changes from anything observed later; do not clean, stage, stash, or reset them.
- Do not edit, create, delete, move, format, generate, install, build, or run commands that may mutate project files or app/device state. Avoid tests/builds by default in a read-only audit. Run one only when the user explicitly authorizes that side effect and its outputs are safely contained.

## 2. Inspect safely and gather evidence

Prefer read-only inspection such as `git status --short`, `git diff --`, `git ls-files`, `rg`, `Get-Content`, and directory listing. Avoid commands with output redirection, formatters, code generators, package installation, migrations, cleanup, or release scripts. Inspect agent instructions and documentation, but treat them as claims to verify.

For each in-scope feature, trace the real production path:

`UI → controller/provider → domain logic → repository/platform adapter → persistence or model execution`

Follow call sites in both directions as needed. Verify that validation, permission requests, safety limits, error handling, and fallback logic are invoked on that path. A declared dependency, unreferenced helper, screen mock, test-only implementation, roadmap item, or documentation statement is not proof of a shipped feature.

For on-device AI, inspect the shipped assets and runtime path: preprocessing, tensor contract, interpreter lifecycle, output interpretation, confidence/rejection, fallback, and model provenance. For local data, trace writes and reads, authoritative source, encryption, errors, migrations, and deletion. For offline/privacy claims, inspect source and merged artifact evidence if already present; do not build an artifact just to inspect it under read-only constraints.

For CI and tests, inspect workflow triggers and conditions, exact invoked command, test discovery or module entry point, environment flags, and the test body. Identify TODOs, stubs, skips, disabled assertions, and commands that can exit successfully without exercising the stated check.

Record evidence while inspecting. Cite precise paths (and line numbers when available). Separate direct observations from inferences and state what evidence is unavailable. Do not expose secrets, user records, private source, or proprietary model/data content; report only the minimum safe metadata needed to establish a finding.

### Evidence precision and certainty

- For every source-based claim or finding, cite the exact repository-relative file path and exact line number(s) wherever available. Use a narrow line span only when needed to show a complete mechanism. If line numbers cannot be established, say why and give the exact file/path plus symbol or section.
- Label each material assertion as one of:
  - **Verified fact** — directly established by inspected source, configuration, artifact, or command output. State which evidence type supports it.
  - **Static inference** — conclusion follows from inspected code/configuration but was not reproduced at runtime. Explain the reasoning and limits.
  - **Unverified assumption** — evidence is missing or inconclusive. Name the missing evidence; do not present it as a fact.
- If there is no direct source evidence, explicitly write **“No direct source evidence”** and classify the claim as unverified unless other evidence supports a narrower conclusion.
- A document's assertion is verified only as “the document says X”; it does not verify the behavior X describes.

## 2A. Mandatory audit coverage checklist

Complete every row for every audit. Mark `Inspected`, `Not applicable` (with a reason), or `Not verified` (with the evidence needed). Cite paths/lines in the evidence column. A short checklist is acceptable; silently omitting an area is not.

| Area | Required inspection | Coverage status and evidence |
|---|---|---|
| Architecture | UI/application/controller/provider/domain/data boundaries, navigation/state flow, production call paths | |
| Persistence and data integrity | Read/write source of truth, serialization, encryption, failures, migrations, deletion, recovery/process interruption | |
| On-device ML and inference | Assets, preprocessing, tensor contract, model lifecycle, output/rejection, fallback, provenance and runtime call path | |
| Privacy and offline behavior | Permissions, manifests/artifacts available, network-capable dependencies, storage/photos/logging/backup; distinguish static from runtime evidence | |
| Safety and validation | User input validation, health/safety rules, permission checks, confidence/range checks and whether each is invoked in production | |
| Testing and CI | Test coverage, test discovery, exact workflow command/conditions, stubs/skips/TODOs and false-green paths | |
| Build and release | SDK/config, build/signing, artifact checks, packaging, release gates and observed/unobserved evidence | |

Do not force an area into the implementation matrix if it is not a capability claim; still complete its coverage row.

## 2B. Conditional project-specific references

First identify the target repository using its root and repository files. Load `references/health-ai-project-baseline.md` and `AUDIT_NOTES.md` **only** if the target is Health-AI. Treat them as dated, volatile leads and reverify against current source. For all unrelated repositories, do not load, cite, or apply Health-AI project facts or architecture assumptions. Generic engineering references remain available for either target.

## 3. Build the mandatory claim-to-evidence matrix

Every material capability claim must appear under exactly one of these statuses:

| Status | Claim | Evidence certainty | Source evidence (exact path and line(s), where available) | Gap or qualification |
|---|---|---|---|---|
| **Implemented** |  | Verified fact / Static inference / Unverified assumption |  |  |
| **Partially implemented** |  | Verified fact / Static inference / Unverified assumption |  |  |
| **Planned** |  | Verified fact / Static inference / Unverified assumption |  |  |
| **Unverified** |  | Verified fact / Static inference / Unverified assumption |  |  |

The four rows above are a template for separate claims, not a requirement to force one claim into every status. Include only statuses supported by the audit; do not omit any status that applies to a material claim. Every material claim needs its own row and evidence citation.

Include at least one source path for every row. Use separate rows for distinct claims; do not let one feature's partial implementation imply its dependent capability is complete. Do not use `recommended` as a status category; recommendations belong in findings.

## 4. Rank findings consistently

For each finding, rate **likelihood** and **impact** separately before assigning `Critical`, `High`, `Medium`, or `Low`. State the rationale. Do not let confidence in the evidence substitute for likelihood: a verified code fact can still have low likelihood of harm, and an uncertain theory must not be called a confirmed blocker.

### Likelihood scale

- **High:** occurs on the normal production path or is directly reproducible under ordinary conditions.
- **Medium:** plausible under a common but conditional path or configuration.
- **Low:** requires unusual conditions, has strong mitigations, or is speculative.
- **Unknown:** evidence is insufficient; use this explicitly rather than guessing.

### Impact scale

- **Severe:** credible risk of serious safety/privacy harm, unrecoverable sensitive-data loss, broad compromise, or invalidating a mandatory release requirement.
- **Major:** breaks a core user journey, materially corrupts data/results, or blocks intended distribution.
- **Moderate:** degrades an important feature with a reasonable workaround or limited scope.
- **Minor:** cosmetic, low-impact, or non-blocking maintainability issue.

### Severity mapping

- **Critical:** high/confirmed likelihood with severe impact, or a reproduced severe safety/privacy/data-loss issue affecting users broadly. A merely possible risk is not Critical.
- **High:** high likelihood with major impact; a confirmed release blocker for the intended release; or a credible severe risk with strong source evidence. Say “confirmed release blocker” only when the blocking condition is directly established or reproduced against the actual release path/artifact.
- **Medium:** moderate impact with medium likelihood, or a material but contained risk with a workaround; also use for substantial uncertainty that merits investigation but is not a demonstrated blocker.
- **Low:** low likelihood and minor impact, or a limited documentation/maintenance issue without material user or release harm.

If impact/likelihood do not fit a clean mapping, explain the judgment rather than mechanically inflating severity. Distinguish **confirmed release blocker**, **potential release risk**, and **not established** in the finding text.

Each finding must include:

- **Severity and title**
- **Likelihood and impact**: ratings plus why they fit the evidence
- **Technical evidence**: exact paths/lines and concise mechanism
- **User/business impact**: concrete consequence
- **Evidence certainty and reproduction status**: verified fact, static inference, or unverified assumption; say reproduced/not reproduced and name conditions only if actually used
- **Recommended remediation**: specific next engineering action

Group related evidence only when the same root cause and remediation apply. Make uncertainty explicit; do not present static inference as a reproduced failure.

## 5. Close the audit without changing the repository

- Capture `git status --short` again. Compare it with the initial status and report unexpected changes. Do not revert them; report and stop if the audit unexpectedly caused a change.
- State whether tests, builds, benchmarks, merged-artifact inspection, and physical-device checks were run. Explicitly list every relevant category not run and why (for example, read-only constraint, unavailable hardware/toolchain, or missing artifact).
- Do not invent metrics or imply runtime validation from source inspection.

## Required audit response

1. **Audit metadata** (all required fields above)
2. **Executive summary**
3. **Mandatory coverage checklist** (all seven areas)
4. **Claim-to-evidence matrix** (`Implemented`, `Partially implemented`, `Planned`, `Unverified`) with evidence certainty
5. **Findings** ranked by severity, with likelihood, impact, evidence certainty, reproduction status, user impact, and remediation
6. **Verification and limitations**, including checks not executed
7. **Initial/final Git status comparison**
8. **Skill/workflow evaluation**, when the user asks whether the skill itself was effective

