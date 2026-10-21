import 'package:app/domain/entities/dish_info.dart';
import 'package:app/features/search/application/food_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sampleDishes = {
    'paneer masala': const DishInfo(
      id: 'paneer masala',
      name: 'Paneer Masala',
      family: 'curry',
      ingredients: ['Paneer', 'Tomato', 'Cream'],
      per100g: DishMacros(kcal: 220, protein: 9, carbs: 8, fat: 17),
      servings: [ServingPreset(label: '1 Katori', grams: 150)],
    ),
    'biryani': const DishInfo(
      id: 'biryani',
      name: 'Biryani',
      family: 'rice',
      ingredients: ['Rice', 'Vegetables', 'Spices'],
      per100g: DishMacros(kcal: 190, protein: 5.5, carbs: 26, fat: 7),
      servings: [ServingPreset(label: '1 Plate', grams: 350)],
    ),
    'aloo paratha': const DishInfo(
      id: 'aloo paratha',
      name: 'Aloo Paratha',
      family: 'bread',
      ingredients: ['Wheat', 'Potato', 'Ghee'],
      per100g: DishMacros(kcal: 260, protein: 5.5, carbs: 34, fat: 11),
      servings: [ServingPreset(label: '1 Piece', grams: 100)],
    ),
  };

  final catalog = DishCatalog(
    classes: sampleDishes.keys.toList(),
    dishes: sampleDishes,
  );

  test('empty query returns all dishes', () {
    final results = filterDishes(catalog);
    expect(results, hasLength(3));
  });

  test('search matches dish name case-insensitively', () {
    final results = filterDishes(catalog, query: 'PANEER');
    expect(results, hasLength(1));
    expect(results.first.id, 'paneer masala');
  });

  test('search matches ingredients', () {
    final results = filterDishes(catalog, query: 'potato');
    expect(results, hasLength(1));
    expect(results.first.id, 'aloo paratha');
  });

  test('search filters by family and query simultaneously', () {
    final results = filterDishes(catalog, query: 'paneer', family: 'curry');
    expect(results, hasLength(1));

    final noMatch = filterDishes(catalog, query: 'paneer', family: 'rice');
    expect(noMatch, isEmpty);
  });

  test('search handles empty results gracefully', () {
    final results = filterDishes(catalog, query: 'nonexistent dish xyz');
    expect(results, isEmpty);
  });
}
