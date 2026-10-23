// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Panjabi Punjabi (`pa`).
class AppLocalizationsPa extends AppLocalizations {
  AppLocalizationsPa([String locale = 'pa']) : super(locale);

  @override
  String get appTitle => 'Health AI';

  @override
  String get greetingMorning => 'ਸ਼ੁਭ ਸਵੇਰ!';

  @override
  String get greetingAfternoon => 'ਨਮਸਕਾਰ!';

  @override
  String get greetingEvening => 'ਸ਼ੁਭ ਸ਼ਾਮ!';

  @override
  String get todayTagline => 'ਸਿਹਤਮੰਦ ਜੀਵਨ ਲਈ ਆਪਣੇ ਸਰੀਰ ਨੂੰ ਪੌਸ਼ਟਿਕ ਭੋਜਨ ਦਿਓ।';

  @override
  String get remainingKcal => 'ਬਾਕੀ';

  @override
  String get kcalUnit => 'ਕੈਲੋਰੀ';

  @override
  String get macroProtein => 'ਪ੍ਰੋਟੀਨ';

  @override
  String get macroCarbs => 'ਕਾਰਬਜ਼';

  @override
  String get macroFat => 'ਫੈਟ';

  @override
  String get stepsTile => 'ਕਦਮ';

  @override
  String get waterTile => 'ਪਾਣੀ';

  @override
  String get sleepTile => 'ਨੀਂਦ';

  @override
  String get todaysMeals => 'ਅੱਜ ਦਾ ਭੋਜਨ';

  @override
  String get caloriesLabel => 'ਕੈਲੋਰੀ';

  @override
  String get addFood => 'ਭੋਜਨ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get logFirstMealCta => 'ਆਪਣਾ ਪਹਿਲਾ ਭੋਜਨ ਦਰਜ ਕਰੋ';

  @override
  String get mealNotLoggedYet => 'ਹਾਲੇ ਦਰਜ ਨਹੀਂ';

  @override
  String get mealBreakfast => 'ਨਾਸ਼ਤਾ';

  @override
  String get mealLunch => 'ਦੁਪਹਿਰ ਦਾ ਖਾਣਾ';

  @override
  String get mealDinner => 'ਸ਼ਾਮ ਦਾ ਖਾਣਾ';

  @override
  String get mealSnacks => 'ਸਨੈਕਸ';

  @override
  String get todayTab => 'ਅੱਜ';

  @override
  String get diaryTab => 'ਡਾਇਰੀ';

  @override
  String get insightsTab => 'ਵਿਸ਼ਲੇਸ਼ਣ';

  @override
  String get profileTab => 'ਪ੍ਰੋਫਾਈਲ';

  @override
  String get diaryTitle => 'ਡਾਇਰੀ';

  @override
  String caloriesLeft(String left) {
    return '$left ਬਾਕੀ';
  }

  @override
  String get nutritionBreakdown => 'ਪੋਸ਼ਣ ਵੇਰਵਾ';

  @override
  String get emptyDayHint =>
      'ਸਕੈਨ ਕਰੋ ਜਾਂ ਵਾਂਝਾ ਪਕਵਾਨ ਜੋੜੋ ਤੇ ਟਰੈਕਿੰਗ ਸ਼ੁਰੂ ਕਰੋ।';

  @override
  String get getStarted => 'ਸ਼ੁਰੂ ਕਰੋ';

  @override
  String get welcomeTagline => 'ਸਮਝਦਾਰੀ ਨਾਲ ਖਾਓ। ਸਿਹਤਮੰਦ ਰਹੋ।';

  @override
  String get signIn => 'ਸਾਈਨ ਇਨ';

  @override
  String get deviceOnlyTitle => 'Health AI ਇਸੇ ਡਿਵਾਈਸ ਉੱਤੇ ਵਰਤੋ';

  @override
  String get signInNote =>
      'Health AI ਆਫ਼ਲਾਈਨ-ਪਹਿਲਾ ਹੈ: ਇੱਥੇ ਕੋਈ ਖਾਤਾ ਨਹੀਂ ਅਤੇ ਕਦੇ ਨਹੀਂ ਹੋਵੇਗਾ। ਤੁਹਾਡਾ ਡਾਇਰੀ ਡਾਟਾ ਇਸੇ ਫੋਨ ਉੱਤੇ ਐਨਕ੍ਰਿਪਟਡ ਰਹਿੰਦਾ ਹੈ।';

  @override
  String get okGotIt => 'ਠੀਕ ਹੈ';

