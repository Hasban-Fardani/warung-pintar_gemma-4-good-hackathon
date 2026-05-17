/// Result type for functional error handling.
/// Replaces `Either` from fpdart/dartz — zero external dependency.
///
/// Usage:
/// ```dart
/// final result = await someOperation();
/// switch (result) {
///   case Success(:final data): handleSuccess(data);
///   case Failure(:final error): handleError(error);
/// }
/// ```
sealed class Result<T, E> {
  const Result();
}

/// Successful result containing data of type [T].
final class Success<T, E> extends Result<T, E> {
  final T data;
  const Success(this.data);
}

/// Failed result containing error of type [E].
final class Failure<T, E> extends Result<T, E> {
  final E error;
  const Failure(this.error);
}

extension ResultExtensions<T, E> on Result<T, E> {
  R when<R>({
    required R Function(T data) success,
    required R Function(E error) failure,
  }) {
    return switch (this) {
      Success(:final data) => success(data),
      Failure(:final error) => failure(error),
    };
  }

  R maybeWhen<R>({
    required R Function(T data) success,
    required R Function() orElse,
  }) {
    return switch (this) {
      Success(:final data) => success(data),
      Failure() => orElse(),
    };
  }
}
