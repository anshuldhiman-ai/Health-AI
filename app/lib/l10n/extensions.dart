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
}
