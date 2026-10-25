import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/domain/entities/sleep_record.dart';

import 'package:app/data/local_storage.dart';

const sleepPrefsKey = 'sleep.v1';

Future<SleepState> loadSavedSleep() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = await AppLocalStorage.readString(sleepPrefsKey);
    if (raw != null) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return SleepState.fromJson(Map<String, dynamic>.from(decoded));
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

  Future<void> save({required int bedMinutes, required int wakeMinutes}) async {
    state = state.save(
      DateTime.now(),
      bedMinutes: bedMinutes,
      wakeMinutes: wakeMinutes,
    );
    await _persist();
  }

  Future<void> removeToday() async {
    state = state.remove(DateTime.now());
    await _persist();
  }

  Future<void> flush() => _persist();

  Future<void> _persist() async {
    try {
      await AppLocalStorage.writeString(sleepPrefsKey, jsonEncode(state.toJson()));
    } catch (_) {
      // Keep the in-session value.
    }
  }
}
