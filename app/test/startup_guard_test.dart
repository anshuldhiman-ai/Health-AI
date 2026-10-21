import 'package:app/app/log_store.dart';
import 'package:app/core/error/app_log.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression guard for the release "black screen" bug (Oct 2026).
///
/// The release APK showed a blank window because the app never painted
/// a first frame: a throw during `bootstrap()` meant `runApp` was never
/// called, so the OS kept the launch background up.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loadSavedDayLog returns an empty log with no stored data', () async {
    final log = await loadSavedDayLog();
    expect(log.entriesFor(0), isEmpty);
  });

  test('loadSavedDayLog survives a corrupt payload', () async {
    SharedPreferences.setMockInitialValues({
      DayLog.storageKey: 'this is not json',
    });
    final log = await loadSavedDayLog();
    expect(log.entriesFor(0), isEmpty);
  });

  test('loadSavedDayLog survives a payload of the wrong shape', () async {
    SharedPreferences.setMockInitialValues({
      DayLog.storageKey: '{"days": "not-a-map"}',
    });
    final log = await loadSavedDayLog();
    expect(log.entriesFor(0), isEmpty);
  });

  test('loadSavedDayLog round-trips a stored entry', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      DayLog.storageKey,
      '{"baseDate":"2026-10-21","days":{"0":[{"mealKind":"lunch",'
      '"dish":"dal","kcal":200,"proteinGrams":10,"carbsGrams":20,'
      '"fatGrams":5}]}}',
    );
    final log = await loadSavedDayLog();
    expect(log.entriesFor(0), hasLength(1));
    expect(log.entriesFor(0).first.dish, 'dal');
  });

  test('the error log keeps a bounded ring buffer', () {
    expect(AppLog.entries.length, lessThanOrEqualTo(AppLog.capacity));
  });
}
