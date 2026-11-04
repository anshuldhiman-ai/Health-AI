# ADR 0009: Offline 24/7 step capture via WorkManager + the hardware step counter

- Status: Accepted
- Date: 2026-11-04
- Supersedes nothing. Extends ADR 0008 (permissions) and ADR 0005
  (timestamps / day boundaries).

## Context

Steps must be recorded all day even when the app is closed, never
launched that day, or killed from recents, and the hour-by-hour
breakdown has to be right. The previous implementation only counted
while a Dart sensor listener was alive, and it deliberately dropped any
movement that happened while the app was not running, so a phone left in
a pocket recorded nothing.

Two facts constrain the design:

1. `TYPE_STEP_COUNTER` is a **hardware** sensor. It keeps counting with
   the app dead, the screen off and the device in a pocket. Reading it
   needs no network and no foreground service.
2. No Dart code runs when the Flutter engine is not alive, so something
   scheduled by the OS has to sample that counter on our behalf.

Health Connect was the obvious alternative source: it aggregates and
de-duplicates steps from any wearable the user already owns. It was
rejected for this change because it adds Health Connect read permissions
and a Play Console health-data declaration, and it cannot be verified
without a physical device — neither of which is needed to satisfy the
requirement.

## Decision

**Sample the hardware counter from a periodic `WorkManager` job; merge
the samples into the existing ledger on the next launch.**

- `androidx.work:work-runtime-ktx:2.10.5` (Apache-2.0) registers one
  unique periodic job, `health_ai_step_capture`, at the WorkManager
  minimum of 15 minutes, `ExistingPeriodicWorkPolicy.KEEP` so a cold
  start does not reset the schedule.
- `StepCaptureWorker` (Kotlin) checks `ACTIVITY_RECOGNITION`, reads the
  cumulative counter once through `StepSensorReader`, and appends
  `{t, s, e}` — wall-clock millis, sensor steps,
  `SystemClock.elapsedRealtime()` — to a SharedPreferences ring buffer
  (`StepSnapshotStore`). Retention 8 days, 1200 samples, `commit()` not
  `apply()` because the worker may be stopped the moment `doWork()`
  returns.
- The readings live in **app-private** storage, are never uploaded, and
  contain only step counts and timestamps.
- A `MethodChannel('health_ai/steps_background')` exposes `schedule`,
  `drain` and `collectNow`. Readings are **never cleared** on the native
  side: the Dart ledger holds a cursor and discards duplicates, which
  stays correct if the process dies between drain and save.
- `ActivityLedger.record` apportions the delta between two readings
  across every clock hour and local day the interval spans, using
  largest-remainder integer apportionment so the buckets sum to exactly
  the measured delta. A gap longer than two hours flags those steps as
  `reconciledSteps`; the daily total is measured, only its placement
  inside the gap is an estimate, and the UI says so.
- The sensor cursor **survives midnight** so a reading that straddles
  the boundary is split rather than dropped or dumped into one day.

### Why not the alternatives

- **A foreground service** — reliable, but it needs a persistent
  notification, burns battery, and triggers Play foreground-service
  policy review. Explicitly out of scope (CLAUDE.md §6.6).
- **`AlarmManager` exact alarms** — needs `SCHEDULE_EXACT_ALARM`, which
  is forbidden in v1 (ADR 0008).
- **`RECEIVE_BOOT_COMPLETED` + a custom receiver** — WorkManager already
  persists its job through `JobScheduler` across reboots; a hand-rolled
  receiver adds surface for no gain.
- **Health Connect as the primary source** — see Context. It remains the
  right answer for a future milestone that wants wearable data.

## New permissions

WorkManager's manifest contributes three permissions. All were verified
in the **merged release** manifest and added to the allow-list in
`tools/check_manifest.sh`:

| Permission | Why | Network? |
|---|---|---|
| `WAKE_LOCK` | Hold the CPU for the few ms the worker reads the sensor | No |
| `RECEIVE_BOOT_COMPLETED` | Declared by work-runtime so the platform can reschedule | No |
| `FOREGROUND_SERVICE` | Declared by work-runtime; the service it guards is disabled by default (`enable_system_foreground_service_default`) and is never started here | No |

`INTERNET` and `ACCESS_NETWORK_STATE` are still removed with
`tools:node="remove"` and the script still fails if either appears.
Verified on the release APK: only the allow-listed set is present.

## Consequences

- Steps are recorded all day with the app closed. A phone that walks
  5,000 steps between two app launches shows those 5,000 steps, split
  across the hours they happened in.
- **Honest limits, stated in the UI copy and not papered over:**
  - WorkManager's 15-minute cadence is best-effort. Doze and OEM battery
    managers (Xiaomi, Oppo, Vivo, Samsung) can defer a job for hours, so
    the hour split inside a deferred gap is an interpolation.
  - A user **Force stop** from Settings suspends all background work
    until the app is launched again. No app can work around this.
  - A **reboot** resets the hardware counter. Steps taken between the
    last sample and the reboot are not recoverable, because the counter
    they were derived from no longer exists. The ledger detects the
    reset via a backwards `elapsedRealtime` and re-anchors instead of
    subtracting a negative delta.
- The Android system's own step aggregation is not used, so the count is
  this device's counter, not a cross-device total.

## Verification

- Unit: `test/domain/services/activity_ledger_test.dart` covers backlog
  attribution across days, cross-midnight splits, duplicate/stale
  samples, reboot re-anchoring and the reconciled flag (29 tests).
- Widget: `test/features/activity/activity_screen_test.dart` covers the
  day/week charts and the history replay.
- Build: release APK builds; `tools/check_manifest.sh` passes.
- **Not yet verified on a physical device.** There is no Android device
  or emulator available in this environment, so the killed/backgrounded
  and reboot paths have not been exercised on real hardware. This must
  be done before release (Section 12.4).
