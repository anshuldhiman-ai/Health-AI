import 'package:app/app/log_store.dart';
import 'package:app/domain/entities/log_entry.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('removeNewest removes the latest meal entry immediately', () {
    final store = DayLog(
      initial: {
        0: [
          LogEntry.estimated(
            mealKind: MealKind.breakfast,
            dish: 'Poha',
            kcal: 250,
          ),
          LogEntry.estimated(
            mealKind: MealKind.lunch,
            dish: 'Dal Tadka',
            kcal: 320,
          ),
        ],
      },
    );

    expect(store.state[0], hasLength(2));
    expect(store.state[0]!.last.dish, 'Dal Tadka');

    final undone = store.removeNewest(0);
    expect(undone, isTrue);
    expect(store.state[0], hasLength(1));
    expect(store.state[0]!.last.dish, 'Poha');
  });

  test('removeNewest returns false when day has no entries', () {
    final store = DayLog(initial: {0: []});
    final undone = store.removeNewest(0);
    expect(undone, isFalse);
  });
}