  @override
  String get wdMon => 'ਸੋਮ';

  @override
  String get wdTue => 'ਮੰਗਲ';

  @override
  String get wdWed => 'ਬੁੱਧ';

  @override
  String get wdThu => 'ਵੀਰ';

  @override
  String get wdFri => 'ਸ਼ੁੱਕਰ';

  @override
  String get wdSat => 'ਸ਼ਨਿ';

  @override
  String get wdSun => 'ਐਤ';

  @override
  String ofTargets(String percent) {
    return '$percent ਟੀਚਾ ਪੂਰਾ';
  }

  @override
  String get ofTargetsCaption => 'ਟਾਰਗਿਟਾਂ ਦਾ';

  @override
  String get mealLog => 'ਭੋਜਨ ਰਿਕਾਰਡ';

  @override
  String get scanScreenTitle => 'ਭੋਜਨ ਸਕੈਨ';

  @override
  String get pointAtPlate => 'ਕੈਮਰਾ ਆਪਣੀ ਥਾਲੀ ਵੱਲ ਰੱਖੋ';

  @override
  String get cameraPlaceholder =>
      'ਕੈਮਰਾ ਝਲਕ ਡਿਵਾਈਸ ਉੱਤੇ ਮਾਡਲ ਦੇ ਨਾਲ ਆਵੇਗੀ (M2)।';

  @override
  String get scanResultTitle => 'ਸਕੈਨ ਨਤੀਜਾ';

  @override
  String get scanResultSubtitle => 'ਚੋਟੀ ਦੇ 3 ਸੰਭਾਵਿਤ ਮੇਲ';

  @override
  String get servingSizeLabel => 'ਪਰੋਸਣ ਦਾ ਆਕਾਰ';

  @override
  String get estimatedCalories => 'ਅੰਦਾਜ਼ਨ ਕੈਲੋਰੀ';

  @override
  String addToMeal(String meal) {
    return '$meal ਵਿੱਚ ਸ਼ਾਮਲ ਕਰੋ';
  }

  @override
  String addedToast(String meal) {
    return '$meal ਵਿੱਚ ਸ਼ਾਮਲ ਕੀਤਾ ਗਿਆ।';
  }

  @override
  String get undo => 'ਵਾਪਸ ਲਵੋ';

  @override
  String get insightsTitle => 'ਵਿਸ਼ਲੇਸ਼ਣ';

  @override
  String get calorieTrend => 'ਕੈਲੋਰੀ ਰੁਝਾਨ';

  @override
  String get avgKcalPerDay => 'ਔਸਤ ਕੈਲੋਰੀ/ਦਿਨ';

  @override
  String trendChangeUp(String percent) {
    return '↑ $percent%';
  }

  @override
  String trendChangeDown(String percent) {
    return '↓ $percent%';
  }

  @override
  String get nutritionBalance => 'ਪੋਸ਼ਣ ਸੰਤੁਲਨ';

  @override
  String get profileTitle => 'ਪ੍ਰੋਫਾਈਲ';

  @override
  String get deviceOnly => 'ਤੁਹਾਡਾ ਡਾਟਾ ਇਸੇ ਡਿਵਾਈਸ ਉੱਤੇ ਰਹਿੰਦਾ ਹੈ।';

  @override
  String get myGoals => 'ਮੇਰੇ ਟੀਚੇ';

  @override
  String get settingsRow => 'ਸੈਟਿੰਗਾਂ';

  @override
  String get helpRow => 'ਮਦਦ';

  @override
  String get aboutRow => 'ਐਪ ਬਾਰੇ';

  @override
  String get closeLabel => 'ਬੰਦ ਕਰੋ';

  @override
  String get scanTorch => 'ਟਾਰਚ ਬਦਲੋ';

  @override
  String get scanCapture => 'ਫੋਟੋ ਲਵੋ';

  @override
  String get scanCameraUnavailableTitle => 'ਕੈਮਰਾ ਉਪਲਬਧ ਨਹੀਂ';

  @override
  String get scanCameraUnavailableHint =>
      'ਕੈਮਰਾ ਇਜਾਜ਼ਤ ਜਾਂਚੋ, ਜਾਂ ਗੈਲਰੀ ਤੋਂ ਫੋਟੋ ਚੁਣੋ।';

  @override
  String get scanPickFromGallery => 'ਗੈਲਰੀ ਤੋਂ ਚੁਣੋ';

