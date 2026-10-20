import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/domain/entities/sleep_record.dart';

const sleepPrefsKey = 'sleep.v1';

Future<SleepState> loadSavedSleep() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(sleepPrefsKey);
    if (raw != null) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return SleepState.fromJson(decoded);
      }
    }
  } catch (_) {
    // Start empty if preferences are unavailable.
  }
  return SleepState.empty();
}

/// Resolved before `runApp`; overridden in `main`.
final initialSleepProvider = Provider<SleepState>((ref) => SleepState.empty());

final sleepProvider = NotifierProvider<SleepController, SleepState>(
  SleepController.new,
);

final sleepTodayProvider = Provider<SleepRecord?>((ref) {
  return ref.watch(sleepProvider).recordFor(DateTime.now());
});

class SleepController extends Notifier<SleepState> {
  @override
  SleepState build() => ref.watch(initialSleepProvider);

  void save({required int bedMinutes, required int wakeMinutes}) {
    state = state.save(
      DateTime.now(),
      bedMinutes: bedMinutes,
      wakeMinutes: wakeMinutes,
    );
    unawaited(_persist());
  }

  void removeToday() {
    state = state.remove(DateTime.now());
    unawaited(_persist());
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(sleepPrefsKey, jsonEncode(state.toJson()));
    } catch (_) {
      // Keep the in-session value.
    }
  }
}
