import 'dart:async';

import 'package:flutter/foundation.dart';

/// In-memory ring buffer for app errors (Section 5.3, R2).
///
/// No remote reporting, no PII, no disk writes: the buffer lives for
/// the process lifetime and is surfaced in-app (and, for developers,
/// printed to the console). Size is fixed so a crash loop cannot grow
/// it without bound.
class AppLog {
  AppLog._();

  static const int capacity = 100;
  static final List<String> _entries = <String>[];

  /// Ring buffer of the most recent errors, oldest first.
  static List<String> get entries => List<String>.unmodifiable(_entries);

  /// Record an error. Safe to call from any zone.
  static void record(Object error, [StackTrace? stack]) {
    final text = stack == null
        ? error.toString()
        : '$error\n${stack.toString().split('\n').take(12).join('\n')}';
    _entries.add(text);
    while (_entries.length > capacity) {
      _entries.removeAt(0);
    }
    // Still print: `adb logcat` is the only way a developer can read
    // this from a release build.
    debugPrint('[AppLog] $text');
  }

  /// Human-readable summary used by the error screen.
  static String get summary =>
      _entries.isEmpty ? 'No errors recorded.' : _entries.last;
}

/// The last error captured by the guard, if any.
Object? _lastError;

/// Install the top-level error guards (Section 5.3).
///
/// `runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.onError`
/// catch everything the framework can throw and route it into [AppLog]
/// so a failure is *visible* instead of a silent black screen.
///
/// Returns the guarded body. Call it as the outermost wrapper of `main`.
Future<void> runAppGuarded(Future<void> Function() body) async {
  FlutterError.onError = (details) {
    AppLog.record(details.exception, details.stack);
    _lastError = details.exception;
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.record(error, stack);
    _lastError = error;
    return true;
  };

  await runZonedGuarded<Future<void>>(
    () async {
      await body();
    },
    (error, stack) {
      AppLog.record(error, stack);
      _lastError = error;
    },
  );
}

/// The last error captured by [runAppGuarded], for the fallback screen.
Object? get lastAppError => _lastError;
