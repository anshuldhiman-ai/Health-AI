import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/domain/entities/hydration.dart';

const waterPrefsKey = 'water.v1';

Future<HydrationState> loadSavedWater() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(waterPrefsKey);
    if (raw != null) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return HydrationState.fromJson(decoded, DateTime.now());
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
  @override
  HydrationState build() =>
      ref.watch(initialWaterProvider).rollTo(DateTime.now());

  void addGlass() {
    state = state.rollTo(DateTime.now()).addGlass();
    unawaited(_persist());
  }

  void removeGlass() {
    state = state.rollTo(DateTime.now()).removeGlass();
    unawaited(_persist());
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(waterPrefsKey, jsonEncode(state.toJson()));
    } catch (_) {
      // Keep the in-session value.
    }
  }
}
