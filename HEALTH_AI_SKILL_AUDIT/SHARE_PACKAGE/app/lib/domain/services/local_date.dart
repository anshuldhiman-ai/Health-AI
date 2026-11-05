/// Local calendar helpers shared by health data. Pure Dart (R9).
library;

/// ISO calendar key (`2026-10-20`) in the phone's local timezone.
String localDateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

/// Midnight for the supplied local date.
DateTime localDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);
