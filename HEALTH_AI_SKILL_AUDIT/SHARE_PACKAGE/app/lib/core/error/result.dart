/// Result type for expected failures (Section 5.3).
///
/// Domain and data code returns [Result<T>] (sealed: [Ok] / [Err])
/// for expected failures (permission denied, model missing, invalid
/// input). Exceptions are for bugs.
///
/// Pure Dart — no Flutter imports (R9).
library;

sealed class Result<T> {
  const Result._();

  /// The value, or `null` if this is an [Err].
  T? get valueOrNull;

  /// The failure, or `null` if this is an [Ok].
  Failure? get failureOrNull;

  bool get isOk;
  bool get isErr;

  R fold<R>(R Function(T value) onOk, R Function(Failure failure) onErr);
}

final class Ok<T> extends Result<T> {
  const Ok(this.value) : super._();

  final T value;

  @override
  T? get valueOrNull => value;

  @override
  Failure? get failureOrNull => null;

  @override
  bool get isOk => true;

  @override
  bool get isErr => false;

  @override
  R fold<R>(R Function(T value) onOk, R Function(Failure failure) onErr) =>
      onOk(value);
}

final class Err<T> extends Result<T> {
  const Err(this.failure) : super._();

  final Failure failure;

  @override
  T? get valueOrNull => null;

  @override
  Failure? get failureOrNull => failure;

  @override
  bool get isOk => false;

  @override
  bool get isErr => true;

  @override
  R fold<R>(R Function(T value) onOk, R Function(Failure failure) onErr) =>
      onErr(failure);
}

/// User-meaningful failure types (Section 5.3).
/// The UI maps each to a message that says what happened AND what
/// to do next.
enum FailureKind {
  permissionDenied,
  modelIntegrityFailed,
  modelUnavailable,
  storageFull,
  invalidInput,
  notFound,
  dbError,
  unknown,
}

final class Failure {
  const Failure(this.kind, this.message, {this.cause});

  final FailureKind kind;

  /// A message safe to log (no PII, no health values — Section 9.2).
  final String message;

  /// Optional underlying error, for the local ring-buffer logger only.
  final Object? cause;

  @override
  bool operator ==(Object other) =>
      other is Failure && other.kind == kind && other.message == message;

  @override
  int get hashCode => Object.hash(kind, message);

  @override
  String toString() => 'Failure($kind, $message)';
}
