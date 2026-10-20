# ML Scripts

This directory contains Python scripts for building datasets, training models, and generating assets for the mobile app.

## Scripts Overview

### build_dish_catalog.py
Builds the app's dish catalog from the Khana label set.

**Outputs:**
- `app/assets/models/labels.json` - Model output order (sorted classes)
- `app/assets/nutrition/khana_catalog.json` - Per 100g energy + macros, key ingredients, serving presets

**Current Catalog Version:** 2.0 (200+ dishes)

**Catalog Coverage:**
The nutrition catalog now includes 200+ Indian dishes covering various cuisines:

- **Dal Varieties:** Toor dal, Moong dal, Masoor dal, Urad dal, Chana dal, Dal makhani, Dal tadka, Pindi chana, Rajma, Lobhia, Palak dal, Methi dal
- **Paneer Dishes:** Paneer butter masala, Paneer tikka, Kadai paneer, Shahi paneer, Paneer do pyaza, Matar paneer, Methi malai paneer, Paneer kofta, Palak paneer, Paneer masala
- **Chicken Curries:** Chicken tikka masala, Butter chicken, Chicken korma, Chilli chicken, Chicken saagwala, Tandoori chicken, Chicken rezala, Afghani chicken
- **Mutton/Lamb:** Mutton rogan josh, Mutton korma, Mutton biryani, Mutton seekh kebab, Keema matar, Keema curry
- **Seafood:** Prawn curry, Crab curry, Fish curry, Fish fry, Fish tikka
- **Egg Dishes:** Egg curry, Egg bhurji, Anda curry
- **Roti/Paratha Varieties:** Paratha, Laccha paratha, Methi paratha, Gobi paratha, Mooli paratha, Paneer paratha, Pudina paratha, Chapati, Tandoori roti, Rumali roti, Missi roti, Makki roti, Bathua roti, Bajra roti, Jowar roti, Naan, Kulcha, Poori, Bhatura, Amritsari kulcha, Garlic naan
- **Rice Dishes:** Biryani, Pulao, Jeera rice, Veg pulao, Kashmiri pulao, Coconut rice, Lemon rice, Tamarind rice, Curd rice, Tomato rice, Ghee rice, Veg fried rice, Khichdi, Dal khichdi, Rajma chawal, Pongal, Kadi chawal, Puliogare, Bisi bele bath, Vangi bath, Tomato bath
- **Breakfast Items:** Upma, Dalia, Cornflakes, Oats porridge, Besan chilla, Moong dal chilla, Suji halwa, Sheera, Semiya upma, Poha, Idli, Dosa varieties (Masala, Rava, Set, Neer, Aval, Moong dal), Appam, Puttu, Pesarattu, Uttapam, Paniyaram, Idiyappam
- **Snacks:** Samosa, Kachori, Mathri, Namak pare, Shakar pare, Papad, Bhel puri, Dahi vada, Mirchi vada, Dahi kachori, Aloo tikki, Onion pakoda, Dhokla, Khandvi, Muthiya, Thepla, Fafda, Khakhra, Chivda, Chikki, Banana chips, Garlic bread, Grilled sandwich, Dabeli, Pav bhaji, Misal pav, Vada pav, Medu vada, Sabudana vada, Patrode, Murukku, Steamed momo
- **Sweets:** Gulab jamun, Rasgulla, Jalebi, Kaju katli, Besan laddu, Boondi laddu, Gajar ka halwa, Moong dal halwa, Kheer, Phirni, Kulfi, Falooda, Rasmalai, Sandesh, Shrikhand, Rabri, Malpua, Imarti, Balushahi, Ghevar, Ghewar, Gujhia, Modak, Mysore pak, Chikki, Anarsa, Pitha, Rasabali, Chhena poda, Chhena gaja, Poda pitha, Enduri pitha, Payasam, Sakkarai pongal, Suji halwa, Sheera
- **Beverages:** Chaas, Lassi (various flavors), Badam milk, Thandai, Masala chai, Adrak chai, Elaichi chai, Filter coffee, Coconut water, Sugarcane juice, Jaljeera, Amla juice, Solkadhi
- **Chaat:** Pani puri, Sev puri, Papdi chaat, Dahi papdi chaat, Bhel puri
- **Kebabs:** Seekh kebab, Hara bhara kabab, Mutton seekh kebab, Chicken reshmi kebab, Galouti kebab, Shami kebab, Kalmi kebab
- **Curries/Sabzi:** Aloo gobi, Aloo methi, Aloo mutter, Bhindi masala, Chana masala, Navratan korma, Palak paneer, Baingan bharta, Brinjal curry, Eggplant masala, Pumpkin sabzi, Kaddu ki sabzi, Arbi ki sabzi, Suran ki sabzi, Matar ki sabzi, Mushroom curry, Soya chunks curry, Soya keema, Aloo matar, Aloo pyaz, Aloo tamatar, Dum aloo, Aloo jeera, Jeera aloo, Gobi matar, Gobi masala, Mushroom masala, Karela sabzi, Tinda sabzi, Lauki ki sabzi, Torai ki sabzi, Parwal ki sabzi, Drumstick curry, Kadhi pakora, Kadhi, Sambhar, Rasam
- **Regional Specialties:**
  - **Gujarati:** Dhokla, Khandvi, Muthiya, Thepla, Fafda, Fafda jalebi
  - **Maharashtrian:** Misal pav, Puran poli (future), Modak
  - **Bengali:** Sandesh, Rasgulla, Ras malai, Chhena poda, Chhena gaja, Pitha, Rasabali
  - **South Indian:** Idli, Dosa, Vada, Uttapam, Paniyaram, Appam, Puttu, Pesarattu, Idiyappam, Sambhar, Rasam, Payasam, Bisi bele bath, Puliogare, Vangi bath, Tomato bath, Adai, Aval dosa, Moong dal dosa
  - **Rajasthani:** Dal baati (future), Ghevar, Ghewar
  - **Punjabi:** Sarson ka saag (future), Makki roti, Dal makhani, Paneer dishes
  - **North Indian:** Various parathas, Dal tadka, Rajma, Kadhi
  - **Fasting Foods:** Sabudana khichdi, Sabudana vada

