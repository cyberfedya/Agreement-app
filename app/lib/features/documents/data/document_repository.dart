import 'package:app/core/network/api_exception.dart';
import 'package:app/core/services/api_service.dart';
import 'package:app/features/documents/domain/document_verification.dart';
import 'package:app/features/documents/domain/interview_preview.dart';
import 'package:app/features/documents/domain/required_document.dart';
import 'package:app/features/documents/domain/uploaded_document.dart';
import 'package:app/shared/models/result.dart';

abstract class DocumentRepository {
  Future<Result<List<RequiredDocument>>> getRequiredDocuments(String dealId);

  Future<Result<List<UploadedDocument>>> getDealDocuments(String dealId);

  Future<Result<List<UploadedDocument>>> upload(
    String dealId,
    List<(String fileName, String contentType, List<int> bytes)> files,
  );

  Future<Result<void>> delete(String dealId, String documentId);

  Future<Result<void>> updateField(String dealId, String documentId, String key, String value);

  Future<Result<InterviewPreview>> getInterviewPreview(String dealId);

  Future<Result<DocumentVerification>> verifyDocument(String dealId);
}

class ApiDocumentRepository implements DocumentRepository {
  ApiDocumentRepository(this._api);

  final ApiService _api;

  @override
  Future<Result<List<RequiredDocument>>> getRequiredDocuments(String dealId) async {
    try {
      return Success(await _api.getRequiredDocuments(dealId));
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<List<UploadedDocument>>> getDealDocuments(String dealId) async {
    try {
      return Success(await _api.getDealDocuments(dealId));
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  /// A blip on a mobile connection (dropped packet, brief backend restart)
  /// is common mid-upload and looks identical to a real failure from the
  /// UI's point of view unless we tell them apart here. Retried silently
  /// under the same "Обрабатываю документ…" animation the caller is
  /// already showing - the user should see a slow upload, never a flash
  /// of "server error" for something that fixed itself a second later.
  static const int _maxUploadAttempts = 3;
  static const List<Duration> _retryDelays = [Duration(seconds: 1), Duration(seconds: 2)];

  @override
  Future<Result<List<UploadedDocument>>> upload(
    String dealId,
    List<(String fileName, String contentType, List<int> bytes)> files,
  ) async {
    for (var attempt = 1; attempt <= _maxUploadAttempts; attempt++) {
      try {
        return Success(await _api.uploadDocuments(dealId, files));
      } on ServerException catch (e) {
        // 4xx means the request itself is bad (validation, unsupported
        // file, ...) - retrying sends the exact same bad request again.
        // Only a 5xx (backend's own transient trouble) is worth retrying.
        if (e.statusCode < 500 || attempt == _maxUploadAttempts) {
          return Failure(_uploadErrorMessage(e));
        }
      } on NetworkException catch (e) {
        // A single dropped connection is common on mobile data; a timeout
        // is not - the OCR call already took the full budget, so retrying
        // would just wait that long again instead of surfacing honestly.
        if (attempt == _maxUploadAttempts) return Failure(e.message);
      } on ApiException catch (e) {
        return Failure(e.message);
      }

      await Future<void>.delayed(_retryDelays[attempt - 1]);
    }

    // Unreachable: the loop always returns or throws on its final attempt.
    return const Failure('Не удалось загрузить документ.');
  }

  /// Russian text for the backend's upload-validation error *codes* (the
  /// stable contract; the English `message` next to them is diagnostic).
  /// Unknown codes fall back to whatever message the backend sent.
  static String _uploadErrorMessage(ServerException e) {
    final body = e.body;
    final code = body is Map ? body['errorCode'] : null;
    return switch (code) {
      'DOCUMENTS_REQUIRED' => 'Прикрепите хотя бы один документ.',
      'TOO_MANY_DOCUMENTS' => 'Слишком много файлов за один раз — загрузите меньше.',
      'EMPTY_DOCUMENT' => 'Файл пустой — выберите другой.',
      'DOCUMENT_TOO_LARGE' => 'Файл слишком большой — сожмите фото или выберите другое.',
      'UNSUPPORTED_DOCUMENT_TYPE' => 'Поддерживаются только фото: JPEG, PNG и WebP.',
      'DOCUMENT_CONTENT_TYPE_MISMATCH' ||
      'DOCUMENT_EXTENSION_MISMATCH' => 'Файл повреждён или его тип не совпадает с содержимым.',
      'INVALID_MULTIPART_REQUEST' => 'Не удалось отправить файлы — попробуйте ещё раз.',
      _ => e.message,
    };
  }

  @override
  Future<Result<void>> delete(String dealId, String documentId) async {
    try {
      await _api.deleteDocument(dealId, documentId);
      return const Success(null);
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<void>> updateField(String dealId, String documentId, String key, String value) async {
    try {
      await _api.updateDocumentField(dealId, documentId, key, value);
      return const Success(null);
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<InterviewPreview>> getInterviewPreview(String dealId) async {
    try {
      return Success(await _api.getInterviewPreview(dealId));
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<DocumentVerification>> verifyDocument(String dealId) async {
    try {
      return Success(await _api.verifyDocument(dealId));
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }
}
