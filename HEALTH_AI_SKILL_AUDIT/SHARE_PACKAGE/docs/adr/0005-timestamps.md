# ADR 0005: Timestamps as UTC epoch millis + tz_offset_min

## Context

Diary entries, workouts, sleep and weight logs must answer "which
local day did this happen on" correctly when the user travels across
time zones or when DST shifts. Storing a local date alone makes
day-boundary logic ambiguous; storing only UTC loses the user's
local context.

## Decision

Every user-facing timestamp in `user.db` is stored as:

- `…_utc` — UTC epoch milliseconds, and
- `tz_offset_min` — the offset from UTC at the time of the event
  (e.g. `330` for IST).

The single authority for "which local day is this" is the
`DayBoundary` domain service (CLAUDE.md Section 6.5); nothing else
computes day boundaries. Domain and data code never calls
`DateTime.now()` directly — they go through the `Clock` abstraction so
tests can control time.

## Consequences

- Reconciliation across reboot/midnight/time-zone changes (M4) has a
  single, testable rule.
- Queries for "today" join on the computed local date, which is
  derived deterministically from the stored pair.
- DST edge cases (ambiguous/repeated local times) are handled in
  `DayBoundary` with documented, tested behaviour.

## Alternatives considered

- **Store local datetime only** — breaks on travel; can't re-derive
  UTC.
- **Store ISO-8601 strings** — larger, slower to query, and still
  needs the offset; epoch millis is what Health Connect and sensors
  natively use.
