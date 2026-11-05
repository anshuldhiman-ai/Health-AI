# Workflow: implement a mobile feature safely

## Step 1 — Inspect

- Read agent instructions, README, ADRs, and current progress.
- Trace the nearest existing feature end-to-end.
- Identify state, routing, domain logic, persistence, and platform dependencies.
- Note the current SDK and package versions from actual pins/lockfiles.

## Step 2 — Specify

Write a short contract covering:

- User story
- Inputs/outputs and units
- Loading/empty/error/success states
- Persistence and deletion behavior
- Privacy and permissions
- Offline behavior
- Acceptance tests

## Step 3 — Design

- Put deterministic rules in the domain layer.
- Put orchestration in the application layer.
- Keep widgets focused on presentation.
- Put storage/plugins/sensors/ML runtime behind data adapters.
- Reuse existing state and navigation conventions.

## Step 4 — Implement

- Make the smallest change.
- Use typed failures for expected problems.
- Add fallback/recovery actions.
- Do not add a dependency without maintenance, license, network, permission, and size review.

## Step 5 — Test

- Add unit tests for domain logic.
- Add storage/widget tests as appropriate.
- Add architecture tests if a new dependency boundary is introduced.
- Test offline and failure paths.
- Run formatter, analyzer, and relevant tests.

## Step 6 — Report

List changed files, actual test commands/results, limitations, and any release blockers.
