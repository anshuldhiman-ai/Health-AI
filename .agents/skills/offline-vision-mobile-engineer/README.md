# Offline Vision Mobile Engineer

A reusable AI-agent skill for engineering offline-first Flutter/Android applications with on-device ML.

## Package contents

- `SKILL.md` — entry point and mandatory workflow
- `references/` — architecture, ML, privacy, numerical, safety, and project-baseline guidance
- `workflows/` — repeatable procedures for feature work, model integration, read-only audits, privacy audits, and release debugging
- `EVALUATION.md` — scenarios for checking whether an agent follows the skill
- `CHANGELOG.md` — version history

## How to use

1. Place this skill folder in the skills directory supported by your coding agent.
2. Make the skill available to the agent.
3. Ask the agent to inspect the repository before changing code.
4. For each task, ask it to cite exact file paths and report only checks it actually ran. For an audit, use `workflows/read-only-audit.md`; it requires a no-mutation boundary, a claim-to-evidence matrix, production-path tracing, CI wiring analysis, and before/after Git status.

The skill is designed to adapt to a repository. Health-AI-specific observations are isolated in `references/health-ai-project-baseline.md` and `AUDIT_NOTES.md`; load them only when the target is Health-AI, and reverify them against current source. They are not universal rules and must not shape audits of unrelated projects.

## Scope and exclusions

This package contains original guidance and summarized engineering observations. It intentionally does not contain Health-AI application source, model weights, datasets, nutrition catalogs, private credentials, or user data.

## Version

0.4.0 — adds mandatory seven-area audit coverage, evidence certainty labels and line-precise citations, a likelihood/impact severity rubric, required audit metadata, and conditional use of Health-AI-only references.

See `CHANGELOG.md` for release notes.
