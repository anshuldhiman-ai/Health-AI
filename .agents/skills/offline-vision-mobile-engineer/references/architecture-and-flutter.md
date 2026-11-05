# Flutter architecture and engineering patterns

## Start with repository reality

Read the repository's own architecture notes and tests. Do not introduce a new architecture just because this reference describes one.

## Useful layer boundaries

A practical separation for Flutter feature work:

- Presentation: widgets, screens, accessibility, view-specific formatting.
- Application: feature orchestration, commands, state transitions.
- Domain: entities, value objects, business rules, pure calculations.
- Data: persistence, model runtime adapters, sensors, platform APIs.
- Core: shared errors, clocks, logging interfaces, formatting.
- Design system: tokens and reusable UI primitives.

Dependencies should point inward. Domain logic should not import Flutter UI, navigation, storage plugins, camera plugins, or native ML runtime APIs.

## State and navigation

- Use the project's existing state-management package and conventions.
- Keep state mutations explicit and testable.
- Handle loading, success, empty, and error states.
- Avoid hidden side effects during widget build.
- Centralize route definitions and onboarding/auth guards.
- Keep feature screens independent of each other's internal implementation.

## Error handling

Use typed errors or a `Result`-style type when callers need to handle expected failures. Reserve thrown exceptions for exceptional or boundary-level failures. Convert plugin/runtime errors into stable application failures at the adapter boundary.

Every recoverable failure should have a user action: retry, retake, search manually, edit the result, or continue without the optional feature.

## Local persistence

Before choosing a storage design, define:

- Source of truth
- Data schema and migrations
- Atomicity and write ordering
- Corruption recovery
- Encryption requirements and key lifecycle
- Backup/export behavior
- Delete-all semantics
- Failure behavior when one tier is unavailable

Do not call a multi-copy storage arrangement "encrypted" if a plaintext copy remains. Do not call a synchronous file flush crash-proof; document the guarantees and test process interruption/corruption.

## Architecture tests

Useful automated checks include:

- Domain imports only approved libraries.
- Design-system code does not depend on features.
- Feature modules do not reach into other feature internals.
- File and symbol naming conventions are consistent.
- Platform/plugin dependencies stay in data or adapter layers.

Regex-based import scanners are useful guardrails but are not a complete language parser. Keep rules narrow and review false positives/negatives.

## UI quality

- Use centralized semantic design tokens.
- Support light/dark themes where required.
- Respect text scaling, screen size, accessibility labels, and tap-target size.
- Keep user-facing strings localizable.
- Treat visual goldens as regression checks, not proof of usability.