  @override
  String get scanAnalyzing => 'ਤੁਹਾਡੀ ਥਾਲੀ ਪੜ੍ਹੀ ਜਾ ਰਹੀ ਹੈ…';

  @override
  String scanAnalyzingHint(int count) {
    return 'ਇਸ ਡਿਵਾਈਸ \'ਤੇ ਭਾਰਤੀ ਪਕਵਾਨਾਂ ਨਾਲ ਮਿਲਾਨ।';
  }

  @override
  String get scanModelMissing =>
      'ਇਸ ਬਿਲਡ ਵਿੱਚ ਪਛਾਣ ਮਾਡਲ ਨਹੀਂ ਇੰਸਟਾਲ, ਇਸ ਲਈ ਸਕੈਨ ਉਪਲਬਧ ਨਹੀਂ।';

  @override
  String get scanPhotoFailed => 'ਉਹ ਫੋਟੋ ਪੜ੍ਹੀ ਨਹੀਂ ਜਾ ਸਕੀ। ਦੂਜੀ ਫੋਟੋ ਅਜ਼ਮਾਓ।';

  @override
  String get scanUncertainHint =>
      'ਘੱਟ ਭਰੋਸਾ — ਸ਼ਾਮਲ ਕਰਨ ਤੋਂ ਪਹਿਲਾਂ ਪਕਵਾਨ ਅਤੇ ਸਮੱਗਰੀ ਜਾਂਚੋ।';

  @override
  String get scanDetecting => 'ਪਛਾਣ ਰਹੇ ਹਾਂ…';

  @override
  String get scanNotFoodTitle => 'ਇਹ ਖਾਣ ਵਾਲੀ ਚੀਜ਼ ਨਹੀਂ ਹੈ';

  @override
  String get scanNotFoodBody =>
      'ਇਸ ਫੋਟੋ ਵਿੱਚ ਕੋਈ ਪਕਵਾਨ ਨਹੀਂ ਮਿਲਿਆ। ਫੋਟੋ ਵਿੱਚ ਖਾਣਾ ਵੱਧ ਭਰ ਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ, ਜਾਂ ਪਕਵਾਨ ਦਾ ਨਾਂ ਲੱਭੋ।';

  @override
  String get scanTryAgain => 'ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ';

  @override
  String get scanSearchManually => 'ਖੁਦ ਲੱਭੋ';

  @override
  String get scanTorchOn => 'ਲਾਈਟ ਚਾਲੂ ਕਰੋ';

  @override
  String get scanTorchOff => 'ਲਾਈਟ ਬੰਦ ਕਰੋ';

  @override
  String get scanCaptureHeading => 'ਆਪਣਾ ਖਾਣਾ ਕੈਪਚਰ ਕਰੋ';

  @override
  String get scanCaptureHint => 'ਫਰੇਮ ਨੂੰ ਇੱਕ ਪਕਵਾਨ ਉੱਤੇ ਰੱਖੋ ਅਤੇ ਸ਼ਟਰ ਦਬਾਓ।';

  @override
  String get scanQuickAdd => 'ਨਾਂ ਨਾਲ ਖਾਣਾ ਛੇਤੀ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get quickAddTitle => 'ਛੇਤੀ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get quickAddSubtitle =>
      'ਤੁਹਾਡੇ ਡਿਵਾਈਸ ਵਿੱਚ ਮੌਜੂਦ ਪਕਵਾਨ ਲੱਭੋ। ਕੁਝ ਵੀ ਕਿਤੇ ਨਹੀਂ ਭੇਜਿਆ ਜਾਂਦਾ।';

  @override
  String get quickAddSearchHint => 'ਪਕਵਾਨ ਲੱਭੋ';

  @override
  String get quickAddPicks => 'ਛੇਤੀ ਚੋਣਾਂ';

  @override
  String get quickAddNoMatch =>
      'ਇਸ ਨਾਲ ਕੋਈ ਪਕਵਾਨ ਨਹੀਂ ਮਿਲਿਆ। ਛੋਟਾ ਸ਼ਬਦ ਅਜ਼ਮਾਓ ਜਾਂ ਸ਼ਬਦ-ਜੋੜ ਵੇਖੋ।';

  @override
  String get quickAddNoNutrition => 'ਹਾਲੇ ਪੋਸ਼ਣ ਡੇਟਾ ਨਹੀਂ';

