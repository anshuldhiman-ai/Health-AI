import 'package:app/app/log_store.dart';
import 'package:app/domain/entities/log_entry.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The in-memory day log (UI v0 stand-in for the M1 data layer):
/// add/undo/totals behaviour stays identical when the drift-backed
/// store replaces this class.
void main() {
  test('seed computes today totals and the ring remaining', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final log = container.read(dayLogProvider.notifier);

    final totals = log.totalsFor(0);
    expect(totals.consumed, 1318);
    expect(totals.consumed < kcalTarget, isTrue);
  });

  test('add appends to today and undo removes the newest entry', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final log = container.read(dayLogProvider.notifier);

    final before = log.totalsFor(0).consumed;
    log.add(
      LogEntry.estimated(
        mealKind: MealKind.lunch,
        dish: 'Chole bhature',
        kcal: 420,
      ),
    );
    expect(log.totalsFor(0).consumed, before + 420);

    expect(log.removeNewest(0), isTrue);
    expect(log.totalsFor(0).consumed, before);

    // Undo on an out-of-window day slot is a no-op.
    expect(log.removeNewest(DayLog.maxDays + 5), isFalse);
  });
}
