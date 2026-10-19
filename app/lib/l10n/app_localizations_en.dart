// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'App';

  @override
  String get greetingMorning => 'Good morning!';

  @override
  String get greetingAfternoon => 'Good afternoon!';

  @override
  String get greetingEvening => 'Good evening!';

  @override
  String get todayTagline => 'Fuel your body for a healthier you.';

  @override
  String get remainingKcal => 'Remaining';

  @override
  String get kcalUnit => 'kcal';

  @override
  String get macroProtein => 'Protein';

  @override
  String get macroCarbs => 'Carbs';

  @override
  String get macroFat => 'Fat';

  @override
  String get stepsTile => 'steps';

  @override
  String get waterTile => 'water';

  @override
  String get sleepTile => 'sleep';

  @override
  String get todaysMeals => 'Today\'s meals';

  @override
  String get addFood => 'Add food';

  @override
  String get logFirstMealCta => 'Log your first meal';

  @override
  String get mealNotLoggedYet => 'Not logged yet';

  @override
  String get mealBreakfast => 'Breakfast';

  @override
  String get mealLunch => 'Lunch';

  @override
  String get mealDinner => 'Dinner';

  @override
  String get mealSnacks => 'Snacks';

  @override
  String get todayTab => 'Today';

  @override
  String get diaryTab => 'Diary';

  @override
  String get insightsTab => 'Insights';

  @override
  String get profileTab => 'Profile';

  @override
  String get diaryTitle => 'Diary';

  @override
  String caloriesLeft(String left) {
    return '$left left';
  }

  @override
  String get nutritionBreakdown => 'Nutrition breakdown';

  @override
  String get emptyDayHint => 'Scan a plate or add a dish to start tracking.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get welcomeTagline => 'Eat Smart. Live Healthier.';

  @override
  String get signIn => 'Sign In';

  @override
  String get deviceOnlyTitle => 'Use Health AI on this device';

  @override
  String get signInNote =>
      'Health AI is offline-first: there is no account and never one. Your diary is encrypted on this phone only.';

  @override
  String get okGotIt => 'Got it';

  @override
  String get wdMon => 'Mon';

  @override
  String get wdTue => 'Tue';

  @override
  String get wdWed => 'Wed';

  @override
  String get wdThu => 'Thu';

  @override
  String get wdFri => 'Fri';

  @override
  String get wdSat => 'Sat';

  @override
  String get wdSun => 'Sun';

  @override
  String ofTargets(String percent) {
    return '$percent of targets';
  }

  @override
  String get mealLog => 'Meal log';

  @override
  String get scanScreenTitle => 'Scan food';

  @override
  String get pointAtPlate => 'Point your camera at the plate';

  @override
  String get cameraPlaceholder =>
      'Camera preview arrives with the on-device model (M2).';

  @override
  String get scanResultTitle => 'Scan result';

  @override
  String get scanResultSubtitle => 'Top 3 possible matches';

  @override
  String get servingSizeLabel => 'Serving size';

  @override
  String get estimatedCalories => 'Estimated calories';

  @override
  String addToMeal(String meal) {
    return 'Add to $meal';
  }

  @override
  String addedToast(String meal) {
    return 'Added to $meal.';
  }

  @override
  String get undo => 'Undo';

  @override
  String get insightsTitle => 'Insights';

  @override
  String get calorieTrend => 'Calorie trend';

  @override
  String get avgKcalPerDay => 'avg kcal/day';

  @override
  String trendChangeUp(String percent) {
    return '↑ $percent%';
  }

  @override
  String trendChangeDown(String percent) {
    return '↓ $percent%';
  }

  @override
  String get nutritionBalance => 'Nutrition balance';

  @override
  String get profileTitle => 'Profile';

  @override
  String get deviceOnly => 'Your data stays on this device.';

  @override
  String get myGoals => 'My goals';

  @override
  String get settingsRow => 'Settings';

  @override
  String get helpRow => 'Help & support';

  @override
  String get aboutRow => 'About the app';
}
