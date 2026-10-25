import 'package:app/data/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression tests for the storage bug that lost logged food, water,
/// sleep and steps on relaunch. The cause was trusting the Android
/// keystore copy as the source of truth: when it failed,
/// flutter_secure_storage 9.2.4 wiped every key and then reported
/// *success*, handing back the string "Data has been reset" in place of
/// the caller's JSON. Nothing threw, so no fallback ran, and the day's
/// log was deleted from disk as "corrupt".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppLocalStorage.clearMemoryCacheForTest();
    SharedPreferences.setMockInitialValues({});
  });

  group('sanitize', () {
    // The exact sentinel from FlutterSecureStoragePlugin.java: the
    // plugin's error path calls deleteAll() and then
    // result.success("Data has been reset").
    test('rejects the plugin reset sentinel instead of treating it as data', () {
      expect(AppLocalStorage.sanitize('Data has been reset'), isNull);
    });

    test('rejects absent and blank values', () {
      expect(AppLocalStorage.sanitize(null), isNull);
      expect(AppLocalStorage.sanitize(''), isNull);
      expect(AppLocalStorage.sanitize('   '), isNull);
    });

    test('passes real payloads through untouched', () {
      const payload = '{"baseDate":"2026-10-24T00:00:00.000","days":{}}';
      expect(AppLocalStorage.sanitize(payload), payload);
    });

    test('does not mangle a payload that merely mentions the sentinel', () {
      const payload = '{"note":"Data has been reset"}';
      expect(AppLocalStorage.sanitize(payload), payload);
    });
  });

  group('round trip', () {
    test('a written string is readable', () async {
      await AppLocalStorage.writeString('k', 'v');
      expect(await AppLocalStorage.readString('k'), 'v');
    });

    test('a written value replaces the previous one', () async {
      await AppLocalStorage.writeString('k', 'first');
      await AppLocalStorage.writeString('k', 'second');
      expect(await AppLocalStorage.readString('k'), 'second');
    });

    test('booleans round trip', () async {
      await AppLocalStorage.writeBool('flag', true);
      expect(await AppLocalStorage.readBool('flag'), isTrue);
      await AppLocalStorage.writeBool('flag', false);
      expect(await AppLocalStorage.readBool('flag'), isFalse);
    });

    test('an unknown key reads as absent, not as empty string', () async {
      expect(await AppLocalStorage.readString('nope'), isNull);
      expect(await AppLocalStorage.readBool('nope'), isNull);
    });

    test('remove deletes the value', () async {
      await AppLocalStorage.writeString('k', 'v');
      await AppLocalStorage.remove('k');
      expect(await AppLocalStorage.readString('k'), isNull);
    });

    test('a value survives a simulated relaunch', () async {
      await AppLocalStorage.writeString('food.log.v2', '{"days":{"0":[]}}');

      // A relaunch constructs nothing new: the store is process-wide
      // preferences plus the keystore mirror. Reading through a fresh
      // instance is what bootstrap does.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('food.log.v2'), '{"days":{"0":[]}}');
      expect(
        await AppLocalStorage.readString('food.log.v2'),
        '{"days":{"0":[]}}',
      );
    });

    test('a sentinel left behind by an older build is not returned', () async {
      // An older build could have persisted the sentinel itself.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('k', 'Data has been reset');
      expect(await AppLocalStorage.readString('k'), isNull);
    });

    test('an empty value is never persisted as if it were data', () async {
      await AppLocalStorage.writeString('k', 'Data has been reset');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('k'), isNull);
    });

    test('readBool reads correctly when saved as boolean in SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('bool_flag', true);
      expect(await AppLocalStorage.readBool('bool_flag'), isTrue);
      await prefs.setBool('bool_flag', false);
      expect(await AppLocalStorage.readBool('bool_flag'), isFalse);
    });

    test('readBool reads correctly when saved as string in SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('str_flag', 'true');
      expect(await AppLocalStorage.readBool('str_flag'), isTrue);
      await prefs.setString('str_flag', 'false');
      expect(await AppLocalStorage.readBool('str_flag'), isFalse);
    });
  });
}
