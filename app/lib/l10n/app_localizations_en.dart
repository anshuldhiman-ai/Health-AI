// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Health AI';

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
  String get todaysMeals => 'Today\'s Meals';

  @override
  String get caloriesLabel => 'Calories';

  @override
  String get addFood => 'Add Food';

  @override
  String get logFirstMealCta => 'Log your first meal';

  @override
  String get mealNotLoggedYet => 'Not added yet';

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
  String get nutritionBreakdown => 'Nutrition Breakdown';

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
  String get ofTargetsCaption => 'of targets';

  @override
  String get mealLog => 'Meal Log';

  @override
  String get scanScreenTitle => 'Scan food';

  @override
  String get pointAtPlate => 'Point your camera at the plate';

  @override
  String get cameraPlaceholder =>
      'Camera preview arrives with the on-device model (M2).';

  @override
  String get scanResultTitle => 'Scan Result';

  @override
  String get scanResultSubtitle => 'Top 3 possible matches';

  @override
  String get servingSizeLabel => 'Select Serving Size';

  @override
  String get estimatedCalories => 'Estimated Calories';

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
  String get calorieTrend => 'Calorie Trend';

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
  String get nutritionBalance => 'Nutrition Balance';

  @override
  String get profileTitle => 'Profile';

  @override
  String get deviceOnly => 'Your data stays on this device.';

  @override
  String get myGoals => 'My Goals';

  @override
  String get settingsRow => 'Settings';

  @override
  String get helpRow => 'Help & Support';

  @override
  String get aboutRow => 'About Health AI';

  @override
  String get closeLabel => 'Close';

  @override
  String get scanTorch => 'Toggle torch';

  @override
  String get scanCapture => 'Capture photo';

  @override
  String get scanCameraUnavailableTitle => 'Camera unavailable';

  @override
  String get scanCameraUnavailableHint =>
      'Check camera permission, or pick a photo from your gallery.';

  @override
  String get scanPickFromGallery => 'Choose from gallery';

  @override
  String get scanAnalyzing => 'Reading your plate…';

  @override
  String get scanAnalyzingHint => 'Matching 80 Indian dishes on this device.';

  @override
  String get scanModelMissing =>
      'The recognition model isn\'t installed in this build, so scanning is unavailable.';

  @override
  String get scanPhotoFailed => 'Couldn\'t read that photo. Try another one.';

  @override
  String get scanUncertainHint =>
      'Low confidence — check the dish and its ingredients before adding.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Make Health AI yours.';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceHint =>
      'System follows your phone\'s light or dark setting.';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get doneLabel => 'Done';

  @override
  String get privacyTitle => 'Private by design';

  @override
  String get privacyBody =>
      'Your meals, steps and photos stay on this device. No account, no cloud.';

  @override
  String get helpTitle => 'Help & Support';

  @override
  String get helpSubtitle => 'Quick answers, all offline.';

  @override
  String get helpScanQ => 'How do I scan a dish?';

  @override
  String get helpScanA =>
      'Tap the green camera button, take or choose a photo, then confirm the best match before adding it.';

  @override
  String get helpCaloriesQ => 'Are the calories exact?';

  @override
  String get helpCaloriesA =>
      'They are estimates based on the dish and serving size. Portion size is the biggest source of error.';

  @override
  String get helpStepsQ => 'Why do steps show a dash?';

  @override
  String get helpStepsA =>
      'Allow physical activity access when Android asks. The phone must have a step counter; steps start counting from the first reading of the day.';

  @override
  String get helpOfflineQ => 'Does the app need internet?';

  @override
  String get helpOfflineA =>
      'No. Recognition, diary and step tracking run on your phone.';

  @override
  String get aboutLegalese => 'Offline nutrition and activity tracking.';

  @override
  String get aboutPrivacy =>
      'Health AI has no account and no cloud sync. Everything you log stays on this device.';

  @override
  String get aboutModel =>
      'Food recognition runs fully on-device with a MobileNetV4 model trained on 80 Indian dishes.';

  @override
  String get chooseGoal => 'Pick the plan that fits you.';

  @override
  String get goalLose => 'Lose weight';

  @override
  String get goalLoseHint => 'A gentle calorie deficit';

  @override
  String get goalLoseSubtitle => 'Lose 5 kg in 3 months';

  @override
  String get goalMaintain => 'Maintain weight';

  @override
  String get goalMaintainHint => 'Balance intake and activity';

  @override
  String get goalMaintainSubtitle => 'Keep your current weight';

  @override
  String get goalGain => 'Gain weight';

  @override
  String get goalGainHint => 'A small calorie surplus';

  @override
  String get goalGainSubtitle => 'Build strength and size';

  @override
  String get gramUnit => 'g';

  @override
  String get kmUnit => 'km';

  @override
  String get minPerKm => 'min/km';

  @override
  String get spmUnit => 'steps/min';

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String durationMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String get dayToday => 'Today';

  @override
  String get dayYesterday => 'Yesterday';

  @override
  String dayDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String stepsDistanceCaption(String distance) {
    return 'steps · $distance km';
  }

  @override
  String get onTrackTitle => 'You\'re on track!';

  @override
  String onTrackBody(String left, String protein) {
    return '$left kcal left · $protein g protein to go';
  }

  @override
  String get overTargetTitle => 'A little over today';

  @override
  String overTargetBody(String over) {
    return '$over kcal over target. A lighter next meal can balance it out.';
  }

  @override
  String get startDayTitle => 'Start your day';

  @override
  String get startDayBody => 'Log a meal to see today\'s calories and macros.';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get searchFood => 'Search food';

  @override
  String get viewDiary => 'View diary';

  @override
  String get activityTitle => 'Activity';

  @override
  String get activitySubtitle => 'Steps, distance and pace from your phone.';

  @override
  String get activityToday => 'Today\'s movement';

  @override
  String get stepsLabel => 'Steps';

  @override
  String stepGoal(String goal) {
    return 'of $goal steps';
  }

  @override
  String get distanceLabel => 'Distance';

  @override
  String get activeTimeLabel => 'Active time';

  @override
  String get avgPaceLabel => 'Avg pace';

  @override
  String get cadenceLabel => 'Cadence';

  @override
  String get todayByHour => 'Today by hour';

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get historyBuildsHint => 'History builds as you use the app.';

  @override
  String get activityPermissionTitle => 'Allow activity access';

  @override
  String get activityPermissionBody =>
      'Health AI reads your phone\'s step counter to show steps, distance and pace. It stays on this device.';

  @override
  String get activityAllow => 'Allow access';

  @override
  String get activityOpenSettings => 'Open settings';

  @override
  String get activityUnsupportedTitle => 'No step sensor found';

  @override
  String get activityUnsupportedBody =>
      'This device does not expose a step counter to apps. You can still log meals and water.';

  @override
  String get activityUnavailableTitle => 'Steps unavailable';

  @override
  String get activityUnavailableBody =>
      'The step sensor is not responding right now. Try again or check activity permission.';

  @override
  String get activityRefresh => 'Try again';

  @override
  String get activityPrivacyNote =>
      'Distance uses an average 0.76 m stride. Active time counts walking intervals only; your phone counts steps while it is with you.';

  @override
  String get waterTitle => 'Water';

  @override
  String get waterSubtitle => 'A glass at a time.';

  @override
  String get waterIntake => 'Water intake';

  @override
  String waterGoal(String goal) {
    return 'Goal: $goal L';
  }

  @override
  String get addGlass => 'Add a glass';

  @override
  String get removeGlass => 'Remove last';

  @override
  String glassesCount(String count, String goal) {
    return '$count of $goal glasses';
  }

  @override
  String get waterNote =>
      'Hydration needs vary. This is a simple daily guide, not medical advice.';

  @override
  String get sleepTitle => 'Sleep';

  @override
  String get sleepSubtitle => 'Log last night\'s rest.';

  @override
  String get sleepDuration => 'Sleep duration';

  @override
  String get bedtimeLabel => 'Bedtime';

  @override
  String get wakeTimeLabel => 'Wake time';

  @override
  String get saveSleep => 'Save sleep';

  @override
  String sleepGoal(String goal) {
    return 'Goal: $goal';
  }

  @override
  String get noSleepLogged => 'No sleep logged for today.';

  @override
  String get sleepNote =>
      'Sleep is logged manually on this device. No wearable or account is required.';

  @override
  String get clearSleep => 'Clear';

  @override
  String get weeklyProgress => 'Weekly Progress';

  @override
  String get weeklySubtitle => 'The last seven days at a glance.';

  @override
  String get viewWeekly => 'View week';

  @override
  String get caloriesTab => 'Calories';

  @override
  String get macrosTab => 'Macros';

  @override
  String get mealsTab => 'Meals';

  @override
  String get weeklyAverage => 'Daily average';

  @override
  String get daysOnTarget => 'Days on target';

  @override
  String get weeklyConsistency => 'Days logged';

  @override
  String get weeklyNote =>
      'Targets are your current plan. Tap a bar for the day\'s total.';

  @override
  String get searchFoodTitle => 'Search Food';

  @override
  String get searchFoodHint => 'Search 80 Indian dishes';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryCurry => 'Curry';

  @override
  String get categoryBread => 'Bread';

  @override
  String get categoryRice => 'Rice';

  @override
  String get categorySnacks => 'Snacks';

  @override
  String get categorySweet => 'Sweet';

  @override
  String get categoryBeverage => 'Beverage';

  @override
  String get categoryChaat => 'Chaat';

  @override
  String get categoryKebab => 'Kebab';

  @override
  String get categoryPizza => 'Pizza';

  @override
  String get categorySouthIndian => 'South Indian';

  @override
  String get categoryFasting => 'Fasting';

  @override
  String get categoryOthers => 'Others';

  @override
  String get noDishesFound => 'No dishes found';

  @override
  String get noDishesFoundHint => 'Try a different name or category.';

  @override
  String get popularDishes => 'Popular dishes';

  @override
  String get allDishes => 'All dishes';

  @override
  String dishesCount(int count) {
    return '$count dishes';
  }

  @override
  String get dishDetails => 'Dish details';

  @override
  String get nutritionTab => 'Nutrition';

  @override
  String get ingredientsTab => 'Ingredients';

  @override
  String get portionsTab => 'Portions';

  @override
  String get per100g => 'per 100 g';

  @override
  String get perServing => 'per serving';

  @override
  String get catalogNote =>
      'Nutrition values are estimates. Recipes and portions vary.';

  @override
  String get ingredientsNote =>
      'Key ingredients from our local catalog. Recipes vary.';

  @override
  String get selectServing => 'Select serving';

  @override
  String get selectMeal => 'Meal';

  @override
  String get addToDiary => 'Add to Diary';

  @override
  String get mealDetails => 'Meal details';

  @override
  String get noMealEntries => 'Nothing logged for this meal yet.';

  @override
  String entriesCount(int count) {
    return '$count items';
  }

  @override
  String get addAnother => 'Add another';

  @override
  String get delete => 'Delete';

  @override
  String get goalLabel => 'Goal';

  @override
  String get stepsToday => 'Today';

  @override
  String get progressLabel => 'Progress';

  @override
  String get savedLabel => 'Saved';

  @override
  String get catalogLoadError => 'Could not load the food catalog.';

  @override
  String kcalLeftShort(String left) {
    return '$left kcal left';
  }

  @override
  String kcalOverShort(String over) {
    return '$over kcal over';
  }

  @override
  String get noWeeklyData => 'No meals logged this week.';
}
