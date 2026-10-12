# Safety rules and nutrition safety references

> **Status: DRAFT — not yet reviewed.** The constants in
> `app/lib/domain/services/safety_rules.dart` MUST be reviewed with a
> qualified nutrition professional before public release (Section 9.4).
> Do not ship until `lastReviewed` in that file is filled in.

## Rules enforced in the domain layer (SafetyGuard, unit-tested)

| Rule | Value | Where enforced |
|---|---|---|
| Age gate | Under 18: no calorie-deficit or weight-loss targets; maintenance / healthy-habits only | Onboarding + goal setup |
| BMI floor | BMI < 18.5 → no weight-loss goal; tracking only | Goal setup |
| Calorie floor | ~1,200 kcal (women) / ~1,500 kcal (men); planner clamps and explains | MacroPlanner / SafetyGuard |
| Rate cap | Default ≤ 0.5 kg/week; hard cap min(1 kg, 1% body weight)/week | SafetyGuard |
| Medical flags | Pregnancy/breastfeeding, diabetes, kidney disease, eating-disorder history, under medical supervision → no automatic deficit plan; tracking only + "talk to your doctor or a registered dietitian" | Onboarding |
| Low-intake check | Intake far below floor for 3+ consecutive days → calm check-in, not a lecture | InsightEngine |

## Sources to verify before release (Section 17)

These numbers are commonly cited unsupervised floors; confirm against
current national dietary guidance:

- National dietary guidelines (e.g. ICMR-NIN Dietary Guidelines for Indians, 2024)
- WHO / FAO energy requirement reports
- Clinical references on safe weight-loss rates

**Action item (M5):** schedule review with a registered dietitian;
record the review date and any changes in this file and in
`safety_rules.dart`.

## Eating-disorder-aware design (Section 9.4)

- No "earn it / burn it off" framing anywhere in the UI.
- No shaming or red alarms for a single high-calorie meal.
- No celebration of extreme restriction.
- Streaks optional and gentle.
- Option to hide calorie numbers and weight; option to disable weight tracking.
- Never invent helpline numbers; point to "a doctor or a registered dietitian".

## Estimates are labelled estimates

- Food from photos, steps-to-calories, and inferred sleep are
  labelled "estimate" and never presented as measurements.
- Show calorie ranges where the portion is uncertain (Section 8.1).

## Not a medical device (R5)

No diagnosis, treatment or disease claims in code, copy, store
listing or screenshots. Onboarding stores a timestamped
acknowledgement of the "not medical advice" screen.