  @override
  String get quickAddUnavailable =>
      'ਪਕਵਾਨ ਸੂਚੀ ਲੋਡ ਨਹੀਂ ਹੋਈ, ਇਸ ਲਈ ਛੇਤੀ ਸ਼ਾਮਲ ਕਰਨਾ ਉਪਲਬਧ ਨਹੀਂ। ਥੋੜ੍ਹੀ ਦੇਰ ਬਾਅਦ ਕੋਸ਼ਿਸ਼ ਕਰੋ।';

  @override
  String get settingsTitle => 'ਸੈਟਿੰਗਾਂ';

  @override
  String get settingsSubtitle => 'Health AI ਨੂੰ ਆਪਣਾ ਬਣਾਓ।';

  @override
  String get appearanceTitle => 'ਰੂਪ';

  @override
  String get appearanceHint =>
      'ਸਿਸਟਮ ਤੁਹਾਡੇ ਫ਼ੋਨ ਦੀ ਲਾਈਟ ਜਾਂ ਡਾਰਕ ਸੈਟਿੰਗ ਅਪਣਾਉਂਦਾ ਹੈ।';

  @override
  String get themeSystem => 'ਸਿਸਟਮ';

  @override
  String get themeLight => 'ਲਾਈਟ';

  @override
  String get themeDark => 'ਡਾਰਕ';

  @override
  String get doneLabel => 'ਹੋ ਗਿਆ';

  @override
  String get privacyTitle => 'ਨਿੱਜੀ ਡਿਜ਼ਾਈਨ';

  @override
  String get privacyBody =>
      'ਤੁਹਾਡਾ ਭੋਜਨ, ਕਦਮ ਅਤੇ ਫ਼ੋਟੋ ਇਸੇ ਡਿਵਾਈਸ \'ਤੇ ਰਹਿੰਦੇ ਹਨ। ਕੋਈ ਖਾਤਾ ਨਹੀਂ, ਕੋਈ ਕਲਾਊਡ ਨਹੀਂ।';

  @override
  String get helpTitle => 'ਮਦਦ';

  @override
  String get helpSubtitle => 'ਛੋਟੇ ਜਵਾਬ, ਸਭ ਆਫ਼ਲਾਈਨ।';

  @override
  String get helpScanQ => 'ਮੈਂ ਪਕਵਾਨ ਕਿਵੇਂ ਸਕੈਨ ਕਰਾਂ?';

  @override
  String get helpScanA =>
      'ਹਰਾ ਕੈਮਰਾ ਬਟਨ ਦਬਾਓ, ਫ਼ੋਟੋ ਲਵੋ ਜਾਂ ਚੁਣੋ, ਫਿਰ ਸ਼ਾਮਲ ਕਰਨ ਤੋਂ ਪਹਿਲਾਂ ਸਹੀ ਮੇਲ ਦੀ ਪੁਸ਼ਟੀ ਕਰੋ।';

  @override
  String get helpCaloriesQ => 'ਕੀ ਕੈਲੋਰੀ ਸਹੀ ਹਨ?';

  @override
  String get helpCaloriesA =>
      'ਇਹ ਪਕਵਾਨ ਅਤੇ ਪਰੋਸ ਦੇ ਆਕਾਰ \'ਤੇ ਅਧਾਰਿਤ ਅੰਦਾਜ਼ੇ ਹਨ। ਪਰੋਸ ਦਾ ਆਕਾਰ ਸਭ ਤੋਂ ਵੱਡੀ ਗਲਤੀ ਦਾ ਕਾਰਨ ਹੈ।';

  @override
  String get helpStepsQ => 'ਕਦਮਾਂ ਵਿੱਚ ਡੈਸ਼ ਕਿਉਂ ਦਿਖਦਾ ਹੈ?';

  @override
  String get helpStepsA =>
      'Android ਦੇ ਪੁੱਛਣ \'ਤੇ ਸਰੀਰਕ ਸਰਗਰਮੀ ਦੀ ਇਜਾਜ਼ਤ ਦਿਓ। ਫ਼ੋਨ ਵਿੱਚ ਕਦਮ ਗਿਣਨ ਵਾਲਾ ਹੋਣਾ ਚਾਹੀਦਾ ਹੈ; ਦਿਨ ਦੀ ਪਹਿਲੀ ਰੀਡਿੰਗ ਤੋਂ ਕਦਮ ਗਿਣੇ ਜਾਂਦੇ ਹਨ।';

  @override
  String get helpOfflineQ => 'ਕੀ ਐਪ ਨੂੰ ਇੰਟਰਨੈੱਟ ਚਾਹੀਦਾ ਹੈ?';

