// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Health AI';

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
  String get caloriesLabel => 'कैलोरी';

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
  String get ofTargetsCaption => 'लक्ष्यों का';

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

  @override
  String get closeLabel => 'बंद करें';

  @override
  String get scanTorch => 'टॉर्च टॉगल करें';

  @override
  String get scanCapture => 'फ़ोटो लें';

  @override
  String get scanCameraUnavailableTitle => 'कैमरा उपलब्ध नहीं';

  @override
  String get scanCameraUnavailableHint =>
      'कैमरा अनुमति जाँचें, या गैलरी से फ़ोटो चुनें।';

  @override
  String get scanPickFromGallery => 'गैलरी से चुनें';

  @override
  String get scanAnalyzing => 'आपकी थाली पढ़ी जा रही है…';

  @override
  String scanAnalyzingHint(int count) {
    return 'इस डिवाइस पर भारतीय व्यंजनों से मिलान।';
  }

  @override
  String get scanModelMissing =>
      'इस बिल्ड में पहचान मॉडल इंस्टॉल नहीं है, इसलिए स्कैन उपलब्ध नहीं है।';

  @override
  String get scanPhotoFailed =>
      'वह फ़ोटो पढ़ी नहीं जा सकी। दूसरी फ़ोटो आज़माएँ।';

  @override
  String get scanUncertainHint =>
      'कम भरोसा — जोड़ने से पहले व्यंजन और सामग्री जाँचें।';

  @override
  String get scanDetecting => 'पहचान रहे हैं…';

  @override
  String get scanNotFoodTitle => 'यह खाने की चीज़ नहीं है';

  @override
  String get scanNotFoodBody =>
      'इस फ़ोटो में कोई व्यंजन नहीं मिला। फ़ोटो में खाना ज़्यादा भरकर दोबारा कोशिश करें, या व्यंजन का नाम खोजें।';

  @override
  String get scanTryAgain => 'दोबारा कोशिश करें';

  @override
  String get scanSearchManually => 'खुद खोजें';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsSubtitle => 'Health AI को अपना बनाएँ।';

  @override
  String get appearanceTitle => 'रूप';

  @override
  String get appearanceHint =>
      'सिस्टम आपके फ़ोन की लाइट या डार्क सेटिंग अपनाता है।';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get doneLabel => 'हो गया';

  @override
  String get privacyTitle => 'निजी डिज़ाइन';

  @override
  String get privacyBody =>
      'आपका भोजन, कदम और फ़ोटो इसी डिवाइस पर रहते हैं। कोई अकाउंट नहीं, कोई क्लाउड नहीं।';

  @override
  String get helpTitle => 'सहायता';

  @override
  String get helpSubtitle => 'छोटे जवाब, सब ऑफ़लाइन।';

  @override
  String get helpScanQ => 'मैं व्यंजन कैसे स्कैन करूँ?';

  @override
  String get helpScanA =>
      'हरा कैमरा बटन दबाएँ, फ़ोटो लें या चुनें, फिर जोड़ने से पहले सही मेल की पुष्टि करें।';

  @override
  String get helpCaloriesQ => 'क्या कैलोरी सटीक हैं?';

  @override
  String get helpCaloriesA =>
      'ये व्यंजन और परोस के आकार पर आधारित अनुमान हैं। परोस का आकार सबसे बड़ी गलती की वजह है।';

  @override
  String get helpStepsQ => 'कदम में डैश क्यों दिखता है?';

  @override
  String get helpStepsA =>
      'Android के पूछने पर फ़िज़िकल एक्टिविटी की अनुमति दें। फ़ोन में स्टेप काउंटर होना चाहिए; दिन की पहली रीडिंग से कदम गिने जाते हैं।';

  @override
  String get helpOfflineQ => 'क्या ऐप को इंटरनेट चाहिए?';

  @override
  String get helpOfflineA =>
      'नहीं। पहचान, डायरी और कदम ट्रैकिंग आपके फ़ोन पर चलते हैं।';

  @override
  String get aboutLegalese => 'ऑफ़लाइन पोषण और गतिविधि ट्रैकिंग।';

  @override
  String get aboutPrivacy =>
      'Health AI में कोई अकाउंट और कोई क्लाउड सिंक नहीं है। आप जो भी दर्ज करते हैं, इसी डिवाइस पर रहता है।';

  @override
  String aboutModel(int count) {
    return 'भोजन की पहचान भारतीय व्यंजनों पर प्रशिक्षित MobileNetV4 मॉडल के साथ पूरी तरह डिवाइस पर चलती है।';
  }

  @override
  String get chooseGoal => 'अपने लिए सही योजना चुनें।';

  @override
  String get goalLose => 'वज़न घटाएँ';

  @override
  String get goalLoseHint => 'हल्का कैलोरी घाटा';

  @override
  String get goalLoseSubtitle => '3 महीने में 5 किलो घटाएँ';

  @override
  String get goalMaintain => 'वज़न बनाए रखें';

  @override
  String get goalMaintainHint => 'खाना और गतिविधि संतुलित करें';

  @override
  String get goalMaintainSubtitle => 'अपना मौजूदा वज़न बनाए रखें';

  @override
  String get goalGain => 'वज़न बढ़ाएँ';

  @override
  String get goalGainHint => 'थोड़ा कैलोरी अधिक';

  @override
  String get goalGainSubtitle => 'ताकत और आकार बनाएँ';

  @override
  String get gramUnit => 'g';

  @override
  String get kmUnit => 'km';

  @override
  String get minPerKm => 'मिनट/किमी';

  @override
  String get spmUnit => 'कदम/मिनट';

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '$hoursघं $minutesमि';
  }

  @override
  String durationMinutes(String minutes) {
    return '$minutes मिनट';
  }

  @override
  String get dayToday => 'आज';

  @override
  String get dayYesterday => 'कल';

  @override
  String dayDaysAgo(int count) {
    return '$count दिन पहले';
  }

  @override
  String stepsDistanceCaption(String distance) {
    return 'कदम · $distance किमी';
  }

  @override
  String get onTrackTitle => 'आप सही रास्ते पर हैं!';

  @override
  String onTrackBody(String left, String protein) {
    return '$left कैलोरी बाकी · $protein ग्राम प्रोटीन बाकी';
  }

  @override
  String get overTargetTitle => 'आज लक्ष्य से थोड़ा ज़्यादा';

  @override
  String overTargetBody(String over) {
    return 'लक्ष्य से $over कैलोरी ज़्यादा। अगला भोजन हल्का रखें।';
  }

  @override
  String get startDayTitle => 'अपना दिन शुरू करें';

  @override
  String get startDayBody =>
      'आज की कैलोरी और मैक्रो देखने के लिए भोजन लॉग करें।';

  @override
  String get quickActions => 'जल्दी काम';

  @override
  String get searchFood => 'भोजन खोजें';

  @override
  String get viewDiary => 'डायरी देखें';

  @override
  String get activityTitle => 'गतिविधि';

  @override
  String get activitySubtitle => 'फ़ोन से कदम, दूरी और गति।';

  @override
  String get activityToday => 'आज की गतिविधि';

  @override
  String get stepsLabel => 'कदम';

  @override
  String stepGoal(String goal) {
    return '$goal कदम का लक्ष्य';
  }

  @override
  String get distanceLabel => 'दूरी';

  @override
  String get activeTimeLabel => 'सक्रिय समय';

  @override
  String get avgPaceLabel => 'औसत गति';

  @override
  String get cadenceLabel => 'कैडेंस';

  @override
  String get todayByHour => 'आज घंटे के अनुसार';

  @override
  String get last7Days => 'पिछले 7 दिन';

  @override
  String get historyBuildsHint => 'ऐप इस्तेमाल करने के साथ इतिहास बनेगा।';

  @override
  String get activityPermissionTitle => 'गतिविधि की अनुमति दें';

  @override
  String get activityPermissionBody =>
      'Health AI कदम, दूरी और गति दिखाने के लिए फ़ोन का स्टेप काउंटर पढ़ता है। यह इसी डिवाइस पर रहता है।';

  @override
  String get activityAllow => 'अनुमति दें';

  @override
  String get activityOpenSettings => 'सेटिंग्स खोलें';

  @override
  String get activityUnsupportedTitle => 'स्टेप सेंसर नहीं मिला';

  @override
  String get activityUnsupportedBody =>
      'यह डिवाइस ऐप्स को स्टेप काउंटर नहीं देता। आप भोजन और पानी फिर भी लॉग कर सकते हैं।';

  @override
  String get activityUnavailableTitle => 'कदम उपलब्ध नहीं';

  @override
  String get activityUnavailableBody =>
      'स्टेप सेंसर अभी जवाब नहीं दे रहा। फिर कोशिश करें या गतिविधि अनुमति जाँचें।';

  @override
  String get activityRefresh => 'फिर कोशिश करें';

  @override
  String get activityPrivacyNote =>
      'दूरी औसत 0.76 मीटर कदम से लगाई जाती है। सक्रिय समय सिर्फ़ चलने के समय का है; फ़ोन साथ होने पर कदम गिनता है।';

  @override
  String get waterTitle => 'पानी';

  @override
  String get waterSubtitle => 'एक गिलास एक बार में।';

  @override
  String get waterIntake => 'पानी की मात्रा';

  @override
  String waterGoal(String goal) {
    return 'लक्ष्य: $goal लीटर';
  }

  @override
  String get addGlass => 'एक गिलास जोड़ें';

  @override
  String get removeGlass => 'पिछला हटाएँ';

  @override
  String glassesCount(String count, String goal) {
    return '$count / $goal गिलास';
  }

  @override
  String get waterNote =>
      'पानी की ज़रूरत अलग-अलग होती है। यह सिर्फ़ एक दैनिक मार्गदर्शन है, चिकित्सा सलाह नहीं।';

  @override
  String get sleepTitle => 'नींद';

  @override
  String get sleepSubtitle => 'पिछली रात का आराम दर्ज करें।';

  @override
  String get sleepDuration => 'नींद की अवधि';

  @override
  String get bedtimeLabel => 'सोने का समय';

  @override
  String get wakeTimeLabel => 'जागने का समय';

  @override
  String get saveSleep => 'नींद सहेजें';

  @override
  String sleepGoal(String goal) {
    return 'लक्ष्य: $goal';
  }

  @override
  String get noSleepLogged => 'आज के लिए नींद दर्ज नहीं है।';

  @override
  String get sleepNote =>
      'नींद इसी डिवाइस पर मैन्युअल रूप से दर्ज होती है। किसी वियरेबल या अकाउंट की ज़रूरत नहीं।';

  @override
  String get clearSleep => 'हटाएँ';

  @override
  String get weeklyProgress => 'साप्ताहिक प्रगति';

  @override
  String get weeklySubtitle => 'पिछले सात दिन एक नज़र में।';

  @override
  String get viewWeekly => 'सप्ताह देखें';

  @override
  String get caloriesTab => 'कैलोरी';

  @override
  String get macrosTab => 'मैक्रो';

  @override
  String get mealsTab => 'भोजन';

  @override
  String get weeklyAverage => 'दैनिक औसत';

  @override
  String get daysOnTarget => 'लक्ष्य पर दिन';

  @override
  String get weeklyConsistency => 'दर्ज किए दिन';

  @override
  String get weeklyNote =>
      'लक्ष्य आपकी वर्तमान योजना के हैं। दिन का कुल देखने के लिए बार पर टैप करें।';

  @override
  String get searchFoodTitle => 'भोजन खोजें';

  @override
  String searchFoodHint(int count) {
    return '$count भारतीय व्यंजन खोजें';
  }

  @override
  String get categoryAll => 'सभी';

  @override
  String get categoryCurry => 'करी';

  @override
  String get categoryBread => 'रोटी';

  @override
  String get categoryRice => 'चावल';

  @override
  String get categorySnacks => 'स्नैक्स';

  @override
  String get categorySweet => 'मिठाई';

  @override
  String get categoryBeverage => 'पेय';

  @override
  String get categoryChaat => 'चाट';

  @override
  String get categoryKebab => 'कबाब';

  @override
  String get categoryPizza => 'पिज़्ज़ा';

  @override
  String get categorySouthIndian => 'दक्षिण भारतीय';

  @override
  String get categoryFasting => 'व्रत';

  @override
  String get categoryOthers => 'अन्य';

  @override
  String get noDishesFound => 'कोई व्यंजन नहीं मिला';

  @override
  String get noDishesFoundHint => 'दूसरा नाम या श्रेणी आज़माएँ।';

  @override
  String get popularDishes => 'लोकप्रिय व्यंजन';

  @override
  String get allDishes => 'सभी व्यंजन';

  @override
  String dishesCount(int count) {
    return '$count व्यंजन';
  }

  @override
  String get dishDetails => 'व्यंजन की जानकारी';

  @override
  String get nutritionTab => 'पोषण';

  @override
  String get ingredientsTab => 'सामग्री';

  @override
  String get portionsTab => 'मात्रा';

  @override
  String get per100g => 'प्रति 100 ग्राम';

  @override
  String get perServing => 'प्रति परोस';

  @override
  String get catalogNote =>
      'पोषण मान अनुमान हैं। पकाने का तरीका और मात्रा बदलती है।';

  @override
  String get ingredientsNote =>
      'हमारी स्थानीय सूची की मुख्य सामग्री। हर रेसिपी अलग हो सकती है।';

  @override
  String get selectServing => 'परोस चुनें';

  @override
  String get selectMeal => 'भोजन';

  @override
  String get addToDiary => 'डायरी में जोड़ें';

  @override
  String get mealDetails => 'भोजन की जानकारी';

  @override
  String get noMealEntries => 'इस भोजन के लिए अभी कुछ दर्ज नहीं है।';

  @override
  String entriesCount(int count) {
    return '$count चीज़ें';
  }

  @override
  String get addAnother => 'और जोड़ें';

  @override
  String get delete => 'हटाएँ';

  @override
  String get goalLabel => 'लक्ष्य';

  @override
  String get stepsToday => 'आज';

  @override
  String get progressLabel => 'प्रगति';

  @override
  String get savedLabel => '????? ???';

  @override
  String get catalogLoadError => '???? ???? ??? ???? ?? ????';

  @override
  String kcalLeftShort(String left) {
    return '$left ?????? ????';
  }

  @override
  String kcalOverShort(String over) {
    return '$over ?????? ???????';
  }

  @override
  String get noWeeklyData => '?? ?????? ??? ???? ???? ???? ???';
}
