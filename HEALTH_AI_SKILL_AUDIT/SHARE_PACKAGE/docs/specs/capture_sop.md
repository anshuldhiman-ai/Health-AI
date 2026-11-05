# Capture SOP — Standard Operating Procedure for Weighed Plates (T1.2)

> **Purpose**: Protocol for collecting ground-truth multi-dish plate photographs paired with scale-weighed item masses for calibration and evaluation of the Health AI vision & mass engine.
> **Schema Reference**: `ml/data/weighed_plates/plates.csv` (AGENTS.md §5.4).

---

## 1. Required Equipment

1. **Digital Kitchen Scale**: Minimum resolution $\le 1\text{ g}$ (tare function required).
2. **Smartphone with Camera & IMU**: Running Android (logs optical axis tilt angle $\theta_{\text{imu}}$).
3. **Reference Containers**:
   - Round ceramic/metal dinner plates (measured diameter, e.g. $26.5\text{ cm}$ or $28.0\text{ cm}$).
   - Katoris / steel bowls (measured rim diameter and depth).
   - Rectangular thali trays (if applicable).

---

## 2. Capture Protocol per Meal

For every meal recorded, perform the following sequence:

### Step 1: Tare & Weighing (Ground Truth Mass)
1. Place container on scale and press **Tare** (zero out tare mass).
2. Add the individual food portion:
   - For Dal: net mass of dal in katori.
   - For Sabzi: net mass in katori or on plate.
   - For Roti / Flatbread: net mass and piece count.
   - For Rice / Carbs: net mass of rice mound.
   - For Salads / Pickles: net mass.
3. Record `net_mass_g` to the nearest $1\text{ g}$.
4. If multi-item on a single plate: weigh each item sequentially onto the plate, recording incremental net weight, or serve from tared serving bowls.

### Step 2: Photography & Perspective Angles
Capture **4 photos per plate**:
1. **Photo 1 (Top-Down)**: $0^\circ \pm 5^\circ$ directly above the center of the plate. Entire plate rim must be visible.
2. **Photo 2 (Slight Tilt)**: $15^\circ \pm 3^\circ$ off-vertical, natural eating perspective.
3. **Photo 3 (Moderate Tilt)**: $30^\circ \pm 3^\circ$ off-vertical (capture HUD warns if $>25^\circ$, useful for tilt-robustness tests).
4. **Photo 4 (Alternative Lighting/Angle)**: Rotated $90^\circ$ or under alternative lighting.

### Step 3: Dataset Diversity Invariants
- $\ge 30\%$ of collected plates must be from restaurants, cafeterias, or non-home utensils.
- Vary lighting conditions: natural daylight, warm incandescent, fluorescent kitchen lighting.
- Include overlapping rotis, mixed curries, and dry sabzis.

---

## 3. CSV Dataset Schema (`ml/data/weighed_plates/plates.csv`)

One row per food item per plate:

| Column | Type | Description | Example |
| :--- | :--- | :--- | :--- |
| `plate_id` | String | Unique plate identifier | `plate_20261101_001` |
| `session_id` | String | Unique meal session identifier | `sess_lunch_01` |
| `image_paths` | String (semicolon-separated) | Relative paths to captured images | `images/p001_top.jpg;images/p001_tilt15.jpg` |
| `imu_tilt_deg` | Float | Tilt angle from phone IMU | `2.4` |
| `plate_type` | String | Container shape (`round_plate`, `rect_tray`, `bowl`) | `round_plate` |
| `plate_diameter_cm` | Float | Measured physical outer rim diameter | `28.0` |
| `container_ids` | String (semicolon-separated) | Sub-container IDs if items are in bowls | `katori_1;katori_2` |
| `item_index` | Integer | Index of item on the plate ($0, 1, 2 \dots$) | `0` |
| `dish_id` | String | Valid `dish_id` from `taxonomy_v1.yaml` | `dal_tadka` |
| `role` | String | Valid 11-role name from `taxonomy_v1.yaml` | `gravy_curry` |
| `net_mass_g` | Float | Net food weight in grams (gross - tare) | `165.0` |
| `piece_count` | Integer / Null | Count for piece-mode foods (rotis, idlis) | `null` |
| `variant` | String | Recipe variant (`home_light_oil`, `home_regular`, `restaurant_rich`) | `home_regular` |
| `lighting` | String | Lighting condition (`daylight`, `warm`, `fluorescent`, `dim`) | `daylight` |
| `notes` | String | Observations (e.g. `ghee on top`, `extra gravy`) | `standard katori fill` |
