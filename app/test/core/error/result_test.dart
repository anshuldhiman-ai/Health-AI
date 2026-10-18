import 'package:app/core/error/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Ok exposes its value and folds to onOk', () {
      const r = Ok<int>(42);
      expect(r.isOk, isTrue);
      expect(r.isErr, isFalse);
      expect(r.valueOrNull, 42);
      expect(r.failureOrNull, isNull);
      expect(r.fold((v) => 'ok $v', (f) => 'err'), 'ok 42');
    });

    test('Err exposes its failure and folds to onErr', () {
      const r = Err<int>(Failure(FailureKind.invalidInput, 'bad input'));
      expect(r.isOk, isFalse);
      expect(r.isErr, isTrue);
      expect(r.valueOrNull, isNull);
      expect(r.failureOrNull!.kind, FailureKind.invalidInput);
      expect(r.fold((v) => 'ok', (f) => f.message), 'bad input');
    });

    test('Failures compare by kind and message', () {
      const a = Failure(FailureKind.permissionDenied, 'denied');
      const b = Failure(FailureKind.permissionDenied, 'denied');
      const c = Failure(FailureKind.permissionDenied, 'other');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
