import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for app state (diary, water, sleep, steps, profile,
/// settings).
///
/// Multi-layer durability strategy:
/// 1. Synchronous atomic file persistence (`app_kv_store.json`) with `flush: true`
///    to guarantee durability even if Android kills the process when swiped away.
/// 2. [SharedPreferences] as authoritative standard Flutter store.
/// 3. Serialized, timeout-guarded [FlutterSecureStorage] ([_SecureMirror])
///    as a best-effort fallback mirror.
class AppLocalStorage {
  AppLocalStorage._();

  static final Map<String, String> _memCache = <String, String>{};
  static bool _durableLoaded = false;

  @visibleForTesting
  static void clearMemoryCacheForTest() {
    _memCache.clear();
    _durableLoaded = false;
  }

  static File? _getFile() {
    if (kIsWeb) return null;
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return null;
      }
      if (Platform.isAndroid) {
        final d1 = Directory('/data/user/0/com.anshuldhiman.app/files');
        if (d1.existsSync()) return File('${d1.path}/app_kv_store.json');
        final d2 = Directory('/data/data/com.anshuldhiman.app/files');
        if (d2.existsSync()) return File('${d2.path}/app_kv_store.json');
        try {
          d1.createSync(recursive: true);
          return File('${d1.path}/app_kv_store.json');
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  static void _ensureLoaded() {
    if (_durableLoaded) return;
    _durableLoaded = true;
    final file = _getFile();
    if (file != null && file.existsSync()) {
      try {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          final decoded = jsonDecode(content);
          if (decoded is Map) {
            for (final e in decoded.entries) {
              if (e.value is String) {
                final sanitized = sanitize(e.value as String);
                if (sanitized != null) {
                  _memCache[e.key.toString()] = sanitized;
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[AppLocalStorage] Durable file read error: $e');
      }
    }
  }

  static void _saveDurable() {
    final file = _getFile();
    if (file == null) return;
    try {
      final tmp = File('${file.path}.tmp');
      tmp.writeAsStringSync(jsonEncode(_memCache), flush: true);
      if (tmp.existsSync()) {
        tmp.renameSync(file.path);
      }
    } catch (e) {
      debugPrint('[AppLocalStorage] Durable file write error: $e');
    }
  }

  /// Read a string. Checks memory cache / durable store first,
  /// then [SharedPreferences], and finally the keystore mirror.
  static Future<String?> readString(String key) async {
    _ensureLoaded();
    if (_memCache.containsKey(key)) {
      return _memCache[key];
    }

    final fromPrefs = await _readPrefs(key);
    if (fromPrefs != null) {
      _memCache[key] = fromPrefs;
      _saveDurable();
      return fromPrefs;
    }

    // Recover from mirror if preferences copy is missing and repopulate
    final fromMirror = await _SecureMirror.read(key);
    if (fromMirror == null) return null;
    _memCache[key] = fromMirror;
    _saveDurable();
    await _writePrefs(key, fromMirror);
    return fromMirror;
  }

  /// Write a string with immediate disk flush and mirror sync.
  static Future<void> writeString(String key, String value) async {
    final clean = sanitize(value);
    if (clean == null) return;

    _ensureLoaded();
    _memCache[key] = clean;
    _saveDurable();

    await _writePrefs(key, clean);
    await _SecureMirror.write(key, clean);
  }

  static Future<void> writeBool(String key, bool value) async {
    _ensureLoaded();
    _memCache[key] = value ? 'true' : 'false';
    _saveDurable();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('[AppLocalStorage] SharedPreferences writeBool error: $e');
    }
    await _SecureMirror.write(key, value ? 'true' : 'false');
  }

  static Future<bool?> readBool(String key) async {
    _ensureLoaded();
    if (_memCache.containsKey(key)) {
      final val = _memCache[key];
      if (val == 'true') return true;
      if (val == 'false') return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.get(key);
      if (val is bool) {
        _memCache[key] = val ? 'true' : 'false';
        _saveDurable();
        return val;
      }
      if (val is String) {
        final sanitized = sanitize(val);
        if (sanitized != null) {
          final b = sanitized == 'true';
          _memCache[key] = b ? 'true' : 'false';
          _saveDurable();
          return b;
        }
      }
    } catch (e) {
      debugPrint('[AppLocalStorage] SharedPreferences readBool error: $e');
    }

    final raw = await _SecureMirror.read(key);
    if (raw == null) return null;
    final b = raw == 'true';
    _memCache[key] = b ? 'true' : 'false';
    _saveDurable();
    return b;
  }

  /// Remove a key from all stores.
  static Future<void> remove(String key) async {
    _ensureLoaded();
    _memCache.remove(key);
    _saveDurable();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      debugPrint('[AppLocalStorage] SharedPreferences remove error: $e');
    }
    await _SecureMirror.remove(key);
  }

  /// Reject values that are not data.
  static String? sanitize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed == _SecureMirror.androidResetSentinel) return null;
    return value;
  }

  static bool get _secureMirrorAvailable {
    if (kIsWeb) return false;
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    } catch (_) {}
    try {
      return WidgetsBinding.instance != null;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> _readPrefs(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.get(key);
      if (val is String) return sanitize(val);
      if (val != null) return sanitize(val.toString());
      return null;
    } catch (e) {
      debugPrint('[AppLocalStorage] SharedPreferences read error: $e');
      return null;
    }
  }

  static Future<void> _writePrefs(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('[AppLocalStorage] SharedPreferences write error: $e');
    }
  }
}

/// Keystore-backed copy of app state with serialized queue and timeout guards.
abstract final class _SecureMirror {
  _SecureMirror._();

  static const androidResetSentinel = 'Data has been reset';
  static const _storage = FlutterSecureStorage();

  // Serialized queue to prevent concurrent KeyStore operations on Android.
  static Future<void> _lock = Future<void>.value();

  static Future<T> _synchronized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _lock = _lock.then((_) async {
      try {
        final result = await action();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  static Future<String?> read(String key) async {
    if (!AppLocalStorage._secureMirrorAvailable) return null;
    return _synchronized(() async {
      try {
        final val = await _storage
            .read(key: key)
            .timeout(const Duration(seconds: 2));
        return AppLocalStorage.sanitize(val);
      } catch (e) {
        debugPrint('[AppLocalStorage] Keystore mirror read error: $e');
        return null;
      }
    });
  }

  static Future<void> write(String key, String value) async {
    if (!AppLocalStorage._secureMirrorAvailable) return;
    return _synchronized(() async {
      try {
        await _storage
            .write(key: key, value: value)
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('[AppLocalStorage] Keystore mirror write error: $e');
        try {
          await _storage
              .delete(key: key)
              .timeout(const Duration(seconds: 1));
        } catch (_) {}
      }
    });
  }

  static Future<void> remove(String key) async {
    if (!AppLocalStorage._secureMirrorAvailable) return;
    return _synchronized(() async {
      try {
        await _storage
            .delete(key: key)
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('[AppLocalStorage] Keystore mirror delete error: $e');
      }
    });
  }
}