**Nutrition Data Notes:**
- All values are per 100g
- Calories (kcal), protein (g), carbohydrates (g), fat (g)
- Values are plausible estimates for Indian cooking methods
- Restaurant-style dishes often have higher oil/ghee content
- Home-cooked versions are moderate in fat
- Values are NOT lab-measured; replace with IFCT-derived values before production
- Portion error dominates tracking accuracy, so ranges are shown in the UI

**Serving Sizes:**
Each dish includes realistic serving size presets:
- Curries: 1 Katori (150g), 1 Bowl (250g)
- Rice dishes: 1 Katori (150g), 1 Plate (350g)
- Breads: 1 Piece (60-90g), 2 Pieces (120-180g)
- Sweets: 1 Piece (40-60g), 2 Pieces (80-120g)
- Snacks: Various appropriate portion sizes
- Beverages: 1 Glass (200-250ml), 1 Cup (120-150ml)

**Usage:**
```bash
cd ml/scripts
python build_dish_catalog.py
```

This will regenerate both `labels.json` and `khana_catalog.json` with the current ROWS definition.

### prepare_dataset.py
Prepares the training dataset from raw images and annotations.

### train.py
Trains the food classification model.

### export_tflite.py
Exports the trained model to TFLite format for on-device inference.

### test_model.py
Tests the exported model on a validation set.

### make_splits.py
Creates train/validation/test splits from the dataset.

### compare_checkpoints.py
Compares model checkpoints to select the best performing model.

## Data Flow

1. Raw images → `prepare_dataset.py` → Processed dataset
2. Processed dataset → `train.py` → Trained model checkpoints
3. Checkpoints → `export_tflite.py` → TFLite model
4. TFLite model + catalog → `app/assets/` → Mobile app

## Important Notes

- Nutrition values are estimates for tracking purposes
- Always verify with lab data before production use
- The catalog is versioned; update the version number when making changes
- Keep the ROWS definition in sync with the model's class labels
- All classes must be sorted alphabetically for consistent model output
