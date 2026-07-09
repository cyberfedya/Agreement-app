import 'package:app/core/network/api_exception.dart';
import 'package:app/core/services/api_service.dart';
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

  @override
  Future<Result<List<UploadedDocument>>> upload(
    String dealId,
    List<(String fileName, String contentType, List<int> bytes)> files,
  ) async {
    try {
      return Success(await _api.uploadDocuments(dealId, files));
    } on ApiException catch (e) {
      return Failure(e.message);
    }
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
}
