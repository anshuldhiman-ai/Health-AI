/// Manually logged sleep. Pure Dart (R9); there is no cloud account and
/// no wearable assumption. Persistence lives in data.
library;

import 'package:app/domain/services/local_date.dart';

int sleepDurationMinutes({required int bedMinutes, required int wakeMinutes}) {
  final bed = bedMinutes.clamp(0, 1439);
  final wake = wakeMinutes.clamp(0, 1439);
  var duration = wake - bed;
  if (duration <= 0) duration += 24 * 60;
  return duration;
}

class SleepRecord {
  const SleepRecord({
    required this.date,
    required this.bedMinutes,
    required this.wakeMinutes,
  });

  factory SleepRecord.fromJson(Map<String, dynamic> json) {
    final date = json['date'];
    return SleepRecord(
      date: date is String ? date : '',
      bedMinutes: (json['bedMinutes'] as num?)?.toInt() ?? 22 * 60 + 30,
      wakeMinutes: (json['wakeMinutes'] as num?)?.toInt() ?? 6 * 60 + 30,
    );
  }

  /// Wake date, ISO local key.
  final String date;

  /// Minutes after midnight for bedtime and wake time.
  final int bedMinutes;
  final int wakeMinutes;

  int get durationMinutes =>
      sleepDurationMinutes(bedMinutes: bedMinutes, wakeMinutes: wakeMinutes);

  Map<String, dynamic> toJson() => {
    'date': date,
    'bedMinutes': bedMinutes,
    'wakeMinutes': wakeMinutes,
  };
}

class SleepDay {
  const SleepDay({required this.date, required this.record});

  final DateTime date;
  final SleepRecord? record;

  int get minutes => record?.durationMinutes ?? 0;
}

class SleepState {
  const SleepState({required this.records});

  factory SleepState.empty() =>
      const SleepState(records: <String, SleepRecord>{});

  factory SleepState.fromJson(Map<String, dynamic> json) {
    final records = <String, SleepRecord>{};
    final raw = json['records'];
    if (raw is Map) {
      for (final entry in raw.entries) {
        final value = entry.value;
        if (entry.key is String && value is Map<String, dynamic>) {
          records[entry.key as String] = SleepRecord.fromJson(value);
        }
      }
    }
    return SleepState(records: records);
  }

  /// Product default: eight hours.
  static const int goalMinutes = 8 * 60;

  final Map<String, SleepRecord> records;

  SleepRecord? recordFor(DateTime now) => records[localDateKey(now)];

  SleepState save(
    DateTime now, {
    required int bedMinutes,
    required int wakeMinutes,
  }) {
    final key = localDateKey(now);
    final record = SleepRecord(
      date: key,
      bedMinutes: bedMinutes,
      wakeMinutes: wakeMinutes,
    );
    return SleepState(records: {...records, key: record});
  }

  SleepState remove(DateTime now) {
    final key = localDateKey(now);
    if (!records.containsKey(key)) return this;
    return SleepState(records: {...records}..remove(key));
  }

  List<SleepDay> recentDays(DateTime now) {
    final today = localDay(now);
    return [
      for (var i = 6; i >= 0; i--)
        () {
          final day = today.subtract(Duration(days: i));
          return SleepDay(date: day, record: records[localDateKey(day)]);
        }(),
    ];
  }

  Map<String, dynamic> toJson() => {
    'records': {
      for (final entry in records.entries) entry.key: entry.value.toJson(),
    },
  };
}
