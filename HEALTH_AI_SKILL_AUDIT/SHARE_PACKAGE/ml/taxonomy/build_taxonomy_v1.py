#!/usr/bin/env python3
"""Build taxonomy_v1.yaml mapping 239 classes from labels.json to 11 roles and ~40 groups (T1.1)."""

import json
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
CLASSES_PATH = REPO_ROOT / "ml" / "data" / "classes.json"
OUT_PATH = REPO_ROOT / "ml" / "taxonomy" / "taxonomy_v1.yaml"

# 11 Roles from AGENTS.md §5.1 (Fixed order, 0 to 10)
ROLES = [
    {"id": 0, "name": "background"},
    {"id": 1, "name": "plate_tray"},
    {"id": 2, "name": "bowl"},
    {"id": 3, "name": "mounded_carb"},
    {"id": 4, "name": "flat_bread"},
    {"id": 5, "name": "gravy_curry"},
    {"id": 6, "name": "dry_sabzi"},
    {"id": 7, "name": "salad_raw"},
    {"id": 8, "name": "condiment"},
    {"id": 9, "name": "protein_piece"},
    {"id": 10, "name": "other_food"},
]


# Mapping rules from raw class name to (role, group, measure_mode, default_serving_g)
def classify_dish(name):
    # Condiments
    if name in ["achar"]:
        return "condiment", "pickle_achar", "volume", 20
    if name in ["solkadhi"]:
        return "condiment", "beverage", "volume", 150

    # Flatbreads
    if name in ["aloo paratha", "paratha"]:
        return "flat_bread", "paratha", "piece", 80
    if name in ["amritsari kulcha"]:
        return "flat_bread", "naan_kulcha", "piece", 90
    if name in [
        "appam",
        "idiyappam",
        "neer dosa",
        "set dosa",
        "masala dosa",
        "rava dosa",
        "uttapam",
    ]:
        return "flat_bread", "dosa_cheela", "piece", 90
    if name in ["besan cheela"]:
        return "flat_bread", "dosa_cheela", "piece", 75
    if name in ["bhatura"]:
        return "flat_bread", "puri_bhatura", "piece", 60
    if name in ["aloo puri", "daal puri", "puri bhaji"]:
        return "flat_bread", "puri_bhatura", "piece", 50
    if name in ["butter naan", "garlic naan", "naan", "naan bread"]:
        return "flat_bread", "naan_kulcha", "piece", 80
    if name in ["chapati", "misi roti", "missi roti", "makki di roti sarson da saag"]:
        return "flat_bread", "roti_chapati", "piece", 35
    if name in ["papad", "masala papad", "khakhra"]:
        return "flat_bread", "papad_crisp", "piece", 15
    if name in ["toast", "bagels", "garlic bread"]:
        return "flat_bread", "western_bread", "piece", 40

    # Gravy / Curry
    if name in ["dal tadka", "dal makhani", "chana masala", "rajma", "rajma chawal"]:
        return "gravy_curry", "dal", "volume", 150
    if name in ["kadhi pakoda"]:
        return "gravy_curry", "kadhi_curd_curry", "volume", 150
    if name in ["anda curry"]:
        return "gravy_curry", "egg_curry", "volume", 160
    if name in ["butter chicken", "chicken razala", "chicken rezala", "chicken tikka masala"]:
        return "gravy_curry", "chicken_curry", "volume", 180
    if name in ["fish curry", "maach jhol"]:
        return "gravy_curry", "fish_curry", "volume", 180
    if name in [
        "palak paneer",
        "paneer butter masala",
        "paneer masala",
        "kadai paneer",
        "navratan korma",
        "kofta",
    ]:
        return "gravy_curry", "paneer_gravy", "volume", 160
    if name in ["misal pav", "pav bhaji"]:
        return "gravy_curry", "street_curry", "volume", 180

    # Dry Sabzi
    if name in [
        "aloo gobi",
        "aloo matar",
        "aloo methi",
        "aloo shimla mirch",
        "dum aloo",
        "canned potatoes",
        "chilli potato",
    ]:
        return "dry_sabzi", "dry_potato_sabzi", "volume", 140
    if name in ["baingan bharta", "karela bharta", "stuffed karela"]:
        return "dry_sabzi", "dry_gourd_eggplant", "volume", 130
    if name in ["bhindi masala"]:
        return "dry_sabzi", "dry_green_sabzi", "volume", 120
    if name in [
        "cabbage",
        "capsicum",
        "cauliflower",
        "peas",
        "spinach",
        "shelled soy bean",
        "sprouts",
        "patrode",
    ]:
        return "dry_sabzi", "dry_vegetable_sabzi", "volume", 120

    # Mounded Carbs
    if name in ["biryani", "fried rice"]:
        return "mounded_carb", "biryani_pulao", "volume", 220
    if name in ["rice cooked"]:
        return "mounded_carb", "steamed_rice", "volume", 150
    if name in ["dal khichdi", "khichdi", "pongal", "sabudana khichdi"]:
        return "mounded_carb", "khichdi_pongal", "volume", 200
    if name in ["poha"]:
        return "mounded_carb", "poha_upma", "volume", 150
    if name in ["chow mein", "chop suey", "cooked pasta", "macaroni salad", "thukpa"]:
        return "mounded_carb", "noodle_pasta", "volume", 180
    if name in ["cooked oatmeal"]:
        return "mounded_carb", "porridge_oats", "volume", 180

    # Salad Raw
    if name in [
        "beetroot",
        "carrots",
        "cucumber",
        "lettuce",
        "onion",
        "radish",
        "tomato",
        "turnip",
    ]:
        return "salad_raw", "raw_vegetable_salad", "volume", 75
    if name in ["corn", "sweet potatoes"]:
        return "salad_raw", "boiled_salad_tuber", "volume", 100
    if name in ["chilli pepper", "garlic", "ginger", "paprika"]:
        return "salad_raw", "aromatics_raw", "volume", 20

    # Protein Pieces
    if name in ["chicken tikka", "chicken wings", "fried chicken", "kebabs", "seekh kebab"]:
        return "protein_piece", "chicken_kebab_piece", "piece", 60
    if name in ["fried fish", "pan-fried prawns"]:
        return "protein_piece", "fish_seafood_piece", "piece", 75
    if name in ["omelette", "scrambled eggs", "sunny side up eggs"]:
        return "protein_piece", "egg_dish", "piece", 80
    if name in ["hara bhara kabab"]:
        return "protein_piece", "veg_kebab_piece", "piece", 40

    # Fruits
    if name in [
        "apple",
        "banana",
        "grape",
        "kiwi",
        "lemon",
        "mango",
        "orange",
        "pear",
        "pineapple",
        "pomegranate",
        "watermelon",
    ]:
        return "other_food", "fruit_raw", "piece", 120

    # Chaat & Snacks
    if name in ["bhel puri", "paani puri", "pani puri", "papdi chaat", "sev puri", "raj kachori"]:
        return "other_food", "chaat", "piece", 100
    if name in [
        "samosa",
        "kachori",
        "aloo tikki",
        "onion pakoda",
        "pakode",
        "sabudana vada",
        "medu vada",
        "vada pav",
    ]:
        return "other_food", "fried_snack", "piece", 50
    if name in ["banana chips", "chivda", "murukku", "popcorn", "shankarpali"]:
        return "other_food", "dry_crunchy_snack", "volume", 40
    if name in ["dhokla", "khandvi", "paniyaram", "kuzhi paniyaram", "unni appam", "idli"]:
        return "other_food", "steamed_snack", "piece", 50
    if name in ["momos", "steamed momo"]:
        return "other_food", "dumpling_momo", "piece", 30
    if name in ["kaathi rolls", "kathi roll", "spring rolls"]:
        return "other_food", "rolls_wraps", "piece", 120
    if name in [
        "burger",
        "veggie burger",
        "hot dogs",
        "sandwich",
        "grilled sandwich",
        "taco",
        "pizza",
        "margherita pizza",
        "paneer pizza",
        "chicken pizza",
        "pepperoni pizza",
    ]:
        return "other_food", "western_fastfood", "piece", 150
    if name in ["litti chokha", "daal baati churma"]:
        return "other_food", "traditional_regional_meal", "piece", 200
    if name in ["thali"]:
        return "other_food", "composite_thali", "volume", 450

    # Sweets & Mithai
    if name in [
        "adhirasam",
        "anarsa",
        "ariselu",
        "balushahi",
        "bandar laddu",
        "besan laddu",
        "boondi",
        "boondi laddu",
        "chikki",
        "peanut chikki",
        "dharwad pedha",
        "gavvalu",
        "ghevar",
        "gujhia",
        "gujiya",
        "gulab jamun",
        "imarti",
        "jalebi",
        "kajjikaya",
        "kaju katli",
        "kakinada khaja",
        "kalakand",
        "ledikeni",
        "lyangcha",
        "malapua",
        "malpua",
        "modak",
        "mysore pak",
        "peda",
        "pithe",
        "poornalu",
        "pootharekulu",
        "rasgulla",
        "sandesh",
        "sohan halwa",
        "sohan papdi",
        "sutar feni",
    ]:
        return "other_food", "mithai_traditional", "piece", 40

    if name in [
        "basundi",
        "chak hao kheer",
        "cham cham",
        "chhena kheeri",
        "doodhpak",
        "falooda",
        "kheer",
        "phirni",
        "rabri",
        "ras malai",
        "sheer khurma",
        "sheer korma",
        "shrikhand",
        "mishti doi",
        "misti doi",
        "kulfi",
    ]:
        return "other_food", "milk_dessert", "volume", 100

    if name in [
        "gajar ka halwa",
        "moong dal halwa",
        "sheera",
        "double ka meetha",
        "khubani ka meetha",
        "qubani ka meetha",
    ]:
        return "other_food", "halwa_pudding", "volume", 100

    if name in [
        "apple pie",
        "brownie",
        "cake",
        "doughnut",
        "ice cream",
        "muffin",
        "pan cake",
        "tiramisu",
        "waffle",
    ]:
        return "other_food", "western_dessert", "piece", 80

    # Beverages
    if name in ["chaas", "chai", "lassi", "lemonade"]:
        return "other_food", "beverage", "volume", 200

    # Fallback
    return "other_food", "miscellaneous_food", "volume", 100


