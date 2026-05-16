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
