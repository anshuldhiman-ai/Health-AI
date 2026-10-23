import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_pa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('pa'),
  ];

  /// The app display name, from the approved reference. Replace in ALL arb files at once if the brand changes.
  ///
  /// In en, this message translates to:
  /// **'Health AI'**
  String get appTitle;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning!'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon!'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening!'**
  String get greetingEvening;

  /// No description provided for @todayTagline.
  ///
  /// In en, this message translates to:
  /// **'Fuel your body for a healthier you.'**
  String get todayTagline;

  /// No description provided for @remainingKcal.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remainingKcal;

  /// No description provided for @kcalUnit.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get kcalUnit;

  /// No description provided for @macroProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get macroProtein;

  /// No description provided for @macroCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get macroCarbs;

  /// No description provided for @macroFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get macroFat;

  /// No description provided for @stepsTile.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get stepsTile;

  /// No description provided for @waterTile.
  ///
  /// In en, this message translates to:
  /// **'water'**
  String get waterTile;

  /// No description provided for @sleepTile.
  ///
  /// In en, this message translates to:
  /// **'sleep'**
  String get sleepTile;

  /// No description provided for @todaysMeals.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Meals'**
  String get todaysMeals;

  /// No description provided for @caloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get caloriesLabel;

  /// No description provided for @addFood.
  ///
  /// In en, this message translates to:
  /// **'Add Food'**
  String get addFood;

  /// No description provided for @logFirstMealCta.
  ///
  /// In en, this message translates to:
  /// **'Log your first meal'**
  String get logFirstMealCta;

  /// No description provided for @mealNotLoggedYet.
  ///
  /// In en, this message translates to:
  /// **'Not added yet'**
  String get mealNotLoggedYet;

  /// No description provided for @mealBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealLunch;

  /// No description provided for @mealDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealDinner;

  /// No description provided for @mealSnacks.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get mealSnacks;

  /// No description provided for @todayTab.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTab;

  /// No description provided for @diaryTab.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get diaryTab;

  /// No description provided for @insightsTab.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insightsTab;

  /// No description provided for @profileTab.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTab;

  /// No description provided for @diaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get diaryTitle;

  /// No description provided for @caloriesLeft.
  ///
  /// In en, this message translates to:
  /// **'{left} left'**
  String caloriesLeft(String left);

  /// No description provided for @nutritionBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Breakdown'**
  String get nutritionBreakdown;

  /// No description provided for @emptyDayHint.
  ///
  /// In en, this message translates to:
  /// **'Scan a plate or add a dish to start tracking.'**
  String get emptyDayHint;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Eat Smart. Live Healthier.'**
  String get welcomeTagline;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @deviceOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Use Health AI on this device'**
  String get deviceOnlyTitle;

  /// No description provided for @signInNote.
  ///
  /// In en, this message translates to:
  /// **'Health AI is offline-first: there is no account and never one. Your diary is encrypted on this phone only.'**
  String get signInNote;

  /// No description provided for @okGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get okGotIt;

  /// No description provided for @wdMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get wdMon;

  /// No description provided for @wdTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get wdTue;

  /// No description provided for @wdWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wdWed;

  /// No description provided for @wdThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get wdThu;

  /// No description provided for @wdFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get wdFri;

  /// No description provided for @wdSat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get wdSat;

  /// No description provided for @wdSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get wdSun;

  /// No description provided for @ofTargets.
  ///
  /// In en, this message translates to:
  /// **'{percent} of targets'**
  String ofTargets(String percent);

  /// No description provided for @ofTargetsCaption.
  ///
  /// In en, this message translates to:
  /// **'of targets'**
  String get ofTargetsCaption;

  /// No description provided for @mealLog.
  ///
  /// In en, this message translates to:
  /// **'Meal Log'**
  String get mealLog;

  /// No description provided for @scanScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan food'**
  String get scanScreenTitle;

  /// No description provided for @pointAtPlate.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the plate'**
  String get pointAtPlate;

  /// No description provided for @cameraPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Camera preview arrives with the on-device model (M2).'**
  String get cameraPlaceholder;

  /// No description provided for @scanResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Result'**
  String get scanResultTitle;

  /// No description provided for @scanResultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Top 3 possible matches'**
  String get scanResultSubtitle;

  /// No description provided for @servingSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Serving Size'**
  String get servingSizeLabel;

  /// No description provided for @estimatedCalories.
  ///
  /// In en, this message translates to:
  /// **'Estimated Calories'**
  String get estimatedCalories;

  /// No description provided for @addToMeal.
  ///
  /// In en, this message translates to:
  /// **'Add to {meal}'**
  String addToMeal(String meal);

  /// No description provided for @addedToast.
  ///
  /// In en, this message translates to:
  /// **'Added to {meal}.'**
  String addedToast(String meal);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insightsTitle;

  /// No description provided for @calorieTrend.
  ///
  /// In en, this message translates to:
  /// **'Calorie Trend'**
  String get calorieTrend;

  /// No description provided for @avgKcalPerDay.
  ///
  /// In en, this message translates to:
  /// **'avg kcal/day'**
  String get avgKcalPerDay;

  /// No description provided for @trendChangeUp.
  ///
  /// In en, this message translates to:
  /// **'↑ {percent}%'**
  String trendChangeUp(String percent);

  /// No description provided for @trendChangeDown.
  ///
  /// In en, this message translates to:
  /// **'↓ {percent}%'**
  String trendChangeDown(String percent);

  /// No description provided for @nutritionBalance.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Balance'**
  String get nutritionBalance;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @deviceOnly.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on this device.'**
  String get deviceOnly;

  /// No description provided for @myGoals.
  ///
  /// In en, this message translates to:
  /// **'My Goals'**
  String get myGoals;

  /// No description provided for @settingsRow.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsRow;

  /// No description provided for @helpRow.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpRow;

  /// No description provided for @aboutRow.
  ///
  /// In en, this message translates to:
  /// **'About Health AI'**
  String get aboutRow;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// No description provided for @scanTorch.
  ///
  /// In en, this message translates to:
  /// **'Toggle torch'**
  String get scanTorch;

  /// No description provided for @scanCapture.
  ///
  /// In en, this message translates to:
  /// **'Capture photo'**
  String get scanCapture;

  /// No description provided for @scanCameraUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get scanCameraUnavailableTitle;

  /// No description provided for @scanCameraUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'Check camera permission, or pick a photo from your gallery.'**
  String get scanCameraUnavailableHint;

  /// No description provided for @scanPickFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get scanPickFromGallery;

  /// No description provided for @scanAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Reading your plate…'**
  String get scanAnalyzing;

  /// No description provided for @scanAnalyzingHint.
  ///
  /// In en, this message translates to:
  /// **'Matching Indian dishes on this device.'**
  String scanAnalyzingHint(int count);

  /// No description provided for @scanModelMissing.
  ///
  /// In en, this message translates to:
  /// **'The recognition model isn\'t installed in this build, so scanning is unavailable.'**
  String get scanModelMissing;

  /// No description provided for @scanPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read that photo. Try another one.'**
  String get scanPhotoFailed;

  /// No description provided for @scanUncertainHint.
  ///
  /// In en, this message translates to:
  /// **'Low confidence — check the dish and its ingredients before adding.'**
  String get scanUncertainHint;

  /// No description provided for @scanDetecting.
  ///
  /// In en, this message translates to:
  /// **'Detecting…'**
  String get scanDetecting;

  /// No description provided for @scanNotFoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Not a food item'**
  String get scanNotFoodTitle;

  /// No description provided for @scanNotFoodBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find a dish in this photo. Try again with the food filling more of the frame, or search for the dish by name.'**
  String get scanNotFoodBody;

  /// No description provided for @scanTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get scanTryAgain;

  /// No description provided for @scanSearchManually.
  ///
  /// In en, this message translates to:
  /// **'Search manually'**
  String get scanSearchManually;

  /// No description provided for @scanTorchOn.
  ///
  /// In en, this message translates to:
  /// **'Turn the light on'**
  String get scanTorchOn;

  /// No description provided for @scanTorchOff.
  ///
  /// In en, this message translates to:
  /// **'Turn the light off'**
  String get scanTorchOff;

  /// No description provided for @scanCaptureHeading.
  ///
  /// In en, this message translates to:
  /// **'Capture your meal'**
  String get scanCaptureHeading;

  /// No description provided for @scanCaptureHint.
  ///
  /// In en, this message translates to:
  /// **'Point the frame at one dish and tap the shutter.'**
  String get scanCaptureHint;

  /// No description provided for @scanQuickAdd.
  ///
  /// In en, this message translates to:
  /// **'Quick add a food by name'**
  String get scanQuickAdd;

  /// No description provided for @quickAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick add'**
  String get quickAddTitle;

  /// No description provided for @quickAddSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search the dishes bundled on your device. Nothing is sent anywhere.'**
  String get quickAddSubtitle;

  /// No description provided for @quickAddSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search a dish'**
  String get quickAddSearchHint;

  /// No description provided for @quickAddPicks.
  ///
  /// In en, this message translates to:
  /// **'Quick picks'**
  String get quickAddPicks;

  /// No description provided for @quickAddNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No dish matches that. Try a shorter word, or check the spelling.'**
  String get quickAddNoMatch;

  /// No description provided for @quickAddNoNutrition.
  ///
  /// In en, this message translates to:
  /// **'No nutrition data yet'**
  String get quickAddNoNutrition;

  /// No description provided for @quickAddUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The dish catalog didn\'t load, so quick add is unavailable. Try again in a moment.'**
  String get quickAddUnavailable;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Make Health AI yours.'**
  String get settingsSubtitle;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @appearanceHint.
  ///
  /// In en, this message translates to:
  /// **'System follows your phone\'s light or dark setting.'**
  String get appearanceHint;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @doneLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneLabel;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Private by design'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Your meals, steps and photos stay on this device. No account, no cloud.'**
  String get privacyBody;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpTitle;

  /// No description provided for @helpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick answers, all offline.'**
  String get helpSubtitle;

  /// No description provided for @helpScanQ.
  ///
  /// In en, this message translates to:
  /// **'How do I scan a dish?'**
  String get helpScanQ;

  /// No description provided for @helpScanA.
  ///
  /// In en, this message translates to:
  /// **'Tap the green camera button, take or choose a photo, then confirm the best match before adding it.'**
  String get helpScanA;

  /// No description provided for @helpCaloriesQ.
  ///
  /// In en, this message translates to:
  /// **'Are the calories exact?'**
  String get helpCaloriesQ;

  /// No description provided for @helpCaloriesA.
  ///
  /// In en, this message translates to:
  /// **'They are estimates based on the dish and serving size. Portion size is the biggest source of error.'**
  String get helpCaloriesA;

  /// No description provided for @helpStepsQ.
  ///
  /// In en, this message translates to:
  /// **'Why do steps show a dash?'**
  String get helpStepsQ;

  /// No description provided for @helpStepsA.
  ///
  /// In en, this message translates to:
  /// **'Allow physical activity access when Android asks. The phone must have a step counter; steps start counting from the first reading of the day.'**
  String get helpStepsA;

  /// No description provided for @helpOfflineQ.
  ///
  /// In en, this message translates to:
  /// **'Does the app need internet?'**
  String get helpOfflineQ;

  /// No description provided for @helpOfflineA.
  ///
  /// In en, this message translates to:
  /// **'No. Recognition, diary and step tracking run on your phone.'**
  String get helpOfflineA;

  /// No description provided for @aboutLegalese.
  ///
  /// In en, this message translates to:
  /// **'Offline nutrition and activity tracking.'**
  String get aboutLegalese;

  /// No description provided for @aboutPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Health AI has no account and no cloud sync. Everything you log stays on this device.'**
  String get aboutPrivacy;

  /// No description provided for @aboutModel.
  ///
  /// In en, this message translates to:
  /// **'Food recognition runs fully on-device with a MobileNetV4 model trained on Indian dishes.'**
  String aboutModel(int count);

  /// No description provided for @chooseGoal.
  ///
  /// In en, this message translates to:
  /// **'Pick the plan that fits you.'**
  String get chooseGoal;

  /// No description provided for @goalLose.
  ///
  /// In en, this message translates to:
  /// **'Lose weight'**
  String get goalLose;

  /// No description provided for @goalLoseHint.
  ///
  /// In en, this message translates to:
  /// **'A gentle calorie deficit'**
  String get goalLoseHint;

  /// No description provided for @goalLoseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lose 5 kg in 3 months'**
  String get goalLoseSubtitle;

  /// No description provided for @goalMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain weight'**
  String get goalMaintain;

  /// No description provided for @goalMaintainHint.
  ///
  /// In en, this message translates to:
  /// **'Balance intake and activity'**
  String get goalMaintainHint;

  /// No description provided for @goalMaintainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your current weight'**
  String get goalMaintainSubtitle;

  /// No description provided for @goalGain.
  ///
  /// In en, this message translates to:
  /// **'Gain weight'**
  String get goalGain;

  /// No description provided for @goalGainHint.
  ///
  /// In en, this message translates to:
  /// **'A small calorie surplus'**
  String get goalGainHint;

  /// No description provided for @goalGainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build strength and size'**
  String get goalGainSubtitle;

  /// No description provided for @gramUnit.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get gramUnit;

  /// No description provided for @kmUnit.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get kmUnit;

  /// No description provided for @minPerKm.
  ///
  /// In en, this message translates to:
  /// **'min/km'**
  String get minPerKm;

  /// No description provided for @spmUnit.
  ///
  /// In en, this message translates to:
  /// **'steps/min'**
  String get spmUnit;

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationHoursMinutes(String hours, String minutes);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(String minutes);

  /// No description provided for @dayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dayToday;

  /// No description provided for @dayYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dayYesterday;

  /// No description provided for @dayDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String dayDaysAgo(int count);

  /// No description provided for @stepsDistanceCaption.
  ///
  /// In en, this message translates to:
  /// **'steps · {distance} km'**
  String stepsDistanceCaption(String distance);

  /// No description provided for @onTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re on track!'**
  String get onTrackTitle;

  /// No description provided for @onTrackBody.
  ///
  /// In en, this message translates to:
  /// **'{left} kcal left · {protein} g protein to go'**
  String onTrackBody(String left, String protein);

  /// No description provided for @overTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'A little over today'**
  String get overTargetTitle;

  /// No description provided for @overTargetBody.
  ///
  /// In en, this message translates to:
  /// **'{over} kcal over target. A lighter next meal can balance it out.'**
  String overTargetBody(String over);

  /// No description provided for @startDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Start your day'**
  String get startDayTitle;

  /// No description provided for @startDayBody.
  ///
  /// In en, this message translates to:
  /// **'Log a meal to see today\'s calories and macros.'**
  String get startDayBody;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @searchFood.
  ///
  /// In en, this message translates to:
  /// **'Search food'**
  String get searchFood;

  /// No description provided for @viewDiary.
  ///
  /// In en, this message translates to:
  /// **'View diary'**
  String get viewDiary;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @activitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Steps, distance and pace from your phone.'**
  String get activitySubtitle;

  /// No description provided for @activityToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s movement'**
  String get activityToday;

  /// No description provided for @stepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get stepsLabel;

  /// No description provided for @stepGoal.
  ///
  /// In en, this message translates to:
  /// **'of {goal} steps'**
  String stepGoal(String goal);

  /// No description provided for @distanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distanceLabel;

  /// No description provided for @activeTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active time'**
  String get activeTimeLabel;

  /// No description provided for @avgPaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg pace'**
  String get avgPaceLabel;

  /// No description provided for @cadenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Cadence'**
  String get cadenceLabel;

  /// No description provided for @todayByHour.
  ///
  /// In en, this message translates to:
  /// **'Today by hour'**
  String get todayByHour;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @historyBuildsHint.
  ///
  /// In en, this message translates to:
  /// **'History builds as you use the app.'**
  String get historyBuildsHint;

  /// No description provided for @activityPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow activity access'**
  String get activityPermissionTitle;

  /// No description provided for @activityPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Health AI reads your phone\'s step counter to show steps, distance and pace. It stays on this device.'**
  String get activityPermissionBody;

  /// No description provided for @activityAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow access'**
  String get activityAllow;

  /// No description provided for @activityOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get activityOpenSettings;

  /// No description provided for @activityUnsupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'No step sensor found'**
  String get activityUnsupportedTitle;

  /// No description provided for @activityUnsupportedBody.
  ///
  /// In en, this message translates to:
  /// **'This device does not expose a step counter to apps. You can still log meals and water.'**
  String get activityUnsupportedBody;

  /// No description provided for @activityUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Steps unavailable'**
  String get activityUnavailableTitle;

  /// No description provided for @activityUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'The step sensor is not responding right now. Try again or check activity permission.'**
  String get activityUnavailableBody;

  /// No description provided for @activityRefresh.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get activityRefresh;

  /// No description provided for @activityPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Distance uses an average 0.76 m stride. Active time counts walking intervals only; your phone counts steps while it is with you.'**
  String get activityPrivacyNote;

  /// No description provided for @waterTitle.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get waterTitle;

  /// No description provided for @waterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A glass at a time.'**
  String get waterSubtitle;

  /// No description provided for @waterIntake.
  ///
  /// In en, this message translates to:
  /// **'Water intake'**
  String get waterIntake;

  /// No description provided for @waterGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal: {goal} L'**
  String waterGoal(String goal);

  /// No description provided for @addGlass.
  ///
  /// In en, this message translates to:
  /// **'Add a glass'**
  String get addGlass;

  /// No description provided for @removeGlass.
  ///
  /// In en, this message translates to:
  /// **'Remove last'**
  String get removeGlass;

  /// No description provided for @glassesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {goal} glasses'**
  String glassesCount(String count, String goal);

  /// No description provided for @waterNote.
  ///
  /// In en, this message translates to:
  /// **'Hydration needs vary. This is a simple daily guide, not medical advice.'**
  String get waterNote;

  /// No description provided for @sleepTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleepTitle;

  /// No description provided for @sleepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log last night\'s rest.'**
  String get sleepSubtitle;

  /// No description provided for @sleepDuration.
  ///
  /// In en, this message translates to:
  /// **'Sleep duration'**
  String get sleepDuration;

  /// No description provided for @bedtimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get bedtimeLabel;

  /// No description provided for @wakeTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Wake time'**
  String get wakeTimeLabel;

  /// No description provided for @saveSleep.
  ///
  /// In en, this message translates to:
  /// **'Save sleep'**
  String get saveSleep;

  /// No description provided for @sleepGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal: {goal}'**
  String sleepGoal(String goal);

  /// No description provided for @noSleepLogged.
  ///
  /// In en, this message translates to:
  /// **'No sleep logged for today.'**
  String get noSleepLogged;

  /// No description provided for @sleepNote.
  ///
  /// In en, this message translates to:
  /// **'Sleep is logged manually on this device. No wearable or account is required.'**
  String get sleepNote;

  /// No description provided for @clearSleep.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSleep;

  /// No description provided for @weeklyProgress.
  ///
  /// In en, this message translates to:
  /// **'Weekly Progress'**
  String get weeklyProgress;

  /// No description provided for @weeklySubtitle.
  ///
  /// In en, this message translates to:
  /// **'The last seven days at a glance.'**
  String get weeklySubtitle;

  /// No description provided for @viewWeekly.
  ///
  /// In en, this message translates to:
  /// **'View week'**
  String get viewWeekly;

  /// No description provided for @caloriesTab.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get caloriesTab;

  /// No description provided for @macrosTab.
  ///
  /// In en, this message translates to:
  /// **'Macros'**
  String get macrosTab;

  /// No description provided for @mealsTab.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get mealsTab;

  /// No description provided for @weeklyAverage.
  ///
  /// In en, this message translates to:
  /// **'Daily average'**
  String get weeklyAverage;

  /// No description provided for @daysOnTarget.
  ///
  /// In en, this message translates to:
  /// **'Days on target'**
  String get daysOnTarget;

  /// No description provided for @weeklyConsistency.
  ///
  /// In en, this message translates to:
  /// **'Days logged'**
  String get weeklyConsistency;

  /// No description provided for @weeklyNote.
  ///
  /// In en, this message translates to:
  /// **'Targets are your current plan. Tap a bar for the day\'s total.'**
  String get weeklyNote;

  /// No description provided for @searchFoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Food'**
  String get searchFoodTitle;

  /// No description provided for @searchFoodHint.
  ///
  /// In en, this message translates to:
  /// **'Search Indian dishes'**
  String searchFoodHint(int count);

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryCurry.
  ///
  /// In en, this message translates to:
  /// **'Curry'**
  String get categoryCurry;

  /// No description provided for @categoryBread.
  ///
  /// In en, this message translates to:
  /// **'Bread'**
  String get categoryBread;

  /// No description provided for @categoryRice.
  ///
  /// In en, this message translates to:
  /// **'Rice'**
  String get categoryRice;

  /// No description provided for @categorySnacks.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get categorySnacks;

  /// No description provided for @categorySweet.
  ///
  /// In en, this message translates to:
  /// **'Sweet'**
  String get categorySweet;

  /// No description provided for @categoryBeverage.
  ///
  /// In en, this message translates to:
  /// **'Beverage'**
  String get categoryBeverage;

  /// No description provided for @categoryChaat.
  ///
  /// In en, this message translates to:
  /// **'Chaat'**
  String get categoryChaat;

  /// No description provided for @categoryKebab.
  ///
  /// In en, this message translates to:
  /// **'Kebab'**
  String get categoryKebab;

  /// No description provided for @categoryPizza.
  ///
  /// In en, this message translates to:
  /// **'Pizza'**
  String get categoryPizza;

  /// No description provided for @categorySouthIndian.
  ///
  /// In en, this message translates to:
  /// **'South Indian'**
  String get categorySouthIndian;

  /// No description provided for @categoryFasting.
  ///
  /// In en, this message translates to:
  /// **'Fasting'**
  String get categoryFasting;

  /// No description provided for @categoryOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get categoryOthers;

  /// No description provided for @noDishesFound.
  ///
  /// In en, this message translates to:
  /// **'No dishes found'**
  String get noDishesFound;

  /// No description provided for @noDishesFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different name or category.'**
  String get noDishesFoundHint;

  /// No description provided for @popularDishes.
  ///
  /// In en, this message translates to:
  /// **'Popular dishes'**
  String get popularDishes;

  /// No description provided for @allDishes.
  ///
  /// In en, this message translates to:
  /// **'All dishes'**
  String get allDishes;

  /// No description provided for @dishesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} dishes'**
  String dishesCount(int count);

  /// No description provided for @dishDetails.
  ///
  /// In en, this message translates to:
  /// **'Dish details'**
  String get dishDetails;

  /// No description provided for @nutritionTab.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutritionTab;

  /// No description provided for @ingredientsTab.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredientsTab;

  /// No description provided for @portionsTab.
  ///
  /// In en, this message translates to:
  /// **'Portions'**
  String get portionsTab;

  /// No description provided for @per100g.
  ///
  /// In en, this message translates to:
  /// **'per 100 g'**
  String get per100g;

  /// No description provided for @perServing.
  ///
  /// In en, this message translates to:
  /// **'per serving'**
  String get perServing;

  /// No description provided for @catalogNote.
  ///
  /// In en, this message translates to:
  /// **'Nutrition values are estimates. Recipes and portions vary.'**
  String get catalogNote;

  /// No description provided for @ingredientsNote.
  ///
  /// In en, this message translates to:
  /// **'Key ingredients from our local catalog. Recipes vary.'**
  String get ingredientsNote;

  /// No description provided for @selectServing.
  ///
  /// In en, this message translates to:
  /// **'Select serving'**
  String get selectServing;

  /// No description provided for @selectMeal.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get selectMeal;

  /// No description provided for @addToDiary.
  ///
  /// In en, this message translates to:
  /// **'Add to Diary'**
  String get addToDiary;

  /// No description provided for @mealDetails.
  ///
  /// In en, this message translates to:
  /// **'Meal details'**
  String get mealDetails;

  /// No description provided for @noMealEntries.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged for this meal yet.'**
  String get noMealEntries;

  /// No description provided for @entriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String entriesCount(int count);

  /// No description provided for @addAnother.
  ///
  /// In en, this message translates to:
  /// **'Add another'**
  String get addAnother;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @goalLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goalLabel;

  /// No description provided for @stepsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get stepsToday;

  /// No description provided for @progressLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressLabel;

  /// No description provided for @savedLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedLabel;

  /// No description provided for @catalogLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the food catalog.'**
  String get catalogLoadError;

  /// No description provided for @kcalLeftShort.
  ///
  /// In en, this message translates to:
  /// **'{left} kcal left'**
  String kcalLeftShort(String left);

  /// No description provided for @kcalOverShort.
  ///
  /// In en, this message translates to:
  /// **'{over} kcal over'**
  String kcalOverShort(String over);

  /// No description provided for @noWeeklyData.
  ///
  /// In en, this message translates to:
  /// **'No meals logged this week.'**
  String get noWeeklyData;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'pa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'pa':
      return AppLocalizationsPa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
