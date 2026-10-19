// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'App';

  @override
  String get greetingMorning => 'सुप्रभात!';

  @override
  String get greetingAfternoon => 'नमस्कार!';

  @override
  String get greetingEvening => 'शुभ संध्या!';

  @override
  String get todayTagline => 'एक स्वस्थ जीवन के लिए अपने शरीर को पोषण दें।';

  @override
  String get remainingKcal => 'शेष';

  @override
  String get kcalUnit => 'कैलोरी';

  @override
  String get macroProtein => 'प्रोटीन';

  @override
  String get macroCarbs => 'कार्ब्स';

  @override
  String get macroFat => 'फैट';

  @override
  String get stepsTile => 'कदम';

  @override
  String get waterTile => 'पानी';

  @override
  String get sleepTile => 'नींद';

  @override
  String get todaysMeals => 'आज के भोजन';

  @override
  String get addFood => 'भोजन जोड़ें';

  @override
  String get logFirstMealCta => 'अपना पहला भोजन लॉग करें';

  @override
  String get mealNotLoggedYet => 'अभी लॉग नहीं हुआ';

  @override
  String get mealBreakfast => 'नाश्ता';

  @override
  String get mealLunch => 'दोपहर का भोजन';

  @override
  String get mealDinner => 'रात का भोजन';

  @override
  String get mealSnacks => 'स्नैक्स';

  @override
  String get todayTab => 'आज';

  @override
  String get diaryTab => 'डायरी';

  @override
  String get insightsTab => 'विश्लेषण';

  @override
  String get profileTab => 'प्रोफ़ाइल';

  @override
  String get diaryTitle => 'डायरी';

  @override
  String caloriesLeft(String left) {
    return '$left बची हैं';
  }

  @override
  String get nutritionBreakdown => 'पोषण विवरण';

  @override
  String get emptyDayHint =>
      'स्कैन करें या व्यंजन जोड़ें और ट्रैकिंग शुरू करें।';

  @override
  String get getStarted => 'शुरू करें';

  @override
  String get welcomeTagline => 'समझदारी से खाएँ। स्वस्थ रहें।';

  @override
  String get signIn => 'साइन इन';

  @override
  String get deviceOnlyTitle => 'Health AI इसी डिवाइस पर उपयोग करें';

  @override
  String get signInNote =>
      'Health AI ऑफ़लाइन-पहला है: यहाँ कोई अकाउंट नहीं है और कभी नहीं होगा। आपका डायरी डेटा इसी फोन पर एन्क्रिप्टेड रहता है।';

  @override
  String get okGotIt => 'ठीक है';

  @override
  String get wdMon => 'सोम';

  @override
  String get wdTue => 'मंगल';

  @override
  String get wdWed => 'बुध';

  @override
  String get wdThu => 'गुरु';

  @override
  String get wdFri => 'शुक्र';

  @override
  String get wdSat => 'शनि';

  @override
  String get wdSun => 'रवि';

  @override
  String ofTargets(String percent) {
    return '$percent लक्ष्य पूरा';
  }

  @override
  String get mealLog => 'भोजन लॉग';

  @override
  String get scanScreenTitle => 'भोजन स्कैन';

  @override
  String get pointAtPlate => 'कैमरा अपनी थाली की ओर रखें';

  @override
  String get cameraPlaceholder =>
      'कैमरा पूर्वावलोकन ऑन-डिवाइस मॉडल के साथ आएगा (M2)।';

  @override
  String get scanResultTitle => 'स्कैन परिणाम';

  @override
  String get scanResultSubtitle => 'शीर्ष 3 संभावित मेल';

  @override
  String get servingSizeLabel => 'परोसने का आकार';

  @override
  String get estimatedCalories => 'अनुमानित कैलोरी';

  @override
  String addToMeal(String meal) {
    return '$meal में जोड़ें';
  }

  @override
  String addedToast(String meal) {
    return '$meal में जोड़ा गया।';
  }

  @override
  String get undo => 'पूर्ववत';

  @override
  String get insightsTitle => 'विश्लेषण';

  @override
  String get calorieTrend => 'कैलोरी रुझान';

  @override
  String get avgKcalPerDay => 'औसत कैलोरी/दिन';

  @override
  String trendChangeUp(String percent) {
    return '↑ $percent%';
  }

  @override
  String trendChangeDown(String percent) {
    return '↓ $percent%';
  }

  @override
  String get nutritionBalance => 'पोषण संतुलन';

  @override
  String get profileTitle => 'प्रोफ़ाइल';

  @override
  String get deviceOnly => 'आपका डेटा इसी डिवाइस पर रहता है।';

  @override
  String get myGoals => 'मेरे लक्ष्य';

  @override
  String get settingsRow => 'सेटिंग्स';

  @override
  String get helpRow => 'सहायता';

  @override
  String get aboutRow => 'ऐप के बारे में';
}
