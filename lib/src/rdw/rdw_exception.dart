/// Something went wrong while asking RDW for data.
///
/// A plate that is not registered is not an error: lookups return `null` or
/// leave the plate out instead.
sealed class RdwException implements Exception {
  const RdwException(this.message);

  /// What went wrong.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// RDW could not be reached, or did not answer in time.
final class RdwNetworkException extends RdwException {
  /// Creates the exception; [cause] is the underlying error.
  const RdwNetworkException(super.message, {this.cause});

  /// The underlying error, such as a `ClientException` or `TimeoutException`.
  final Object? cause;
}

/// RDW refused the request because too many were made (HTTP 429).
///
/// An app token raises the limit; see `RdwClient.appToken`.
final class RdwRateLimitedException extends RdwException {
  /// Creates the exception.
  const RdwRateLimitedException(super.message, {this.retryAfter});

  /// How long RDW asked to wait, if it said so.
  final Duration? retryAfter;
}

/// RDW answered with an error, or with data this package cannot read.
final class RdwResponseException extends RdwException {
  /// Creates the exception.
  const RdwResponseException(super.message, {this.statusCode});

  /// The HTTP status code, if the request got that far.
  final int? statusCode;
}
