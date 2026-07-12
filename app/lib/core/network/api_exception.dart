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
  const NetworkException([super.message = 'Could not reach the server. Check your connection.']);
}

/// The request was sent but no response arrived within the configured
/// timeout - the server may still be processing it (e.g. a slow OCR call);
/// unlike [NetworkException] this does not necessarily mean the device is
/// offline.
class ApiTimeoutException extends ApiException {
  const ApiTimeoutException([super.message = 'The server took too long to respond. Please try again.']);
}

/// The server responded with 2xx but a shape Flutter's models didn't
/// expect (missing/renamed/mistyped field). Thrown by the typed decode
/// step rather than left to surface as an uncaught TypeError, so callers
/// see a normal [Failure] instead of a crash.
class MalformedResponseException extends ApiException {
  const MalformedResponseException([super.message = 'Received an unexpected response from the server.']);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Not found.']);
}

class ServerException extends ApiException {
  ServerException({required this.statusCode, this.body}) : super(_messageFrom(statusCode, body));

  final int statusCode;
  final dynamic body;

  /// Backend error payloads carry a human-readable `message` (e.g. the
  /// document-upload validator's "Upload at least one document.") - show
  /// that instead of a bare status code whenever it's present.
  static String _messageFrom(int statusCode, dynamic body) {
    if (body is Map && body['message'] is String && (body['message'] as String).trim().isNotEmpty) {
      return body['message'] as String;
    }
    return 'Server error ($statusCode).';
  }
}

/// Thrown when a generate request is rejected because required questions
/// were left unanswered.
class MissingFieldsException extends ApiException {
  MissingFieldsException(this.fieldIds)
    : super('Please answer all required questions before generating.');

  final List<int> fieldIds;
}
