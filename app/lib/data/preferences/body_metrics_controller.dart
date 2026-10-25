import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/data/local_storage.dart';

const bodyMetricsPrefsKey = 'profile.body_metrics.v1';

enum BmiStatus {
  unknown,
  severelyUnderweight, // < 17.0 (Red)
  slightlyUnderweight, // 17.0 - 18.4 (Yellow)
  normal, // 18.5 - 24.9 (Green)
  overweight, // 25.0 - 29.9 (Yellow)
  obese, // >= 30.0 (Red)
}

class BodyMetrics {
  const BodyMetrics({
    this.name = 'Alex',
    this.dateOfBirth,
    this.heightCm,
    this.weightKg,
    this.activityLevel = 'Active',
    this.useFeet = false,
    this.useLbs = false,
    this.onboardingCompleted = false,
  });

  final String name;
  final DateTime? dateOfBirth;
  final double? heightCm;
  final double? weightKg;
  final String activityLevel;
  final bool useFeet;
  final bool useLbs;
  final bool onboardingCompleted;

  int? get age {
    final dob = dateOfBirth;
    if (dob == null) return null;
    final now = DateTime.now();
    var a = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      a--;
    }
    return a >= 0 ? a : null;
  }

  double? get bmi {
    final h = heightCm;
    final w = weightKg;
    if (h == null || w == null || h <= 0) return null;
    return w / ((h / 100) * (h / 100));
  }

  BmiStatus get bmiStatus {
    final b = bmi;
    if (b == null) return BmiStatus.unknown;
    if (b < 17.0) return BmiStatus.severelyUnderweight;
    if (b < 18.5) return BmiStatus.slightlyUnderweight;
    if (b < 25.0) return BmiStatus.normal;
    if (b < 30.0) return BmiStatus.overweight;
    return BmiStatus.obese;
  }

  String get bmiLabel => switch (bmiStatus) {
    BmiStatus.unknown => 'Add height & weight to calculate BMI',
    BmiStatus.severelyUnderweight => 'Severely Underweight (< 17.0)',
    BmiStatus.slightlyUnderweight => 'Borderline Underweight (17.0–18.4)',
    BmiStatus.normal => 'Healthy / Normal Range (18.5–24.9)',
    BmiStatus.overweight => 'Borderline Overweight (25.0–29.9)',
    BmiStatus.obese => 'Obese Range (≥ 30.0)',
  };

  String get formattedHeight {
    if (heightCm == null) return 'Add height';
    if (useFeet) {
      final totalInches = heightCm! / 2.54;
      final feet = totalInches ~/ 12;
      final inches = (totalInches % 12).round();
      return "$feet' $inches\"";
    }
    return '${heightCm!.toStringAsFixed(0)} cm';
  }

  String get formattedWeight {
    if (weightKg == null) return 'Add weight';
    if (useLbs) {
      final lbs = weightKg! * 2.20462;
      return '${lbs.toStringAsFixed(1)} lbs';
    }
    return '${weightKg!.toStringAsFixed(1)} kg';
  }

  BodyMetrics copyWith({
    String? name,
    DateTime? dateOfBirth,
    double? heightCm,
    double? weightKg,
    String? activityLevel,
    bool? useFeet,
    bool? useLbs,
    bool? onboardingCompleted,
  }) => BodyMetrics(
    name: name ?? this.name,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    activityLevel: activityLevel ?? this.activityLevel,
    useFeet: useFeet ?? this.useFeet,
    useLbs: useLbs ?? this.useLbs,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'heightCm': heightCm,
    'weightKg': weightKg,
    'activityLevel': activityLevel,
    'useFeet': useFeet,
    'useLbs': useLbs,
    'onboardingCompleted': onboardingCompleted,
  };

  factory BodyMetrics.fromJson(Map<String, dynamic> json) => BodyMetrics(
    name: (json['name'] as String?)?.trim().isNotEmpty == true
        ? json['name'] as String
        : 'Alex',
    dateOfBirth: json['dateOfBirth'] != null
        ? DateTime.tryParse(json['dateOfBirth'].toString())
        : null,
    heightCm: (json['heightCm'] as num?)?.toDouble(),
    weightKg: (json['weightKg'] as num?)?.toDouble(),
    activityLevel: (json['activityLevel'] as String?) ?? 'Active',
    useFeet: (json['useFeet'] as bool?) ?? false,
    useLbs: (json['useLbs'] as bool?) ?? false,
    onboardingCompleted: (json['onboardingCompleted'] as bool?) ?? false,
  );
}

Future<BodyMetrics> loadSavedBodyMetrics() async {
  try {
    final raw = await AppLocalStorage.readString(bodyMetricsPrefsKey);
    if (raw == null || raw.isEmpty) return const BodyMetrics();
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const BodyMetrics();
    return BodyMetrics.fromJson(Map<String, dynamic>.from(decoded));
  } catch (e) {
    return const BodyMetrics();
  }
}

final initialBodyMetricsProvider = Provider<BodyMetrics>(
  (ref) => const BodyMetrics(),
);

final bodyMetricsProvider =
    NotifierProvider<BodyMetricsController, BodyMetrics>(
      BodyMetricsController.new,
    );

class BodyMetricsController extends Notifier<BodyMetrics> {
  Future<void> _saveQueue = Future<void>.value();

  @override
  BodyMetrics build() => ref.watch(initialBodyMetricsProvider);

  Future<void> update({
    String? name,
    DateTime? dateOfBirth,
    double? heightCm,
    double? weightKg,
    String? activityLevel,
    bool? useFeet,
    bool? useLbs,
    bool? onboardingCompleted,
  }) async {
    final next = state.copyWith(
      name: name,
      dateOfBirth: dateOfBirth,
      heightCm: heightCm,
      weightKg: weightKg,
      activityLevel: activityLevel,
      useFeet: useFeet,
      useLbs: useLbs,
      onboardingCompleted: onboardingCompleted,
    );
    state = next;
    await _persist(next);
  }

  Future<void> flush() => _persist(state);

  Future<void> _persist(BodyMetrics snapshot) {
    final payload = jsonEncode(snapshot.toJson());
    return _saveQueue = _saveQueue.then((_) async {
      await AppLocalStorage.writeString(bodyMetricsPrefsKey, payload);
    });
  }
}
