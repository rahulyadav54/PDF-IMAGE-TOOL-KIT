import 'app_exception.dart';

/// Represents a failure result with a user-facing message.
class Failure {
  const Failure(this.message, {this.cause});

  final String message;
  final Object? cause;

  factory Failure.fromException(Object error) {
    if (error is AppException) {
      return Failure(error.message, cause: error.cause);
    }
    return Failure(
      'Something went wrong. Please try again.',
      cause: error,
    );
  }
}
