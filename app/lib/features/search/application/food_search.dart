import 'package:app/domain/entities/dish_info.dart';

/// Curated shortcuts for an empty search. These are catalog ids, not a
/// second nutrition source.
const List<String> popularDishIds = [
  'paneer masala',
  'chole bhature',
  'masala dosa',
  'biryani',
  'aloo paratha',
  'samosa',
  'kulfi',
  'idli',
];

/// Stable display order for the catalog families.
const List<String> familyOrder = [
  'curry',
  'bread',
  'rice',
  'south indian',
  'snacks',
  'chaat',
  'sweet',
  'beverage',
  'kebab',
  'pizza',
  'fasting',
  'others',
];

final Map<String, String> _dishSearchIndex = {};

String _getSearchableText(DishInfo dish) {
  return _dishSearchIndex.putIfAbsent(dish.id, () {
    final parts = [
      dish.name.toLowerCase(),
      dish.id.toLowerCase(),
      dish.family.toLowerCase(),
      ...dish.ingredients.map((i) => i.toLowerCase()),
    ];
    return parts.join(' ');
  });
}

/// Filter by free text (name, id, family, ingredients) and family. Pure
/// function so both the search screen and tests use the same rules.
List<DishInfo> filterDishes(
  DishCatalog catalog, {
  String query = '',
  String? family,
}) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty && family == null) {
    return catalog.dishes.values.toList(growable: false);
  }
  return [
    for (final dish in catalog.dishes.values)
      if ((family == null || dish.family == family) &&
          (needle.isEmpty || _getSearchableText(dish).contains(needle)))
        dish,
  ];
}

List<DishInfo> popularDishes(DishCatalog catalog) => [
  for (final id in popularDishIds)
    if (catalog.dishes[id] != null) catalog.dishes[id]!,
];

/// Families present in the catalog, in the product's preferred order.
List<String> catalogFamilies(DishCatalog catalog) {
  final present = {for (final dish in catalog.dishes.values) dish.family};
  return [
    for (final family in familyOrder)
      if (present.contains(family)) family,
    for (final family in present)
      if (!familyOrder.contains(family)) family,
  ];
}
