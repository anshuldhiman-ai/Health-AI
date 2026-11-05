# Changelog

## 0.4.0

- Added a mandatory seven-area coverage checklist for read-only audits.
- Required exact source paths and line numbers wherever available, with explicit Verified fact / Static inference / Unverified assumption labels.
- Added likelihood and impact scales, severity mapping, and explicit distinction between confirmed release blockers and potential risks.
- Required audit metadata: skill/version, workflow, repository, date, and checks executed/not executed.
- Made Health-AI baseline and audit notes conditional on the target being Health-AI.
- Added evaluation scenarios for all v0.4 capabilities.

## 0.3.0

- Added `workflows/read-only-audit.md` with a no-mutation protocol, initial/final Git status checks, safe inspection guidance, and explicit unrun-check reporting.
- Required a four-state claim-to-evidence matrix and production-path tracing for audit work.
- Standardized finding fields: severity, technical evidence, user/business impact, reproduction status, and remediation.
- Added CI test-discovery, stub, skip, and false-green analysis.
- Marked Health-AI baseline material as dated and volatile; clarified that source verification takes precedence.
- Expanded `EVALUATION.md` with scenarios for audit boundaries, evidence, production paths, CI wiring, finding quality, and baseline drift.

## 0.2.0

- Initial repository-informed skill and technical reference set.
