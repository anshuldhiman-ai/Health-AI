# ADR 0002: Layer discipline — pure-Dart domain, Riverpod, go_router

## Context

The app needs state management, navigation and data access that stay
testable and keep business logic out of widgets. The team is one
developer; the stack must be boring, well-maintained and licence-safe.

## Decision

- **State / DI: Riverpod** (`flutter_riverpod`, code-gen via
  `riverpod_generator`). Compile-safe providers, easy testing with
  overrides, no global mutable state outside providers.
- **Navigation: go_router** with typed routes, deep links and an
  onboarding redirect guard.
- **Domain layer is pure Dart**: no Flutter, no packages except
  `meta`/`collection`. Entities, value objects, repository
  interfaces, domain services, use cases all live there.
- **Dependencies point inward only** (CLAUDE.md Section 5.1):
  presentation → application → domain ← data; ml sits behind a domain
  interface. `design_system` imports only `core`.
- **Features are feature-first**: each feature owns
  `application/` + `presentation/{screens,widgets}/` and a public
  barrel. Features never import each other's internals.
- `test/architecture_test.dart` scans import lines and fails CI on
  violations. Never weaken it.

## Consequences

- Domain services (TDEE, MacroPlanner, SafetyGuard, InsightEngine)
  test without Flutter and reach ≥90% coverage.
- Controllers expose `AsyncValue<State>` with explicit
  loading/empty/error/data variants; every screen renders all four.
- Widgets contain no business logic; side effects (navigation,
  snackbars) happen in screen listeners.

## Alternatives considered

- **Bloc** — heavier ceremony for a solo developer; Riverpod's
  provider model fits the app's shape better.
- **Provider (non-Riverpod)** — deprecated upstream.
- **Flutter Navigator 1.0 imperative** — no typed routes, no
  redirect guards; go_router gives deep links for free.