  @override
  String get helpOfflineA =>
      'ਨਹੀਂ। ਪਛਾਣ, ਡਾਇਰੀ ਅਤੇ ਕਦਮ ਟਰੈਕਿੰਗ ਤੁਹਾਡੇ ਫ਼ੋਨ \'ਤੇ ਚੱਲਦੇ ਹਨ।';

  @override
  String get aboutLegalese => 'ਆਫ਼ਲਾਈਨ ਪੋਸ਼ਣ ਅਤੇ ਸਰਗਰਮੀ ਟਰੈਕਿੰਗ।';

  @override
  String get aboutPrivacy =>
      'Health AI ਵਿੱਚ ਕੋਈ ਖਾਤਾ ਅਤੇ ਕੋਈ ਕਲਾਊਡ ਸਿੰਕ ਨਹੀਂ। ਤੁਸੀਂ ਜੋ ਵੀ ਦਰਜ ਕਰਦੇ ਹੋ, ਇਸੇ ਡਿਵਾਈਸ \'ਤੇ ਰਹਿੰਦਾ ਹੈ।';

  @override
  String aboutModel(int count) {
    return 'ਭੋਜਨ ਦੀ ਪਛਾਣ ਭਾਰਤੀ ਪਕਵਾਨਾਂ \'ਤੇ ਸਿਖਲਾਈ ਪ੍ਰਾਪਤ MobileNetV4 ਮਾਡਲ ਨਾਲ ਪੂਰੀ ਤਰ੍ਹਾਂ ਡਿਵਾਈਸ \'ਤੇ ਚੱਲਦੀ ਹੈ।';
  }

  @override
  String get chooseGoal => 'ਆਪਣੇ ਲਈ ਸਹੀ ਯੋਜਨਾ ਚੁਣੋ।';

  @override
  String get goalLose => 'ਭਾਰ ਘਟਾਓ';

  @override
  String get goalLoseHint => 'ਹਲਕੀ ਕੈਲੋਰੀ ਘਾਟ';

  @override
  String get goalLoseSubtitle => '3 ਮਹੀਨਿਆਂ ਵਿੱਚ 5 ਕਿਲੋ ਘਟਾਓ';

  @override
  String get goalMaintain => 'ਭਾਰ ਬਣਾਈ ਰੱਖੋ';

  @override
  String get goalMaintainHint => 'ਖਾਣਾ ਅਤੇ ਸਰਗਰਮੀ ਸੰਤੁਲਿਤ ਕਰੋ';

  @override
  String get goalMaintainSubtitle => 'ਆਪਣਾ ਮੌਜੂਦਾ ਭਾਰ ਬਣਾਈ ਰੱਖੋ';

  @override
  String get goalGain => 'ਭਾਰ ਵਧਾਓ';

  @override
  String get goalGainHint => 'ਥੋੜ੍ਹੀ ਕੈਲੋਰੀ ਵੱਧ';

  @override
  String get goalGainSubtitle => 'ਤਾਕਤ ਅਤੇ ਆਕਾਰ ਬਣਾਓ';

  @override
  String get gramUnit => 'g';

  @override
  String get kmUnit => 'km';

  @override
  String get minPerKm => 'ਮਿੰਟ/ਕਿਮੀ';

