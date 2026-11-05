# UI/UX review — status and what is left

The reference is `ref_ui.png` (and the per-screen crops in
`ref_crops/`). Screens are reviewed by rendering them to PNG with
`test/ui_screens_test.dart` — a widget test that only asserts "no
exception" cannot tell you that a screen looks cheap.

```bash
cd app
RUN_UI_GOLDENS=1 flutter test test/ui_screens_test.dart --update-goldens
# then open test/goldens/ui/*.png
```

The PNGs are a human visual baseline, not a CI gate: font rasterising
differs per platform. The test skips itself unless `RUN_UI_GOLDENS=1`.

---

## Fixed in this pass

| Area | Before | After |
|---|---|---|
| **Nav dock** | Scan disc floated in the bottom-right, next to a dead 64px gap | Scan disc centred and **docked into** the bar (white ring cuts a notch) — every screen |
| **Cards** | Heavy grey drop shadow, every card a floating blob | Flat white surface + hairline edge, barely-there depth |
| **Buttons** | Stadium pills | Rounded rectangles (14) |
| **Stat tiles** | Bare square icon | Glyph in a filled circle |
| **Today** | No "Today's Meals" section; the screen ended in a large empty canvas | "Today's Meals" section with an Add Food chip; date + bell header row; compact hero card |
| **Insights** | Chart axis on the **right**, a **negative** calorie axis (−200), no day labels, stray fill edge | Calories on the left, floor at 0, `Fri 16 / Sat 17 …` day labels, range chips sized to content |
| **Profile** | Three separate shadowed cards | One grouped surface with hairline dividers |
| **Typography** | Diary "Add Food" label, chart tooltip and meal chips fell back to the **system font** (Roboto) | All carry the brand family |
| **Meter bars** | Thick grey pills | Thin rules with a coloured fill |

---

## Still to do

### 1. Empty states read as "broken", not "empty" — **high impact**
Every meter, ring and chart is at 0% with no data, so a first-run
user sees a big grey donut and three blank rules. The reference shows
populated data, so the empty state was never designed.

- Give the calorie ring a soft `primaryWash` track instead of a heavy
  grey donut.
- Consider an explicit "no data yet" variant of the hero card rather
  than a ring at 0%.
- Insights: hide the chart and show a short empty state until there
  are two or more logged days.

### 2. Scan and Search screens were never reviewed — **high impact**
`ref_crops/scan.png` shows the result sheet: photo thumbnail, top-3
rows with confidence chips, serving-size selector, a calorie range
callout, and a full-width confirm button. Check the current scan
sheet against it, and check `/search` (which has no reference crop).

### 3. The reference has screens the app does not — **medium**
- Splash screen (`ref_crops/welcome.png` is labelled "Splash Screen" —
  the app opens straight on the welcome page).
- Onboarding/profile setup beyond the "Sign In" note.
- Activity screen (`/activity`) has no reference crop.
- Water and Sleep screens have no reference crops.

### 4. Dark mode was never checked — **medium**
`AppColors.dark` exists and every token has a dark value, but no
screenshot has been reviewed in dark mode. Render the goldens with
`themeMode: dark` and compare.

### 5. Micro-interaction and motion — **low**
- The nav bar's active icon changes instantly. The reference implies
  a soft cross-fade.
- No pressed/haptic feedback on the nav destinations.
- The calorie ring and the trend chart animate in from 0 with no
  stagger, so the first frame of the dashboard is empty for a moment.

### 6. Content and copy — **low**
- The profile shows "Anshul" and "Your data stays on this device."; the
  reference shows a full name and an email.
- "Weekly Progress" on Insights is a stub row that the reference does
  not have; the reference's Insights is Calorie Trend + Nutrition
  Balance only.
- The `Start your day` banner is app-specific (not in the reference)
  and takes a lot of vertical space for an empty state.

### 7. Accessibility pass — **medium**
- Text scaling to 200% has not been reviewed on any screen. The
  dashboard has a fixed-height hero card; large text will overflow.
- The meal-kind chips and range chips need to be checked against the
  48dp touch target rule (R14).
- Contrast of `inkMuted` on `canvas` has not been measured for the
  small captions.

---

## Non-negotiables that are easy to break

- **R13** no hard-coded user-facing string — every new label goes in
  the ARB files (`lib/l10n/app_en.arb`, `_hi`, `_pa`).
- **R14** 48dp touch targets, WCAG AA contrast, TalkBack labels.
- A raw `TextStyle` **replaces** the theme style. Always start from
  `AppTypography.*` so the brand family is kept.
