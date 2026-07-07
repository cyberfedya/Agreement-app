sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([super.message = 'Could not reach the server. Check your connection.']);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Not found.']);
}

class ServerException extends ApiException {
  ServerException({required this.statusCode, this.body})
    : super('Server error ($statusCode).');

  final int statusCode;
  final dynamic body;
}

/// Thrown when a generate request is rejected because required questions
/// were left unanswered.
class MissingFieldsException extends ApiException {
  MissingFieldsException(this.fieldIds)
    : super('Please answer all required questions before generating.');

  final List<int> fieldIds;
}
