import 'package:flutter/material.dart';

/// Shared family icon used by manual search and dish detail. Purely
/// decorative; the family label is always shown as text too.
IconData familyIcon(String family) {
  switch (family) {
    case 'curry':
      return Icons.soup_kitchen_rounded;
    case 'bread':
      return Icons.breakfast_dining_rounded;
    case 'rice':
      return Icons.rice_bowl_rounded;
    case 'south indian':
      return Icons.lunch_dining_rounded;
    case 'snacks':
      return Icons.tapas_rounded;
    case 'chaat':
      return Icons.emoji_food_beverage_rounded;
    case 'sweet':
      return Icons.cake_rounded;
    case 'beverage':
      return Icons.local_cafe_rounded;
    case 'kebab':
      return Icons.outdoor_grill_rounded;
    case 'pizza':
      return Icons.local_pizza_rounded;
    case 'fasting':
      return Icons.spa_rounded;
    default:
      return Icons.restaurant_rounded;
  }
}
