import 'package:flutter/foundation.dart';

import 'package:app/features/documents/data/document_repository.dart';
import 'package:app/features/documents/domain/interview_preview.dart';
import 'package:app/features/documents/domain/required_document.dart';
import 'package:app/features/documents/domain/uploaded_document.dart';
import 'package:app/shared/models/result.dart';

/// Drives the "upload supporting documents first" step: what's worth
/// suggesting for this deal's template, what's been uploaded so far, and
/// how many fields the AI managed to read off them.
class DocumentUploadProvider extends ChangeNotifier {
  DocumentUploadProvider(this._repository);

  final DocumentRepository _repository;

  String? _dealId;
  bool _isLoadingRequirements = false;
  bool _isUploading = false;
  bool _isLoadingPreview = false;
  String? _errorMessage;
  List<RequiredDocument> _requiredDocuments = const [];
  final List<UploadedDocument> _uploadedDocuments = [];
  InterviewPreview? _preview;

  bool get isLoadingRequirements => _isLoadingRequirements;
  bool get isUploading => _isUploading;
  bool get isLoadingPreview => _isLoadingPreview;
  String? get errorMessage => _errorMessage;
  List<RequiredDocument> get requiredDocuments => List.unmodifiable(_requiredDocuments);
  List<UploadedDocument> get uploadedDocuments => List.unmodifiable(_uploadedDocuments);
  InterviewPreview? get preview => _preview;

  /// True once required-document suggestions have loaded and there's
  /// actually at least one worth showing - callers use this to decide
  /// whether the upload step is worth showing at all.
  bool get hasSuggestions => _requiredDocuments.isNotEmpty;

  int get extractedFieldCount =>
      _uploadedDocuments.where((d) => d.isProcessed).fold(0, (sum, d) => sum + d.fields.length);

  Future<void> loadRequirements(String dealId) async {
    _dealId = dealId;
    _isLoadingRequirements = true;
    _errorMessage = null;
    notifyListeners();

    switch (await _repository.getRequiredDocuments(dealId)) {
      case Success(:final value):
        _requiredDocuments = value;
      case Failure():
        // Not fatal - the upload step just won't show suggested types,
        // the user can still upload anything freely.
        _requiredDocuments = const [];
    }

    _isLoadingRequirements = false;
    notifyListeners();
  }

  /// Uploads [files], then refreshes the remaining-questions preview so
  /// the summary card (and its TTS narration) reflects the new documents.
  Future<bool> upload(List<(String fileName, String contentType, List<int> bytes)> files) async {
    final dealId = _dealId;
    if (dealId == null || files.isEmpty) return false;

    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    var success = false;
    switch (await _repository.upload(dealId, files)) {
      case Success(:final value):
        _uploadedDocuments.addAll(value);
        success = true;
      case Failure(:final message):
        _errorMessage = message;
    }

    _isUploading = false;
    notifyListeners();

    if (success) await _refreshPreview();
    return success;
  }

  Future<void> deleteDocument(String documentId) async {
    final dealId = _dealId;
    if (dealId == null) return;

    switch (await _repository.delete(dealId, documentId)) {
      case Success():
        _uploadedDocuments.removeWhere((d) => d.id == documentId);
        notifyListeners();
        await _refreshPreview();
      case Failure(:final message):
        _errorMessage = message;
        notifyListeners();
    }
  }

  Future<void> _refreshPreview() async {
    final dealId = _dealId;
    if (dealId == null) return;

    _isLoadingPreview = true;
    notifyListeners();

    switch (await _repository.getInterviewPreview(dealId)) {
      case Success(:final value):
        _preview = value;
      case Failure():
        _preview = null;
    }

    _isLoadingPreview = false;
    notifyListeners();
  }
}
