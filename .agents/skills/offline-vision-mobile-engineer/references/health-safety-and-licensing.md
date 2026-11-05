# Health, nutrition, and licensing boundaries

## Health and nutrition safety

A wellness tracker is not automatically a medical device, but its recommendations can still affect users.

- Do not diagnose, treat, or claim to prevent disease.
- Do not create individualized clinical nutrition advice without qualified oversight.
- Treat calorie, macro, sleep, step, and portion values as estimates where appropriate.
- Show assumptions and uncertainty.
- Avoid shame, punishment, or celebration of extreme restriction.
- Provide safe fallback and user control.
- Escalate clinical thresholds, age rules, pregnancy, chronic disease, and eating-disorder safeguards to qualified professionals.
- Never claim safety thresholds were clinically reviewed unless a dated review record exists.

## Dataset and model licensing

Audit each item independently:

1. Source code
2. Third-party runtime libraries
3. Pretrained model weights
4. Training datasets
5. Annotation tools and generated labels
6. Derived model weights
7. Nutrition/food composition data
8. Fonts, icons, images, and other assets

Record license, attribution, commercial-use permission, redistribution permission, and any non-commercial/no-derivatives restrictions.

If a dataset's terms are unknown or restrict commercial use, do not assume the resulting weights can be shipped commercially. Keep research-only artifacts separate from production artifacts.

## Skill-package distribution

A reusable skill should contain original instructions and generic examples. Do not include:

- User data or private records
- Model weights/checkpoints
- Datasets or copyrighted catalogs
- Secrets, certificates, tokens, or credentials
- Whole application source trees
- Third-party material without redistribution rights

Summarize patterns and cite repository paths for the owner's own private workflow instead.
