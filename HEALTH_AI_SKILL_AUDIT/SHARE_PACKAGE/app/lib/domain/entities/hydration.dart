/// Daily water intake. Pure Dart (R9); persistence lives in data.
library;

import 'package:app/domain/services/local_date.dart';

class HydrationDay {
  const HydrationDay({required this.date, required this.glasses});

  final DateTime date;
  final int glasses;
}

class HydrationState {
  const HydrationState({
    required this.date,
    required this.glasses,
    required this.history,
    this.customGoalGlasses,
  });

  factory HydrationState.empty(DateTime now) => HydrationState(
    date: localDateKey(now),
    glasses: 0,
    history: const <String, int>{},
  );

  factory HydrationState.fromJson(Map<String, dynamic> json, DateTime now) {
    final history = <String, int>{};
    final raw = json['history'];
    if (raw is Map) {
      for (final entry in raw.entries) {
        final value = entry.value;
        if (entry.key is String && value is num) {
          history[entry.key as String] = value.toInt();
        }
      }
    }
    final storedDate = json['date'];
    final key = storedDate is String ? storedDate : localDateKey(now);
    final customGoal = (json['goalGlasses'] as num?)?.toInt();
    final state = HydrationState(
      date: key,
      glasses: (json['glasses'] as num?)?.toInt() ?? 0,
      history: history,
      customGoalGlasses: customGoal,
    );
    return state.rollTo(now);
  }

  /// Product default: ten 250 ml glasses (2.5 L).
  static const int goalGlasses = 10;
  static const int mlPerGlass = 250;

  final String date;
  final int glasses;
  final Map<String, int> history;
  final int? customGoalGlasses;

  int get targetGlasses => customGoalGlasses ?? goalGlasses;

  double get liters => glasses * mlPerGlass / 1000;

  double get goalLiters => targetGlasses * mlPerGlass / 1000;

  double get progress => (glasses / targetGlasses).clamp(0.0, 1.0);

  bool get goalReached => glasses >= targetGlasses;

  HydrationState setGoalGlasses(int nextGoal) {
    return HydrationState(
      date: date,
      glasses: glasses,
      history: history,
      customGoalGlasses: nextGoal.clamp(1, 40),
    );
  }

  HydrationState rollTo(DateTime now) {
    final key = localDateKey(now);
    if (key == date) return this;
    return HydrationState(
      date: key,
      glasses: history[key] ?? 0,
      history: _pruned(history, now),
      customGoalGlasses: customGoalGlasses,
    );
  }

  HydrationState addGlass() {
    final next = glasses + 1;
    return HydrationState(
      date: date,
      glasses: next,
      history: {...history, date: next},
      customGoalGlasses: customGoalGlasses,
    );
  }

  HydrationState removeGlass() {
    if (glasses <= 0) return this;
    final next = glasses - 1;
    return HydrationState(
      date: date,
      glasses: next,
      history: {...history, date: next},
      customGoalGlasses: customGoalGlasses,
    );
  }

  HydrationState resetToday() {
    return HydrationState(
      date: date,
      glasses: 0,
      history: {...history, date: 0},
      customGoalGlasses: customGoalGlasses,
    );
  }

  List<HydrationDay> recentDays(DateTime now) {
    final today = localDay(now);
    return [
      for (var i = 6; i >= 0; i--)
        () {
          final day = today.subtract(Duration(days: i));
          final key = localDateKey(day);
          return HydrationDay(
            date: day,
            glasses: i == 0 ? glasses : (history[key] ?? 0),
          );
        }(),
    ];
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'glasses': glasses,
    'history': history,
    'goalGlasses': targetGlasses,
  };

  static Map<String, int> _pruned(Map<String, int> source, DateTime now) {
    final oldest = localDay(now).subtract(const Duration(days: 90));
    return {
      for (final entry in source.entries)
        if (entry.key.compareTo(localDateKey(oldest)) >= 0)
          entry.key: entry.value,
    };
  }
}
