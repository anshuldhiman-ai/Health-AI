/// Meal taxonomy shared by Today, Diary and Scan. Pure Dart (R9).
library;

/// The four canonical meal slots of a day.
enum MealKind { breakfast, lunch, dinner, snacks }

/// Which slot a scan/search should preselect for the current clock.
MealKind mealForHour(int hour) {
  if (hour < 11) return MealKind.breakfast;
  if (hour < 16) return MealKind.lunch;
  if (hour < 19) return MealKind.snacks;
  return MealKind.dinner;
}
