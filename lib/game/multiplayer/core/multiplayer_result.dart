/// Minimal, dependency-free Result type for clearer success/error handling.
/// Dart 3 sealed classes enable exhaustive switch/case in callers.
sealed class MultiplayerResult<T> {
  const MultiplayerResult();

  R match<R>({
    required R Function(T value) ok,
    required R Function(MultiplayerFailure err) err,
  });

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T getOrElse(T fallback) => switch (this) {
    Ok(value: final v) => v,
    Err() => fallback,
  };
}

class Ok<T> extends MultiplayerResult<T> {
  final T value;
  const Ok(this.value);

  @override
  R match<R>({
    required R Function(T value) ok,
    required R Function(MultiplayerFailure err) err,
  }) => ok(value);
}

class Err<T> extends MultiplayerResult<T> {
  final MultiplayerFailure failure;
  const Err(this.failure);

  @override
  R match<R>({
    required R Function(T value) ok,
    required R Function(MultiplayerFailure err) err,
  }) => err(failure);
}

/// Normalized failure shape for application/domain layers.
/// You can map HTTP/WS/protocol errors into this.
class MultiplayerFailure {
  final String code;     // e.g. "http/401", "ws/disconnected", "room/full"
  final String message;  // user/dev friendly
  final Object? cause;   // original exception
  final StackTrace? stackTrace;

  const MultiplayerFailure(this.code, this.message, {this.cause, this.stackTrace});

  @override
  String toString() => 'Failure(code: $code, message: $message, cause: $cause)';
}
