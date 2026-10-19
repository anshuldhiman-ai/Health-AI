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

  /// The app display name. Working title until the brand name is decided (Section 0) — replace in ALL arb files at once.
  ///
  /// In en, this message translates to:
  /// **'App'**
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
  /// **'Today\'s meals'**
  String get todaysMeals;

  /// No description provided for @addFood.
  ///
  /// In en, this message translates to:
  /// **'Add food'**
  String get addFood;

  /// No description provided for @logFirstMealCta.
  ///
  /// In en, this message translates to:
  /// **'Log your first meal'**
  String get logFirstMealCta;

  /// No description provided for @mealNotLoggedYet.
  ///
  /// In en, this message translates to:
  /// **'Not logged yet'**
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
  /// **'Nutrition breakdown'**
  String get nutritionBreakdown;

  /// No description provided for @ofTargets.
  ///
  /// In en, this message translates to:
  /// **'{percent} of targets'**
  String ofTargets(String percent);

  /// No description provided for @mealLog.
  ///
  /// In en, this message translates to:
  /// **'Meal log'**
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
  /// **'Scan result'**
  String get scanResultTitle;

  /// No description provided for @scanResultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Top 3 possible matches'**
  String get scanResultSubtitle;

  /// No description provided for @servingSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Serving size'**
  String get servingSizeLabel;

  /// No description provided for @estimatedCalories.
  ///
  /// In en, this message translates to:
  /// **'Estimated calories'**
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
  /// **'Calorie trend'**
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
  /// **'Nutrition balance'**
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
  /// **'My goals'**
  String get myGoals;

  /// No description provided for @settingsRow.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsRow;

  /// No description provided for @helpRow.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get helpRow;

  /// No description provided for @aboutRow.
  ///
  /// In en, this message translates to:
  /// **'About the app'**
  String get aboutRow;
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
