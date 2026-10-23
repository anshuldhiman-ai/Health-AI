import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/domain/entities/log_entry.dart';
import 'package:app/domain/entities/macro.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/domain/entities/nutrition_targets.dart';

/// The whole UI's source of truth for logged days.
///
/// Days are indexed by OFFSET from today: 0 = today, 1 = yesterday,
/// ... Negative offsets (future) are invalid by construction. The
/// store persists finished entries locally (SharedPreferences, never
/// remote). [loadSavedDayLog] shifts saved offsets forward when the
/// app is opened on a later date.
class DayTotals {
  const DayTotals({
    required this.consumed,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int consumed;
  final int protein;
  final int carbs;
  final int fat;

  List<MacroLine> macroLines(NutritionTargets targets) => [
    MacroLine(kind: MacroKind.protein, value: protein, target: targets.protein),
    MacroLine(kind: MacroKind.carbs, value: carbs, target: targets.carbs),
    MacroLine(kind: MacroKind.fat, value: fat, target: targets.fat),
  ];

  double targetsCompletion(NutritionTargets targets) {
    final lines = macroLines(targets);
    final sum = lines.fold<double>(0, (acc, m) => acc + m.ratio);
    return (sum / lines.length).clamp(0.0, 1.0);
  }
}

class DayLog extends StateNotifier<Map<int, List<LogEntry>>> {
  DayLog({this.prefs, Map<int, List<LogEntry>>? initial})
    : super(initial ?? const {});

  /// Diary shows one week; Insights needs enough history for 90D plus
  /// the preceding 90D comparison window.
  static const diaryDays = 7;
  static const maxDays = 180;

  static const storageKey = 'food.log.v2';

  final SharedPreferences? prefs;
  Future<void> _saveQueue = Future<void>.value();

  List<LogEntry> entriesFor(int dayOffset) => state[dayOffset] ?? const [];

  DayTotals totalsFor(int dayOffset) {
    var protein = 0, carbs = 0, fat = 0;
    final entries = entriesFor(dayOffset);
    for (final e in entries) {
      protein += e.proteinGrams;
      carbs += e.carbsGrams;
      fat += e.fatGrams;
    }
    return DayTotals(
      consumed: entries.fold(0, (sum, e) => sum + e.kcal),
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }

  int kcalForMeal(int dayOffset, MealKind kind) =>
      entriesFor(dayOffset)
          .where((e) => e.mealKind == kind)
          .fold(0, (sum, e) => sum + e.kcal);

  /// Append a confirmed scan/menu pick to the requested day. The UI
  /// never writes raw macro numbers — it gets an estimated entry from
  /// [LogEntry.estimated] or the shared portion math.
  void add(LogEntry entry, {int dayOffset = 0}) {
    if (dayOffset < 0 || dayOffset >= maxDays) return;
    _commit({
      ...state,
      dayOffset: [...entriesFor(dayOffset), entry],
    });
  }

  /// Undo support: remove the newest entry of any day.
  bool removeNewest(int dayOffset) {
    final entries = entriesFor(dayOffset);
    if (entries.isEmpty) return false;
    _commit({...state, dayOffset: entries.sublist(0, entries.length - 1)});
    return true;
  }

  /// Remove a specific entry from a day (meal detail sheet).
  bool removeAt(int dayOffset, int index) {
    final entries = entriesFor(dayOffset);
    if (index < 0 || index >= entries.length) return false;
    final next = [...entries]..removeAt(index);
    _commit({...state, dayOffset: next});
    return true;
  }

  /// Await the latest local write (used by tests and shutdown paths).
  Future<void> flush() => _saveQueue;

  void _commit(Map<int, List<LogEntry>> next) {
    state = next;
    final prefs = this.prefs;
    if (prefs == null) return;
    final payload = jsonEncode({
      'baseDate': _dateOnly(DateTime.now()).toIso8601String(),
      'days': {
        for (final entry in next.entries)
          '${entry.key}': [for (final row in entry.value) row.toJson()],
      },
    });
    // Serialize writes so a fast undo cannot land before its add.
    _saveQueue = _saveQueue.then((_) async {
      try {
        final success = await prefs.setString(storageKey, payload);
        if (!success) {
          debugPrint('[DayLog] Failed to save to SharedPreferences');
        }
      } catch (e) {
        debugPrint('[DayLog] Save error: $e');
        // Keep the in-session value if save fails.
      }
    });
  }
}

/// Load the on-device diary before the first frame. Entries are
/// stored against the date they were logged, so shifts forward when
/// the app opens on a later day.
///
/// Never throws: a storage failure returns an empty log so the app can
/// still paint its first frame (an uncaught throw here means no
/// `runApp`, which the user sees as a black screen).
Future<DayLog> loadSavedDayLog() async {
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {
    // Storage unavailable: start with an empty, in-memory-only log.
    return DayLog();
  }
  try {
    return await _loadSavedDayLog(prefs);
  } catch (_) {
    // Corrupt payload of any other shape: drop it and start clean.
    await prefs.remove(DayLog.storageKey).catchError((_) => false);
    return DayLog(prefs: prefs);
  }
}

Future<DayLog> _loadSavedDayLog(SharedPreferences prefs) async {
  final raw = prefs.getString(DayLog.storageKey);
  final entries = <int, List<LogEntry>>{};
  DateTime? base;
  if (raw != null) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final baseRaw = decoded['baseDate'];
        base = baseRaw is String ? DateTime.tryParse(baseRaw) : null;
        final days = decoded['days'];
        if (days is Map<String, dynamic>) {
          for (final day in days.entries) {
            final offset = int.tryParse(day.key);
            final rows = day.value;
            if (offset == null || rows is! List) continue;
            final parsed = <LogEntry>[];
            for (final row in rows) {
              if (row is! Map<String, dynamic>) continue;
              try {
                parsed.add(LogEntry.fromJson(row));
              } on FormatException {
                // Skip a malformed row, keep the rest of the day.
              }
            }
            if (parsed.isNotEmpty) entries[offset] = parsed;
          }
        }
      }
    } on FormatException {
      await prefs.remove(DayLog.storageKey);
    }
  }

  if (base != null && entries.isNotEmpty) {
    final today = _dateOnly(DateTime.now());
    final delta = today.difference(_dateOnly(base)).inDays;
    if (delta > 0) {
      final shifted = <int, List<LogEntry>>{};
      for (final day in entries.entries) {
        final offset = day.key + delta;
        if (offset >= 0 && offset < DayLog.maxDays) {
          shifted[offset] = day.value;
        }
      }
      entries
        ..clear()
        ..addAll(shifted);
    }
  }

  return DayLog(prefs: prefs, initial: entries);
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

final dayLogProvider = StateNotifierProvider<DayLog, Map<int, List<LogEntry>>>(
  (ref) {
    // This should always be overridden in bootstrap with loaded data.
    // If accessed without override, return empty log as fallback.
    return DayLog();
  },
);
