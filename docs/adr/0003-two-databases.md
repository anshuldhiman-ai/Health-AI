# ADR 0003: Two databases — read-only nutrition.db, encrypted user.db

## Context

The app needs public food-composition data (thousands of foods,
serving sizes, barcode subset, label→food mapping) and personal
health data (meals, weight, sleep, photos metadata). They have
completely different trust, mutability and size profiles.

## Decision

Two SQLite databases, managed with **drift** + **SQLCipher**
(`sqlcipher_flutter_libs`):

| DB | Contents | Encrypted | Mutable |
|---|---|---|---|
| `nutrition.db` | Public food data | No (public data) | Read-only, shipped as an asset, replaced on app update; version + SHA-256 recorded in a `meta` table and in `docs/model-cards/` |
| `user.db` | Everything personal | **Yes (SQLCipher)** | Key generated on first run (256-bit random), stored via Android Keystore-backed `flutter_secure_storage` |

All timestamps in `user.db` are stored as **UTC epoch millis plus
`tz_offset_min`**, so "which day was this meal" stays stable across
travel and DST.

Foreign keys ON; indices on `eaten_at_utc` and `local_date`; FTS5
search lives in `nutrition.db`. Migrations are append-only (R10).

## Consequences

- A nutrition-data update never touches user data, and only the
  sensitive DB pays the encryption cost.
- Nutrition data quality (per-100g values, sanity checks, licence
  tags) is a build-time concern of
  `ml/scripts/build_nutrition_db.py`, not app code.
- "Delete all my data" wipes `user.db`, photos, secure-storage keys
  and settings in one flow, then restarts onboarding.

## Alternatives considered

- **One encrypted DB for everything** — pays SQLCipher cost on every
  read of public data; couples data updates to user data.
- **Hive/Isar instead of SQLite** — no SQLCipher; weaker story for
  encrypted health data and for FTS search.
- **SharedPreferences for settings** — fine for the small
  `app_setting` table use case; we keep settings in `user.db` so the
  delete-all flow has one place to wipe.
