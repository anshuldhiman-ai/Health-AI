import 'package:app/domain/entities/macro.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/l10n/app_localizations.dart';

/// Shared label mapping for domain enums (Today, Diary and Insights
/// all speak the same vocabulary). Feature-agnostic, lives beside the
/// ARB sources so adding a macro never means touching every screen.
extension L10nLabels on AppLocalizations {
  String macroLabel(MacroKind kind) {
    switch (kind) {
      case MacroKind.protein:
        return macroProtein;
      case MacroKind.carbs:
        return macroCarbs;
      case MacroKind.fat:
        return macroFat;
    }
  }

  String mealLabel(MealKind kind) {
    switch (kind) {
      case MealKind.breakfast:
        return mealBreakfast;
      case MealKind.lunch:
        return mealLunch;
      case MealKind.dinner:
        return mealDinner;
      case MealKind.snacks:
        return mealSnacks;
    }
  }

  /// Display label for a catalog family id (`south indian` → South Indian).
  String dishFamilyLabel(String family) {
    switch (family) {
      case 'curry':
        return categoryCurry;
      case 'bread':
        return categoryBread;
      case 'rice':
        return categoryRice;
      case 'snacks':
        return categorySnacks;
      case 'sweet':
        return categorySweet;
      case 'beverage':
        return categoryBeverage;
      case 'chaat':
        return categoryChaat;
      case 'kebab':
        return categoryKebab;
      case 'pizza':
        return categoryPizza;
      case 'south indian':
        return categorySouthIndian;
      case 'fasting':
        return categoryFasting;
      default:
        return categoryOthers;
    }
  }

  /// Relative day label used by diary/search targeting.
  String dayOffsetLabel(int offset) {
    if (offset == 0) return dayToday;
    if (offset == 1) return dayYesterday;
    return dayDaysAgo(offset);
  }

  /// Localized duration from whole minutes (`1h 20m`, `45 min`).
  String formatMinutes(int minutes) {
    if (minutes < 60) return durationMinutes('$minutes');
    return durationHoursMinutes('${minutes ~/ 60}', '${minutes % 60}');
  }
}
