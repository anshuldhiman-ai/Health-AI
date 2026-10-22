#!/usr/bin/env python
"""Build the app's dish catalog from the Khana label set.

Writes:
  app/assets/models/labels.json      - model output order (sorted classes)
  app/assets/nutrition/khana_catalog.json
      per 100 g energy + macros, key ingredients, serving presets

Nutrition numbers are plausible cooked-dish values for a tracking app
(portion error dominates, so ranges are shown in the UI). They are NOT
lab-measured; replace with IFCT-derived values before shipping to real
users (Section 8.4). One row per Khana class keeps the model, catalog
and UI in sync.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / "app"

# label, display, family, kcal/100g, protein, carbs, fat, ingredients,
# serving preset
ROWS: list[tuple[str, str, str, float, float, float, float, str, str]] = [
    ("aloo gobi", "Aloo Gobi", "curry", 120, 2.9, 12.0, 6.8, "Potato|Cauliflower|Spices", "curry"),
    ("aloo methi", "Aloo Methi", "curry", 118, 3.2, 11.0, 6.5, "Potato|Fenugreek|Spices", "curry"),
    ("aloo mutter", "Aloo Mutter", "curry", 125, 3.8, 14.0, 6.2, "Potato|Peas|Tomato", "curry"),
    ("aloo paratha", "Aloo Paratha", "bread", 260, 5.5, 34.0, 11.0, "Wheat|Potato|Ghee", "paratha"),
    (
        "amritsari kulcha",
        "Amritsari Kulcha",
        "bread",
        280,
        7.0,
        40.0,
        9.5,
        "Wheat|Potato|Ghee",
        "kulcha",
    ),
    ("anda curry", "Anda Curry", "curry", 150, 8.0, 6.0, 11.0, "Egg|Onion|Tomato", "curry"),
    ("balushahi", "Balushahi", "sweet", 450, 5.0, 55.0, 23.0, "Flour|Ghee|Sugar", "sweet"),
    (
        "banana chips",
        "Banana Chips",
        "snacks",
        520,
        3.0,
        58.0,
        31.0,
        "Banana|Coconut oil|Salt",
        "chips",
    ),
    (
        "besan laddu",
        "Besan Laddu",
        "sweet",
        430,
        9.0,
        55.0,
        20.0,
        "Gram flour|Ghee|Sugar",
        "laddoo",
    ),
    ("bhindi masala", "Bhindi Masala", "curry", 110, 2.4, 9.0, 7.5, "Okra|Onion|Spices", "curry"),
    ("biryani", "Biryani", "rice", 190, 5.5, 26.0, 7.0, "Rice|Vegetables|Spices|Ghee", "rice"),
    (
        "boondi laddu",
        "Boondi Laddu",
        "sweet",
        420,
        7.0,
        60.0,
        17.0,
        "Gram flour|Ghee|Sugar",
        "laddoo",
    ),
    ("chaas", "Chaas", "beverage", 40, 2.0, 4.0, 1.2, "Curd|Cumin|Salt", "bev"),
    (
        "chana masala",
        "Chana Masala",
        "curry",
        150,
        7.0,
        20.0,
        5.0,
        "Chickpeas|Onion|Tomato",
        "curry",
    ),
    ("chapati", "Chapati", "bread", 240, 8.0, 46.0, 3.5, "Wheat|Water", "bread"),
    (
        "chicken pizza",
        "Chicken Pizza",
        "pizza",
        250,
        12.0,
        27.0,
        10.0,
        "Chicken|Cheese|Wheat",
        "pizza",
    ),
    (
        "chicken wings",
        "Chicken Wings",
        "snacks",
        290,
        27.0,
        3.0,
        19.0,
        "Chicken|Spices|Oil",
        "wings",
    ),
    ("chikki", "Chikki", "sweet", 480, 10.0, 60.0, 22.0, "Jaggery|Peanuts", "chikki"),
    ("chivda", "Chivda", "snacks", 480, 8.0, 55.0, 25.0, "Rice flakes|Peanuts|Spices", "chips"),
    (
        "chole bhature",
        "Chole Bhature",
        "bread",
        330,
        9.0,
        38.0,
        15.0,
        "Chickpeas|Wheat|Oil",
        "puri",
    ),
    ("dabeli", "Dabeli", "snacks", 220, 5.0, 32.0, 8.0, "Bun|Potato|Spices", "dabeli"),
    ("dal khichdi", "Dal Khichdi", "rice", 130, 5.0, 20.0, 3.5, "Rice|Lentils|Ghee", "rice"),
    ("dhokla", "Dhokla", "snacks", 160, 6.0, 23.0, 4.5, "Gram flour|Curd|Mustard", "dhokla"),
    ("falooda", "Falooda", "sweet", 210, 3.0, 33.0, 7.0, "Milk|Vermicelli|Rose syrup", "kheer"),
    ("fish curry", "Fish Curry", "curry", 140, 13.0, 5.0, 8.0, "Fish|Coconut|Spices", "curry"),
    (
        "gajar ka halwa",
        "Gajar Ka Halwa",
        "sweet",
        330,
        4.5,
        40.0,
        17.0,
        "Carrot|Milk|Ghee|Sugar",
        "halwa",
    ),
    (
        "garlic bread",
        "Garlic Bread",
        "snacks",
        330,
        9.0,
        44.0,
        12.0,
        "Wheat|Garlic|Butter",
        "bread",
    ),
    ("garlic naan", "Garlic Naan", "bread", 320, 8.0, 48.0, 10.0, "Wheat|Garlic|Curd", "naan"),
    ("ghevar", "Ghevar", "sweet", 400, 4.0, 52.0, 20.0, "Flour|Ghee|Sugar", "ghevar"),
    (
        "grilled sandwich",
        "Grilled Sandwich",
        "snacks",
        250,
        7.0,
        30.0,
        11.0,
        "Bread|Vegetables|Cheese",
        "sandwich",
    ),
    ("gujhia", "Gujhia", "sweet", 380, 5.0, 50.0, 17.0, "Flour|Khoya|Sugar", "sweet"),
    (
        "gulab jamun",
        "Gulab Jamun",
        "sweet",
        330,
        4.0,
        48.0,
        14.0,
        "Milk solids|Sugar|Ghee",
        "gulab",
    ),
    (
        "hara bhara kabab",
        "Hara Bhara Kabab",
        "kebab",
        190,
        5.0,
        18.0,
        11.0,
        "Spinach|Peas|Potato",
        "kebab",
    ),
    ("idiyappam", "Idiyappam", "south indian", 150, 3.0, 32.0, 1.0, "Rice|Coconut", "idiyappam"),
    ("idli", "Idli", "south indian", 140, 4.0, 28.0, 1.0, "Rice|Lentils", "idli"),
    ("jalebi", "Jalebi", "sweet", 380, 3.0, 55.0, 16.0, "Flour|Sugar|Ghee", "jalebi"),
    ("kaju katli", "Kaju Katli", "sweet", 480, 9.0, 55.0, 24.0, "Cashew|Sugar|Ghee", "sweet"),
    ("khakhra", "Khakhra", "snacks", 380, 12.0, 60.0, 9.0, "Wheat|Oil|Spices", "khakhra"),
    ("kheer", "Kheer", "sweet", 180, 4.0, 26.0, 6.5, "Rice|Milk|Sugar", "kheer"),
    ("kulfi", "Kulfi", "sweet", 220, 4.5, 24.0, 12.0, "Milk|Sugar|Cardamom", "sweet"),
    (
        "margherita pizza",
        "Margherita Pizza",
        "pizza",
        230,
        9.0,
        26.0,
        9.0,
        "Wheat|Cheese|Tomato",
        "pizza",
    ),
    (
        "masala dosa",
        "Masala Dosa",
        "south indian",
        220,
        5.0,
        28.0,
        9.0,
        "Rice|Lentils|Potato",
        "dosa",
    ),
    ("masala papad", "Masala Papad", "others", 220, 8.0, 24.0, 10.0, "Papad|Onion|Tomato", "papad"),
    ("medu vada", "Medu Vada", "south indian", 280, 7.0, 28.0, 15.0, "Lentils|Onion|Oil", "vada"),
    ("misal pav", "Misal Pav", "snacks", 230, 7.0, 30.0, 9.0, "Sprouts|Bread|Spices", "sprouts"),
    ("modak", "Modak", "sweet", 300, 4.0, 45.0, 11.0, "Rice flour|Coconut|Jaggery", "sweet"),
    (
        "moong dal halwa",
        "Moong Dal Halwa",
        "sweet",
        380,
        6.0,
        45.0,
        19.0,
        "Lentils|Ghee|Sugar",
        "halwa",
    ),
    ("murukku", "Murukku", "others", 500, 8.0, 58.0, 26.0, "Rice flour|Lentils|Oil", "murukku"),
    ("mysore pak", "Mysore Pak", "sweet", 550, 6.0, 52.0, 36.0, "Gram flour|Ghee|Sugar", "sweet"),
    (
        "navratan korma",
        "Navratan Korma",
        "curry",
        180,
        4.0,
        14.0,
        12.0,
        "Vegetables|Cream|Cashew",
        "curry",
    ),
    ("neer dosa", "Neer Dosa", "south indian", 160, 3.0, 32.0, 2.0, "Rice|Coconut", "dosa"),
    (
        "onion pakoda",
        "Onion Pakoda",
        "snacks",
        320,
        6.0,
        30.0,
        19.0,
        "Onion|Gram flour|Oil",
        "pakoda",
    ),
    ("palak paneer", "Palak Paneer", "curry", 180, 8.0, 6.0, 14.0, "Spinach|Paneer|Cream", "curry"),
    (
        "paneer masala",
        "Paneer Masala",
        "curry",
        220,
        9.0,
        8.0,
        17.0,
        "Paneer|Tomato|Cream",
        "curry",
    ),
    (
        "paneer pizza",
        "Paneer Pizza",
        "pizza",
        260,
        12.0,
        27.0,
        11.0,
        "Paneer|Cheese|Wheat",
        "pizza",
    ),
    ("pani puri", "Pani Puri", "chaat", 200, 4.0, 28.0, 8.0, "Wheat|Potato|Tamarind", "snack"),
    (
        "paniyaram",
        "Paniyaram",
        "south indian",
        230,
        5.0,
        30.0,
        9.0,
        "Rice|Lentils|Oil",
        "paniyaram",
    ),
    ("papdi chaat", "Papdi Chaat", "chaat", 220, 5.0, 30.0, 9.0, "Wheat|Curd|Chutney", "snack"),
    (
        "patrode",
        "Patrode",
        "others",
        190,
        4.0,
        28.0,
        7.0,
        "Colocasia leaves|Gram flour|Spices",
        "patrode",
    ),
    (
        "pav bhaji",
        "Pav Bhaji",
        "snacks",
        200,
        4.5,
        24.0,
        9.0,
        "Bread|Vegetables|Butter",
        "pavbhaji",
    ),
    (
        "pepperoni pizza",
        "Pepperoni Pizza",
        "pizza",
        290,
        12.0,
        26.0,
        15.0,
        "Wheat|Cheese|Pepperoni",
        "pizza",
    ),
    ("phirni", "Phirni", "sweet", 190, 4.0, 27.0, 7.0, "Rice|Milk|Sugar", "kheer"),
    ("poha", "Poha", "snacks", 180, 3.5, 30.0, 5.0, "Rice flakes|Peanuts|Spices", "katori"),
    ("pongal", "Pongal", "rice", 160, 4.5, 26.0, 4.5, "Rice|Lentils|Ghee", "katori"),
    ("puri bhaji", "Puri Bhaji", "bread", 300, 5.0, 33.0, 17.0, "Wheat|Potato|Oil", "puri"),
    (
        "rajma chawal",
        "Rajma Chawal",
        "rice",
        150,
        5.0,
        24.0,
        3.5,
        "Kidney beans|Rice|Spices",
        "rice",
    ),
    ("rasgulla", "Rasgulla", "sweet", 240, 4.0, 46.0, 5.0, "Milk solids|Sugar", "rasgulla"),
    (
        "rava dosa",
        "Rava Dosa",
        "south indian",
        210,
        4.0,
        27.0,
        9.0,
        "Semolina|Rice flour|Oil",
        "dosa",
    ),
    (
        "sabudana khichdi",
        "Sabudana Khichdi",
        "fasting",
        230,
        3.0,
        36.0,
        8.0,
        "Sago|Peanuts|Potato",
        "curry",
    ),
    (
        "sabudana vada",
        "Sabudana Vada",
        "fasting",
        330,
        4.0,
        40.0,
        16.0,
        "Sago|Potato|Peanuts",
        "vada",
    ),
    ("samosa", "Samosa", "snacks", 300, 5.0, 32.0, 17.0, "Wheat|Potato|Peas", "samosa"),
    ("seekh kebab", "Seekh Kebab", "kebab", 260, 20.0, 4.0, 19.0, "Chicken|Spices|Oil", "kebab"),
    ("set dosa", "Set Dosa", "south indian", 200, 5.0, 32.0, 6.0, "Rice|Lentils", "dosa"),
    ("sev puri", "Sev Puri", "chaat", 230, 5.0, 30.0, 10.0, "Wheat|Sev|Potato", "snack"),
    ("solkadhi", "Solkadhi", "beverage", 70, 1.0, 6.0, 4.5, "Kokum|Coconut milk|Spices", "bev"),
    (
        "steamed momo",
        "Steamed Momo",
        "snacks",
        160,
        5.0,
        24.0,
        4.5,
        "Flour|Vegetables|Spices",
        "momo",
    ),
    ("thali", "Thali", "others", 160, 5.0, 20.0, 6.0, "Roti|Dal|Rice|Vegetables", "thali"),
    ("thukpa", "Thukpa", "others", 130, 5.0, 18.0, 4.0, "Noodles|Vegetables|Broth", "noodles"),
    ("uttapam", "Uttapam", "south indian", 190, 4.5, 28.0, 6.5, "Rice|Lentils|Onion", "uttapam"),
    ("vada pav", "Vada Pav", "snacks", 290, 6.0, 38.0, 12.0, "Bread|Potato|Spices", "vadapav"),
]

# Serving presets: (label, grams). Portions are the honest range the
# result sheet offers; the first entry is the default.
SERVINGS: dict[str, list[tuple[str, int]]] = {
    "curry": [("1 Katori", 150), ("1 Bowl", 250)],
    "rice": [("1 Katori", 150), ("1 Plate", 350)],
    "bread": [("1 Piece", 60), ("2 Pieces", 120)],
    "paratha": [("1 Piece", 100), ("2 Pieces", 200)],
    "kulcha": [("1 Piece", 90), ("2 Pieces", 180)],
    "naan": [("1 Piece", 90), ("2 Pieces", 180)],
    "puri": [("1 Plate", 300)],
    "sweet": [("1 Piece", 50), ("2 Pieces", 100)],
    "laddoo": [("1 Piece", 40), ("2 Pieces", 80)],
    "gulab": [("2 Pieces", 90)],
    "rasgulla": [("2 Pieces", 100)],
    "jalebi": [("1 Piece", 50), ("2 Pieces", 100)],
    "ghevar": [("1 Piece", 80)],
    "chikki": [("1 Piece", 30)],
    "halwa": [("1 Katori", 100), ("1 Bowl", 180)],
    "kheer": [("1 Katori", 150), ("1 Bowl", 250)],
    "chips": [("1 Handful", 30), ("1 Packet", 100)],
    "bev": [("1 Glass", 200)],
    "snack": [("1 Piece", 80), ("1 Plate", 160)],
    "dhokla": [("2 Pieces", 80), ("4 Pieces", 160)],
    "wings": [("2 Pieces", 100)],
    "sandwich": [("1 Piece", 120)],
    "dabeli": [("1 Piece", 120)],
    "pakoda": [("1 Plate", 100)],
    "khakhra": [("1 Piece", 30)],
    "pizza": [("1 Slice", 100), ("2 Slices", 200)],
    "dosa": [("1 Piece", 120), ("1 Plate", 240)],
    "idli": [("2 Pieces", 90), ("3 Pieces", 135)],
    "vada": [("1 Piece", 60), ("2 Pieces", 120)],
    "idiyappam": [("2 Pieces", 100), ("1 Plate", 200)],
    "paniyaram": [("3 Pieces", 100), ("5 Pieces", 165)],
    "uttapam": [("1 Piece", 150), ("1 Plate", 300)],
    "momo": [("1 Piece", 30), ("1 Plate (6)", 180)],
    "thali": [("1 Thali", 450)],
    "noodles": [("1 Bowl", 300)],
    "papad": [("1 Piece", 20)],
    "murukku": [("1 Piece", 25)],
    "patrode": [("1 Piece", 80)],
    "kebab": [("1 Piece", 70), ("1 Plate", 200)],
    "pavbhaji": [("1 Plate", 300)],
    "sprouts": [("1 Plate", 320)],
    "vadapav": [("1 Piece", 150)],
    "samosa": [("1 Piece", 60), ("2 Pieces", 120)],
    "katori": [("1 Katori", 150), ("1 Bowl", 250)],
    "chivda": [("1 Handful", 30)],
    "gujhia": [("1 Piece", 60)],
    "pesarattu": [("1 Piece", 60), ("2 Pieces", 120)],
}

# Extra rows for classes in the NEW dataset's label set that the
# curated Khana 80 list does not cover. Without them the scan screen
# silently drops a prediction (the catalog lookup returns null).
EXTRA_ROWS: list[tuple[str, str, str, float, float, float, float, str, str]] = [
    (
        "paani puri",
        "Pani Puri",
        "chaat",
        150,
        3.5,
        26.0,
        4.5,
        "Wheat|Onion|Chana|Mango",
        "snack",
    ),
    (
        "dahi papdi chaat",
        "Dahi Papdi Chaat",
        "chaat",
        140,
        5.0,
        20.0,
        4.5,
        "Yogurt|Papdi|Onion|Chutney",
        "snack",
    ),
    (
        "rajma curry",
        "Rajma Curry",
        "curry",
        130,
        6.0,
        18.0,
        3.5,
        "Kidney beans|Onion|Tomato|Spices",
        "curry",
    ),
    (
        "chole",
        "Chole",
        "curry",
        165,
        8.5,
        24.0,
        3.5,
        "Chickpeas|Onion|Tomato|Spices",
        "curry",
    ),
    (
        "pesarattu",
        "Pesarattu",
        "south indian",
        210,
        6.5,
        38.0,
        3.5,
        "Rice|Lentils|Peanut",
        "pesarattu",
    ),
]

LABELS = [row[0] for row in ROWS]


def _row_to_dish(
    label: str,
    display: str,
    family: str,
    kcal: float,
    protein: float,
    carbs: float,
    fat: float,
    ing: str,
    preset: str,
) -> dict[str, object]:
    return {
        "name": display,
        "family": family,
        "ingredients": ing.split("|"),
        "per100g": {
            "kcal": kcal,
            "protein": protein,
            "carbs": carbs,
            "fat": fat,
        },
        "servings": [{"label": name, "grams": grams} for name, grams in SERVINGS[preset]],
    }


def _carry_over(existing_path: Path) -> dict[str, dict[str, object]]:
    """Keep dish rows that are already in the app but not in ROWS.

    The catalog was hand-extended to cover the new dataset's class
    list. Those rows are the only source for their nutrition values, so
    a rebuild must not drop them.
    """
    if not existing_path.is_file():
        return {}
    data = json.loads(existing_path.read_text(encoding="utf-8"))
    rows = data.get("dishes") or {}
    return {k: v for k, v in rows.items() if isinstance(v, dict)}


# --- auto-generated rows -------------------------------------------------
#
# A model class with NO curated row must still get a dish, otherwise
# the scan flow silently drops the prediction. The values below are
# PLAUSIBLE ESTIMATES for a typical serving of the family, never
# lab-measured (Section 8.4). Every auto-generated row is listed in
# the catalog's `autoGenerated` array so a human can review it.

# (family, kcal, protein, carbs, fat, ingredients, serving preset)
_FAMILY_DEFAULTS: dict[str, tuple[float, float, float, float, str, str]] = {
    "curry": (140.0, 6.0, 14.0, 6.0, "Onion|Tomato|Spices", "curry"),
    "bread": (250.0, 6.5, 40.0, 7.0, "Wheat|Ghee", "paratha"),
    "rice": (180.0, 4.0, 30.0, 3.0, "Rice|Vegetables|Spices", "rice"),
    "south indian": (200.0, 5.0, 32.0, 5.0, "Rice|Lentils|Seasoning", "dosa"),
    "snacks": (280.0, 6.0, 34.0, 12.0, "Flour|Potato|Oil", "snack"),
    "chaat": (160.0, 4.5, 22.0, 5.0, "Chickpeas|Onion|Chutney", "snack"),
    "sweet": (420.0, 5.0, 60.0, 18.0, "Sugar|Ghee|Flour", "sweet"),
    "beverage": (70.0, 1.5, 12.0, 2.0, "Milk|Tea|Sugar", "bev"),
    "kebab": (230.0, 12.0, 12.0, 15.0, "Minced meat|Spices", "kebab"),
    "pizza": (265.0, 11.0, 33.0, 10.0, "Wheat|Cheese|Tomato", "pizza"),
    "fasting": (120.0, 3.0, 20.0, 2.5, "Potato|Curd|Spices", "curry"),
    "others": (180.0, 6.0, 24.0, 6.0, "Seasonal vegetables|Spices", "thali"),
}

# Keyword -> family, checked in order against the class id.
_FAMILY_KEYWORDS: tuple[tuple[tuple[str, ...], str], ...] = (
    (("dal", "sambar", "rasam", "chana", "rajma", "chole", "korma", "masala"), "curry"),
    (("roti", "paratha", "naan", "kulcha", "bread", "puri", "bhature", "toast", "pita"), "bread"),
    (("biryani", "rice", "pulao", "khichdi", "porridge"), "rice"),
    (("dosa", "idli", "vada", "uttapam", "idiyappam", "rasam", "chutney", "bisi"), "south indian"),
    (
        (
            "laddu",
            "ladoo",
            "halwa",
            "jalebi",
            "rasgulla",
            "gulab",
            "barfi",
            "kulfi",
            "kheer",
            "payasa",
        ),
        "sweet",
    ),
    (("tea", "coffee", "chai", "juice", "lassi", "sherbet", "drink"), "beverage"),
    (("kebab", "tikka", "tandoori", "grill"), "kebab"),
    (("pizza", "pasta", "noodle"), "pizza"),
    (
        ("samosa", "pakora", "bhaji", "chaat", "puri", "dahi", "pani puri", "chana", "chole"),
        "chaat",
    ),
    (("sandwich", "burger", "roll", "wrap", "toast", "omelette", "chips"), "snacks"),
    (("kulfi", "falooda", "shake"), "sweet"),
    (("fasting", "vrat", "sabudana"), "fasting"),
)


def _guess_family(label: str) -> str:
    words = label.replace("-", " ").lower()
    for keywords, family in _FAMILY_KEYWORDS:
        if any(word in words for word in keywords):
            return family
    return "others"


def _display_name(label: str) -> str:
    """`aloo gobi` -> `Aloo Gobi` (title case, dashes to spaces)."""
    parts = [p for p in label.replace("-", " ").split() if p]
    return " ".join(p if p.isupper() else p.capitalize() for p in parts)


def _auto_row(label: str) -> dict[str, object]:
    family = _guess_family(label)
    kcal, protein, carbs, fat, ingredients, preset = _FAMILY_DEFAULTS[family]
    return _row_to_dish(
        label,
        _display_name(label),
        family,
        kcal,
        protein,
        carbs,
        fat,
        ingredients,
        preset,
    )


def _read_class_list(path: Path) -> list[str]:
    """The model's class order (the app indexes the model output by it)."""
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list) or not data:
        raise SystemExit(f"error: {path} is not a non-empty list of class names")
    if not all(isinstance(c, str) and c for c in data):
        raise SystemExit(f"error: {path} must contain only non-empty strings")
    if len(set(data)) != len(data):
        dupes = sorted({c for c in data if data.count(c) > 1})
        raise SystemExit(f"error: {path} has duplicate class names: {dupes}")
    return list(data)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--classes",
        type=Path,
        default=None,
        help=(
            "classes.json (the model's class order, e.g. ml/data/classes.json). "
            "When given, the catalog's class list is exactly this list, in "
            "this order, and every class gets a dish."
        ),
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=None,
        help="where to write the catalog (default: the app asset)",
    )
    args = parser.parse_args()

    catalog_path = args.out or (APP / "assets" / "nutrition" / "khana_catalog.json")

    dishes: dict[str, dict[str, object]] = {}
    for label, display, family, kcal, protein, carbs, fat, ing, preset in ROWS:
        dishes[label] = _row_to_dish(label, display, family, kcal, protein, carbs, fat, ing, preset)
    for label, display, family, kcal, protein, carbs, fat, ing, preset in EXTRA_ROWS:
        dishes.setdefault(
            label,
            _row_to_dish(label, display, family, kcal, protein, carbs, fat, ing, preset),
        )

    # Carry over rows that only exist in the shipped catalog.
    carried = _carry_over(catalog_path)
    added = 0
    for label, row in carried.items():
        if label not in dishes:
            dishes[label] = row
            added += 1

    auto_generated: list[str] = []

    if args.classes is not None:
        # The model indexes its output by THIS order, so the catalog's
        # class list must be exactly it.
        classes = _read_class_list(args.classes)
        for label in classes:
            if label not in dishes:
                dishes[label] = _auto_row(label)
                auto_generated.append(label)
        # Classes the model does not know are dropped from the catalog:
        # keeping them would make the class list disagree with the
        # model's output.
        for label in list(dishes):
            if label not in set(classes):
                del dishes[label]
    else:
        # No class list: the class list is the SORTED, DEDUPLICATED
        # union of every class with a dish.
        classes = sorted(dishes)

    catalog = {
        "version": 3,
        "source": (
            "Khana 80-class label set plus the new dataset's class list; "
            "plausible cooked-dish values (NOT lab-measured)"
        ),
        "classes": classes,
        "dishes": dishes,
        "autoGenerated": sorted(auto_generated),
    }

    catalog_path.parent.mkdir(parents=True, exist_ok=True)
    catalog_path.write_text(
        json.dumps(catalog, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"catalog: {catalog_path} ({len(dishes)} dishes, {len(classes)} classes)")
    print(f"  carried over {added} existing rows")
    if auto_generated:
        print(f"  auto-generated {len(auto_generated)} rows (review these):")
        for label in sorted(auto_generated):
            print(f"    {label}")
    print(
        "  NOTE: labels.json is NOT written here. It must come from the "
        "model's class order (export_onnx2tf.py --classes ...)."
    )


if __name__ == "__main__":
    main()
