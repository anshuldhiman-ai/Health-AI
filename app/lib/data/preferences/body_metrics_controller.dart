import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bodyMetricsPrefsKey = 'profile.body_metrics.v1';

class BodyMetrics {
  const BodyMetrics({this.heightCm, this.weightKg});

  final double? heightCm;
  final double? weightKg;

  double? get bmi {
    final h = heightCm;
    final w = weightKg;
    if (h == null || w == null || h <= 0) return null;
    return w / ((h / 100) * (h / 100));
  }

  BodyMetrics copyWith({double? heightCm, double? weightKg}) => BodyMetrics(
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
  );

  Map<String, dynamic> toJson() => {'heightCm': heightCm, 'weightKg': weightKg};

  factory BodyMetrics.fromJson(Map<String, dynamic> json) => BodyMetrics(
    heightCm: (json['heightCm'] as num?)?.toDouble(),
    weightKg: (json['weightKg'] as num?)?.toDouble(),
  );
}

Future<BodyMetrics> loadSavedBodyMetrics() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(bodyMetricsPrefsKey);
    if (raw == null) return const BodyMetrics();
    return BodyMetrics.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return const BodyMetrics();
  }
}

final initialBodyMetricsProvider = Provider<BodyMetrics>(
  (ref) => const BodyMetrics(),
);

final bodyMetricsProvider = NotifierProvider<BodyMetricsController, BodyMetrics>(
  BodyMetricsController.new,
);

class BodyMetricsController extends Notifier<BodyMetrics> {
  @override
  BodyMetrics build() => ref.watch(initialBodyMetricsProvider);

  void update({double? heightCm, double? weightKg}) {
    state = state.copyWith(heightCm: heightCm, weightKg: weightKg);
    unawaited(_persist());
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(bodyMetricsPrefsKey, jsonEncode(state.toJson()));
    } catch (_) {
      // Keep current in-memory values if local storage is unavailable.
    }
  }
}
