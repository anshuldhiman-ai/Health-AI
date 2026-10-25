import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/data/local_storage.dart';
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

  /// Add a row and wait for its local write before leaving the current
  /// flow. Most callers can use [add]; confirmation screens should use
  /// this so a fast app close cannot race the preference write.
  Future<void> addAndSave(LogEntry entry, {int dayOffset = 0}) async {
    add(entry, dayOffset: dayOffset);
    await flush();
  }

  /// Undo support: remove the newest entry of any day.
  bool removeNewest(int dayOffset) {
    final entries = entriesFor(dayOffset);
    if (entries.isEmpty) return false;
    _commit({...state, dayOffset: entries.sublist(0, entries.length - 1)});
    return true;
  }

  /// Clear all entries for the given day offset.
  void clearDay(int dayOffset) {
    if (dayOffset < 0 || dayOffset >= maxDays) return;
    final next = Map<int, List<LogEntry>>.from(state);
    next.remove(dayOffset);
    _commit(next);
  }

  /// Remove all entries of a specific meal kind for a day.
  void removeMeal(int dayOffset, MealKind kind) {
    final entries = entriesFor(dayOffset);
    final next = entries.where((e) => e.mealKind != kind).toList();
    _commit({...state, dayOffset: next});
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
    final payload = jsonEncode({
      'baseDate': _dateOnly(DateTime.now()).toIso8601String(),
      'days': {
        for (final entry in next.entries)
          '${entry.key}': [for (final row in entry.value) row.toJson()],
      },
    });
    // Serialize writes so a fast undo cannot land before its add.
    // [AppLocalStorage] owns the storage strategy (authoritative
    // preferences copy plus keystore mirror); writing preferences again
    // from here just gives the log two places to disagree with itself.
    _saveQueue = _saveQueue.then((_) async {
      try {
        await AppLocalStorage.writeString(storageKey, payload);
      } catch (e) {
        debugPrint('[DayLog] Save error: $e');
      }
    });
  }
}

/// Load the on-device diary before the first frame. Entries are
/// stored against the date they were logged, so shifts forward when
/// the app opens on a later day.
///
/// Never throws: a storage failure returns an empty log so the app can
/// still paint its first frame.
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
  } catch (e) {
    debugPrint('[DayLog] Error in loadSavedDayLog: $e');
    return DayLog(prefs: prefs);
  }
}

Future<DayLog> _loadSavedDayLog(SharedPreferences? prefs) async {
  // Sanitised by [AppLocalStorage]: a value that is not real data is
  // reported as absent, so the deletion below can only ever be reached
  // by a genuinely unparseable payload and never by a storage error.
  String? raw = await AppLocalStorage.readString(DayLog.storageKey);
  if (raw == null && prefs != null) {
    raw = AppLocalStorage.sanitize(prefs.getString(DayLog.storageKey));
  }
  final entries = <int, List<LogEntry>>{};
  DateTime? base;
  if (raw != null && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final baseRaw = decoded['baseDate'];
        base = baseRaw is String ? DateTime.tryParse(baseRaw) : null;
        final days = decoded['days'];
        if (days is Map) {
          for (final day in days.entries) {
            final offset = int.tryParse(day.key.toString());
            final rows = day.value;
            if (offset == null || rows is! List) continue;
            final parsed = <LogEntry>[];
            for (final row in rows) {
              if (row is! Map) continue;
              try {
                parsed.add(LogEntry.fromJson(Map<String, dynamic>.from(row)));
              } catch (e) {
                debugPrint('[DayLog] Skipped bad row: $e');
              }
            }
            if (parsed.isNotEmpty) entries[offset] = parsed;
          }
        }
      }
    } on FormatException catch (e) {
      debugPrint('[DayLog] Dropping corrupt payload: $e');
      if (prefs != null) await prefs.remove(DayLog.storageKey);
      await AppLocalStorage.remove(DayLog.storageKey);
    } catch (e) {
      debugPrint('[DayLog] Load error (data preserved): $e');
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
