import 'package:flutter/foundation.dart';

import 'package:app/features/documents/data/document_repository.dart';
import 'package:app/features/documents/domain/interview_preview.dart';
import 'package:app/features/documents/domain/uploaded_document.dart';
import 'package:app/shared/models/result.dart';

/// Drives document upload for a deal: what's been uploaded so far, and how
/// many fields the AI managed to read off them. Used by the mid-interview
/// document-suggestion card (`QuestionnaireProvider.documentSuggestion`) -
/// registered once at the app root, so [attachDeal] must be called before
/// [upload] to point it at the right deal.
class DocumentUploadProvider extends ChangeNotifier {
  DocumentUploadProvider(this._repository);

  final DocumentRepository _repository;

  String? _dealId;
  bool _isUploading = false;
  bool _isLoadingPreview = false;
  String? _errorMessage;
  final List<UploadedDocument> _uploadedDocuments = [];
  InterviewPreview? _preview;
  List<String> _pendingMismatchWarnings = const [];

  bool get isUploading => _isUploading;
  bool get isLoadingPreview => _isLoadingPreview;
  String? get errorMessage => _errorMessage;
  List<UploadedDocument> get uploadedDocuments => List.unmodifiable(_uploadedDocuments);
  InterviewPreview? get preview => _preview;

  /// Warnings from the most recent [upload] call for documents that seem
  /// to be about a different subject than what's already known (e.g. a
  /// different car brand) - the page shows these once, then clears them.
  List<String> get pendingMismatchWarnings => List.unmodifiable(_pendingMismatchWarnings);

  void clearMismatchWarnings() {
    if (_pendingMismatchWarnings.isEmpty) return;
    _pendingMismatchWarnings = const [];
    notifyListeners();
  }

  int get extractedFieldCount =>
      _uploadedDocuments.where((d) => d.isProcessed).fold(0, (sum, d) => sum + d.fields.length);

  /// Points this provider at [dealId] - resets per-deal state when
  /// switching to a different deal (this provider is registered once at
  /// the app root, so without this guard, starting a fresh deal would
  /// keep showing the previous deal's uploaded documents/preview).
  void attachDeal(String dealId) {
    if (_dealId == dealId) return;
    _dealId = dealId;
    _uploadedDocuments.clear();
    _preview = null;
    _pendingMismatchWarnings = const [];
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
        _pendingMismatchWarnings = value
            .map((d) => d.mismatchWarning)
            .whereType<String>()
            .toList(growable: false);
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

  /// Corrects a field the AI misread - updates locally first so the UI
  /// reflects the fix immediately, then persists it (and refreshes the
  /// preview count, since the corrected value can now cover a question).
  Future<void> updateField(String documentId, String key, String value) async {
    final dealId = _dealId;
    if (dealId == null) return;

    final index = _uploadedDocuments.indexWhere((d) => d.id == documentId);
    if (index == -1) return;

    _uploadedDocuments[index] = _uploadedDocuments[index].withField(key, value);
    notifyListeners();

    switch (await _repository.updateField(dealId, documentId, key, value)) {
      case Success():
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