  @override
  String get spmUnit => 'ਕਦਮ/ਮਿੰਟ';

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '$hoursਘੰ $minutesਮਿ';
  }

  @override
  String durationMinutes(String minutes) {
    return '$minutes ਮਿੰਟ';
  }

  @override
  String get dayToday => 'ਅੱਜ';

  @override
  String get dayYesterday => 'ਕੱਲ੍ਹ';

  @override
  String dayDaysAgo(int count) {
    return '$count ਦਿਨ ਪਹਿਲਾਂ';
  }

  @override
  String stepsDistanceCaption(String distance) {
    return 'ਕਦਮ · $distance ਕਿਮੀ';
  }

  @override
  String get onTrackTitle => 'ਤੁਸੀਂ ਸਹੀ ਰਾਹ \'ਤੇ ਹੋ!';

  @override
  String onTrackBody(String left, String protein) {
    return '$left ਕੈਲੋਰੀ ਬਾਕੀ · $protein ਗ੍ਰਾਮ ਪ੍ਰੋਟੀਨ ਬਾਕੀ';
  }

  @override
  String get overTargetTitle => 'ਅੱਜ ਟੀਚੇ ਤੋਂ ਥੋੜ੍ਹਾ ਵੱਧ';

  @override
  String overTargetBody(String over) {
    return 'ਟੀਚੇ ਤੋਂ $over ਕੈਲੋਰੀ ਵੱਧ। ਅਗਲਾ ਭੋਜਨ ਹਲਕਾ ਰੱਖੋ।';
  }

  @override
  String get startDayTitle => 'ਆਪਣਾ ਦਿਨ ਸ਼ੁਰੂ ਕਰੋ';

  @override
  String get startDayBody => 'ਅੱਜ ਦੀ ਕੈਲੋਰੀ ਅਤੇ ਮੈਕਰੋ ਵੇਖਣ ਲਈ ਭੋਜਨ ਦਰਜ ਕਰੋ।';

  @override
  String get quickActions => 'ਤੇਜ਼ ਕਾਰਵਾਈਆਂ';

  @override
  String get searchFood => 'ਭੋਜਨ ਖੋਜੋ';

  @override
  String get viewDiary => 'ਡਾਇਰੀ ਵੇਖੋ';

  @override
  String get activityTitle => 'ਸਰਗਰਮੀ';

  @override
  String get activitySubtitle => 'ਫ਼ੋਨ ਤੋਂ ਕਦਮ, ਦੂਰੀ ਅਤੇ ਰਫ਼ਤਾਰ।';

  @override
  String get activityToday => 'ਅੱਜ ਦੀ ਸਰਗਰਮੀ';

  @override
  String get stepsLabel => 'ਕਦਮ';

  @override
  String stepGoal(String goal) {
    return '$goal ਕਦਮਾਂ ਦਾ ਟੀਚਾ';
  }

  @override
  String get distanceLabel => 'ਦੂਰੀ';

  @override
  String get activeTimeLabel => 'ਸਰਗਰਮ ਸਮਾਂ';

  @override
  String get avgPaceLabel => 'ਔਸਤ ਰਫ਼ਤਾਰ';

  @override
  String get cadenceLabel => 'ਕੈਡੈਂਸ';

  @override
  String get todayByHour => 'ਅੱਜ ਘੰਟੇ ਅਨੁਸਾਰ';

  @override
  String get last7Days => 'ਪਿਛਲੇ 7 ਦਿਨ';

  @override
  String get historyBuildsHint => 'ਐਪ ਵਰਤੋਂ ਨਾਲ ਇਤਿਹਾਸ ਬਣੇਗਾ।';

  @override
  String get activityPermissionTitle => 'ਸਰਗਰਮੀ ਦੀ ਇਜਾਜ਼ਤ ਦਿਓ';

  @override
  String get activityPermissionBody =>
      'Health AI ਕਦਮ, ਦੂਰੀ ਅਤੇ ਰਫ਼ਤਾਰ ਦਿਖਾਉਣ ਲਈ ਫ਼ੋਨ ਦਾ ਕਦਮ ਗਿਣਨ ਵਾਲਾ ਪੜ੍ਹਦਾ ਹੈ। ਇਹ ਇਸੇ ਡਿਵਾਈਸ \'ਤੇ ਰਹਿੰਦਾ ਹੈ।';

  @override
  String get activityAllow => 'ਇਜਾਜ਼ਤ ਦਿਓ';

  @override
  String get activityOpenSettings => 'ਸੈਟਿੰਗਾਂ ਖੋਲ੍ਹੋ';

  @override
  String get activityUnsupportedTitle => 'ਕਦਮ ਸੈਂਸਰ ਨਹੀਂ ਮਿਲਿਆ';

  @override
  String get activityUnsupportedBody =>
      'ਇਹ ਡਿਵਾਈਸ ਐਪਾਂ ਨੂੰ ਕਦਮ ਗਿਣਨ ਵਾਲਾ ਨਹੀਂ ਦਿੰਦਾ। ਤੁਸੀਂ ਭੋਜਨ ਅਤੇ ਪਾਣੀ ਫਿਰ ਵੀ ਦਰਜ ਕਰ ਸਕਦੇ ਹੋ।';

  @override
  String get activityUnavailableTitle => 'ਕਦਮ ਉਪਲਬਧ ਨਹੀਂ';

  @override
  String get activityUnavailableBody =>
      'ਕਦਮ ਸੈਂਸਰ ਹੁਣ ਜਵਾਬ ਨਹੀਂ ਦੇ ਰਿਹਾ। ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ ਜਾਂ ਸਰਗਰਮੀ ਇਜਾਜ਼ਤ ਜਾਂਚੋ।';

  @override
  String get activityRefresh => 'ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ';

  @override
  String get activityPrivacyNote =>
      'ਦੂਰੀ ਔਸਤ 0.76 ਮੀਟਰ ਕਦਮ ਨਾਲ ਲਗਾਈ ਜਾਂਦੀ ਹੈ। ਸਰਗਰਮ ਸਮਾਂ ਸਿਰਫ਼ ਤੁਰਨ ਦਾ ਹੈ; ਫ਼ੋਨ ਨਾਲ ਹੋਣ \'ਤੇ ਕਦਮ ਗਿਣਦਾ ਹੈ।';

  @override
  String get waterTitle => 'ਪਾਣੀ';

  @override
  String get waterSubtitle => 'ਇੱਕ ਗਲਾਸ ਇੱਕ ਵਾਰ।';

  @override
  String get waterIntake => 'ਪਾਣੀ ਦੀ ਮਾਤਰਾ';

  @override
  String waterGoal(String goal) {
    return 'ਟੀਚਾ: $goal ਲੀਟਰ';
  }

  @override
  String get addGlass => 'ਇੱਕ ਗਲਾਸ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get removeGlass => 'ਪਿਛਲਾ ਹਟਾਓ';

  @override
  String glassesCount(String count, String goal) {
    return '$count / $goal ਗਲਾਸ';
  }

  @override
  String get waterNote =>
      'ਪਾਣੀ ਦੀ ਲੋੜ ਵੱਖਰੀ ਹੋ ਸਕਦੀ ਹੈ। ਇਹ ਸਿਰਫ਼ ਰੋਜ਼ਾਨਾ ਮਾਰਗਦਰਸ਼ਨ ਹੈ, ਡਾਕਟਰੀ ਸਲਾਹ ਨਹੀਂ।';

  @override
  String get sleepTitle => 'ਨੀਂਦ';

  @override
  String get sleepSubtitle => 'ਪਿਛਲੀ ਰਾਤ ਦਾ ਆਰਾਮ ਦਰਜ ਕਰੋ।';

  @override
  String get sleepDuration => 'ਨੀਂਦ ਦੀ ਮਿਆਦ';

  @override
  String get bedtimeLabel => 'ਸੌਣ ਦਾ ਸਮਾਂ';

  @override
  String get wakeTimeLabel => 'ਉੱਠਣ ਦਾ ਸਮਾਂ';

  @override
  String get saveSleep => 'ਨੀਂਦ ਸੰਭਾਲੋ';

  @override
  String sleepGoal(String goal) {
    return 'ਟੀਚਾ: $goal';
  }

  @override
  String get noSleepLogged => 'ਅੱਜ ਲਈ ਨੀਂਦ ਦਰਜ ਨਹੀਂ।';

  @override
  String get sleepNote =>
      'ਨੀਂਦ ਇਸੇ ਡਿਵਾਈਸ \'ਤੇ ਹੱਥੀਂ ਦਰਜ ਹੁੰਦੀ ਹੈ। ਕਿਸੇ ਵਿਅਰੇਬਲ ਜਾਂ ਖਾਤੇ ਦੀ ਲੋੜ ਨਹੀਂ।';

  @override
  String get clearSleep => 'ਹਟਾਓ';

  @override
  String get weeklyProgress => 'ਹਫ਼ਤਾਵਾਰੀ ਤਰੱਕੀ';

  @override
  String get weeklySubtitle => 'ਪਿਛਲੇ ਸੱਤ ਦਿਨ ਇੱਕ ਨਜ਼ਰ ਵਿੱਚ।';

  @override
  String get viewWeekly => 'ਹਫ਼ਤਾ ਵੇਖੋ';

  @override
  String get caloriesTab => 'ਕੈਲੋਰੀ';

  @override
  String get macrosTab => 'ਮੈਕਰੋ';

  @override
  String get mealsTab => 'ਭੋਜਨ';

  @override
  String get weeklyAverage => 'ਰੋਜ਼ਾਨਾ ਔਸਤ';

  @override
  String get daysOnTarget => 'ਟੀਚੇ \'ਤੇ ਦਿਨ';

  @override
  String get weeklyConsistency => 'ਦਰਜ ਦਿਨ';

  @override
  String get weeklyNote =>
      'ਟੀਚੇ ਤੁਹਾਡੀ ਮੌਜੂਦਾ ਯੋਜਨਾ ਦੇ ਹਨ। ਦਿਨ ਦਾ ਕੁੱਲ ਵੇਖਣ ਲਈ ਬਾਰ \'ਤੇ ਟੈਪ ਕਰੋ।';

  @override
  String get searchFoodTitle => 'ਭੋਜਨ ਖੋਜੋ';

  @override
  String searchFoodHint(int count) {
    return '$count ਭਾਰਤੀ ਪਕਵਾਨ ਖੋਜੋ';
  }

  @override
  String get categoryAll => 'ਸਾਰੇ';

  @override
  String get categoryCurry => 'ਕੜੀ';

  @override
  String get categoryBread => 'ਰੋਟੀ';

  @override
  String get categoryRice => 'ਚੌਲ';

  @override
  String get categorySnacks => 'ਸਨੈਕਸ';

  @override
  String get categorySweet => 'ਮਿਠਾਈ';

  @override
  String get categoryBeverage => 'ਪੀਣ';

  @override
  String get categoryChaat => 'ਚਾਟ';

  @override
  String get categoryKebab => 'ਕਬਾਬ';

  @override
  String get categoryPizza => 'ਪੀਜ਼ਾ';

  @override
  String get categorySouthIndian => 'ਦੱਖਣੀ ਭਾਰਤੀ';

  @override
  String get categoryFasting => 'ਵਰਤ';

  @override
  String get categoryOthers => 'ਹੋਰ';

  @override
  String get noDishesFound => 'ਕੋਈ ਪਕਵਾਨ ਨਹੀਂ ਮਿਲਿਆ';

  @override
  String get noDishesFoundHint => 'ਹੋਰ ਨਾਮ ਜਾਂ ਸ਼੍ਰੇਣੀ ਅਜ਼ਮਾਓ।';

  @override
  String get popularDishes => 'ਪ੍ਰਸਿੱਧ ਪਕਵਾਨ';

  @override
  String get allDishes => 'ਸਾਰੇ ਪਕਵਾਨ';

  @override
  String dishesCount(int count) {
    return '$count ਪਕਵਾਨ';
  }

  @override
  String get dishDetails => 'ਪਕਵਾਨ ਦੀ ਜਾਣਕਾਰੀ';

  @override
  String get nutritionTab => 'ਪੋਸ਼ਣ';

  @override
  String get ingredientsTab => 'ਸਮੱਗਰੀ';

  @override
  String get portionsTab => 'ਮਾਤਰਾ';

  @override
  String get per100g => 'ਪ੍ਰਤੀ 100 ਗ੍ਰਾਮ';

  @override
  String get perServing => 'ਪ੍ਰਤੀ ਪਰੋਸ';

  @override
  String get catalogNote =>
      'ਪੋਸ਼ਣ ਮੁੱਲ ਅੰਦਾਜ਼ੇ ਹਨ। ਪਕਾਉਣ ਦਾ ਤਰੀਕਾ ਅਤੇ ਮਾਤਰਾ ਬਦਲਦੀ ਹੈ।';

  @override
  String get ingredientsNote =>
      'ਸਾਡੀ ਸਥਾਨਕ ਸੂਚੀ ਦੀ ਮੁੱਖ ਸਮੱਗਰੀ। ਹਰ ਵਿਅੰਜਨ ਵੱਖਰਾ ਹੋ ਸਕਦਾ ਹੈ।';

  @override
  String get selectServing => 'ਪਰੋਸ ਚੁਣੋ';

  @override
  String get selectMeal => 'ਭੋਜਨ';

  @override
  String get addToDiary => 'ਡਾਇਰੀ ਵਿੱਚ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get mealDetails => 'ਭੋਜਨ ਦੀ ਜਾਣਕਾਰੀ';

  @override
  String get noMealEntries => 'ਇਸ ਭੋਜਨ ਲਈ ਹਾਲੇ ਕੁਝ ਦਰਜ ਨਹੀਂ।';

  @override
  String entriesCount(int count) {
    return '$count ਚੀਜ਼ਾਂ';
  }

  @override
  String get addAnother => 'ਹੋਰ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get delete => 'ਹਟਾਓ';

  @override
  String get goalLabel => 'ਟੀਚਾ';

  @override
  String get stepsToday => 'ਅੱਜ';

  @override
  String get progressLabel => 'ਤਰੱਕੀ';

  @override
  String get savedLabel => '??????? ???';

  @override
  String get catalogLoadError => '???? ???? ??? ???? ?? ????';

  @override
  String kcalLeftShort(String left) {
    return '$left ?????? ????';
  }

  @override
  String kcalOverShort(String over) {
    return '$over ?????? ???';
  }

  @override
  String get noWeeklyData => '?? ????? ??? ???? ??? ?????';
}