def main():
    with open(CLASSES_PATH, encoding="utf-8") as f:
        classes = json.load(f)

    # Collect groups and dishes
    groups_dict = {}
    dishes = []

    for c in sorted(classes):
        role, group, measure_mode, default_g = classify_dish(c)
        dish_id = c.replace(" ", "_").replace("-", "_")
        en_name = " ".join(word.capitalize() for word in c.split())

        if group not in groups_dict:
            groups_dict[group] = {
                "group_id": group,
                "role": role,
                "name": group.replace("_", " ").title(),
                "generic_dish_id": f"generic_{group}",
            }

        dishes.append(
            {
                "dish_id": dish_id,
                "raw_name": c,
                "names": {
                    "en": en_name,
                    "hi": en_name,  # Baseline placeholder for hi
                },
                "taxonomy": {
                    "role": role,
                    "group": group,
                    "is_generic": False,
                },
                "measure": {
                    "mode": measure_mode,
                    "serving_default_g": default_g,
                },
            }
        )

    # Add exactly one generic dish for each group
    generic_dishes = []
    for g_id, g_info in sorted(groups_dict.items()):
        gen_dish_id = f"generic_{g_id}"
        generic_dishes.append(
            {
                "dish_id": gen_dish_id,
                "raw_name": f"Generic {g_info['name']}",
                "names": {
                    "en": f"Generic {g_info['name']}",
                    "hi": f"सामान्य {g_info['name']}",
                },
                "taxonomy": {
                    "role": g_info["role"],
                    "group": g_id,
                    "is_generic": True,
                },
                "measure": {
                    "mode": "volume"
                    if g_info["role"] in ["gravy_curry", "dry_sabzi", "mounded_carb"]
                    else "piece",
                    "serving_default_g": 150,
                },
            }
        )

    all_dishes = dishes + generic_dishes

    taxonomy_doc = {
        "version": 1,
        "roles": ROLES,
        "groups": list(groups_dict.values()),
        "dishes": all_dishes,
        "stats": {
            "total_roles": len(ROLES),
            "total_groups": len(groups_dict),
            "catalog_dishes_count": len(dishes),
            "generic_fallbacks_count": len(generic_dishes),
            "total_dishes_count": len(all_dishes),
        },
    }

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(OUT_PATH, "w", encoding="utf-8") as f:
        yaml.dump(taxonomy_doc, f, sort_keys=False, allow_unicode=True)

    print(f"Generated {OUT_PATH}")
    print(f"Total roles: {len(ROLES)}")
    print(f"Total groups: {len(groups_dict)}")
    print(f"Catalog dishes: {len(dishes)}")
    print(f"Generic fallbacks: {len(generic_dishes)}")


if __name__ == "__main__":
    main()
