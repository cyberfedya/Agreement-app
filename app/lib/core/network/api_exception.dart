sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// No route to the server at all - offline, DNS failure, connection
/// refused. Distinct from [TimeoutException] so the UI can tell "we never
/// even reached them" apart from "they were too slow to answer".
class NetworkException extends ApiException {
  const NetworkException(super.message);
}

/// The request was sent but no response arrived within the configured
/// timeout - the server may still be processing it (e.g. a slow OCR call);
/// unlike [NetworkException] this does not necessarily mean the device is
/// offline.
class ApiTimeoutException extends ApiException {
  const ApiTimeoutException(super.message);
}

/// The server responded with 2xx but a shape Flutter's models didn't
/// expect (missing/renamed/mistyped field). Thrown by the typed decode
/// step rather than left to surface as an uncaught TypeError, so callers
/// see a normal [Failure] instead of a crash.
class MalformedResponseException extends ApiException {
  const MalformedResponseException(super.message);
}

class NotFoundException extends ApiException {
  const NotFoundException(super.message);
}

class ServerException extends ApiException {
  ServerException({required this.statusCode, this.body, required String fallbackMessage})
    : super(_messageFrom(statusCode, body, fallbackMessage));

  final int statusCode;
  final dynamic body;

  /// Backend error payloads carry a human-readable `message` (e.g. the
  /// document-upload validator's "Upload at least one document.") - show
  /// that instead of the generic fallback whenever it's present.
  static String _messageFrom(int statusCode, dynamic body, String fallbackMessage) {
    if (body is Map && body['message'] is String && (body['message'] as String).trim().isNotEmpty) {
      return body['message'] as String;
    }
    return fallbackMessage;
  }
}

/// Thrown when a generate request is rejected because required questions
/// were left unanswered.
class MissingFieldsException extends ApiException {
  MissingFieldsException(this.fieldIds, String message) : super(message);

  final List<int> fieldIds;
}

/// Thrown when the backend blocks generation because the deal needs a
/// legal review first (HTTP 409 `legal_review_required`).
class LegalReviewRequiredException extends ApiException {
  const LegalReviewRequiredException(super.message);
}
