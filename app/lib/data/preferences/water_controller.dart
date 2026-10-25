import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/domain/entities/hydration.dart';

import 'package:app/data/local_storage.dart';

const waterPrefsKey = 'water.v1';

Future<HydrationState> loadSavedWater() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = await AppLocalStorage.readString(waterPrefsKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return HydrationState.fromJson(
          Map<String, dynamic>.from(decoded),
          DateTime.now(),
        );
      }
    }
  } catch (_) {
    // Start empty if preferences are unavailable.
  }
  return HydrationState.empty(DateTime.now());
}

/// Resolved before `runApp`; overridden in `main`.
final initialWaterProvider = Provider<HydrationState>(
  (ref) => HydrationState.empty(DateTime.now()),
);

final waterProvider = NotifierProvider<WaterController, HydrationState>(
  WaterController.new,
);

/// Always reflects today, even if the app stayed open over midnight.
final waterTodayProvider = Provider<HydrationState>((ref) {
  return ref.watch(waterProvider).rollTo(DateTime.now());
});

class WaterController extends Notifier<HydrationState> {
  Future<void> _saveQueue = Future<void>.value();
  @override
  HydrationState build() =>
      ref.watch(initialWaterProvider).rollTo(DateTime.now());

  Future<void> addGlass() async {
    state = state.rollTo(DateTime.now()).addGlass();
    await _persist();
  }

  Future<void> removeGlass() async {
    state = state.rollTo(DateTime.now()).removeGlass();
    await _persist();
  }

  Future<void> setGoal(int goalGlasses) async {
    state = state.rollTo(DateTime.now()).setGoalGlasses(goalGlasses);
    await _persist();
  }

  Future<void> resetToday() async {
    state = state.rollTo(DateTime.now()).resetToday();
    await _persist();
  }

  Future<void> flush() => _saveQueue;

  Future<void> _persist() {
    // Capture each state before queuing the write so rapid taps cannot
    // let an older asynchronous preference write land last.
    final payload = jsonEncode(state.toJson());
    return _saveQueue = _saveQueue.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await AppLocalStorage.writeString(waterPrefsKey, payload);
      } catch (_) {
        // Keep the in-session value.
      }
    });
  }
}
