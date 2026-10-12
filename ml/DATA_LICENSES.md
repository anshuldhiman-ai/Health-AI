# Data licences

> **Status: M0 draft.** Record every dataset BEFORE downloading or
> using it: URL, licence text, date accessed, what use it permits
> (research vs commercial), attribution required (Section 8.2).

## Planned datasets

| Dataset | What it is | Licence (verify before use) | Date accessed | Permitted use | Attribution |
|---|---|---|---|---|---|
| Khana (arXiv 2509.06006) | ~131K images, 80 Indian-dish labels | **check paper + site** | ☐ | ☐ | ☐ |
| Kaggle "Indian Food Classification" (l33tc0d3r) | Smaller Indian dish set | **check dataset licence** | ☐ | ☐ | ☐ |
| IndianFoodNet | ~5.5K images, 30 classes, detection annotations | **check paper/site** | ☐ | ☐ | ☐ |
| Food-101 | 101K images, 101 classes | **check terms** | ☐ | ☐ | ☐ |
| UEC-FOOD256 | 256 categories, bounding boxes, Japan-centric | **check terms** | ☐ | ☐ | ☐ |
| Nutrition5k (Google Research) | Plates with measured weights/nutrition + depth | **check licence** | ☐ | research only | ☐ |
| Non-food images (COCO / Open Images subsets) | Negatives for `not_food` | **check terms** | ☐ | ☐ | ☐ |
| Self-collected phone photos | Real conditions; the biggest accuracy lever | Own consent protocol (Section 8.3) | ☐ | ✓ | n/a |

## Hard rules

- **NEVER scrape Google Images, Instagram, Zomato, Swiggy or recipe
  sites for training images** (copyright and ToS).
- If a licence forbids commercial use and the app might ever be
  monetised, either exclude it or use it only for experiments —
  never for the shipped model.
- Pretrained backbone weights carry licences too (some are
  non-commercial or research-only). Log the exact weights in the
  model card.
- Datasets are gitignored; they are versioned with DVC against a
  private remote.

## Self-collection protocol (Section 8.3)

- 300+ photos per class for the 40 most common classes, 100+ for
  the rest. Adjust after error analysis.
- Written/recorded consent from anyone whose meals or surroundings
  appear; no faces, no personal documents in frame; strip EXIF GPS.
- Diversity on purpose: lighting, angles, containers, partly eaten,
  mixed plates, different phones.
- Per-image metadata CSV: `class, photographer_id, device,
  session_id, setting, date`.
- **Splits are by `photographer_id`/`session_id`, never random by
  image** — otherwise near-duplicate photos leak into validation.
- Golden test set: ≥50 real phone photos per class from people NOT
  in the training pool. Frozen, versioned, never used for tuning.
