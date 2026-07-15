import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:app/features/documents/data/document_repository.dart';
import 'package:app/features/documents/domain/uploaded_document.dart';
import 'package:app/shared/models/result.dart';

/// Drives document upload for a deal: what's been uploaded so far and the
/// per-document extraction results, exactly as the backend reported them.
/// Registered once at the app root, so [attachDeal] must be called before
/// [upload] to point it at the right deal.
///
/// Deliberately holds no derived progress state - remaining questions,
/// coverage and review classification all live in `QuestionnaireProvider`
/// (fetched from the backend), so the same fact is never stored twice.
class DocumentUploadProvider extends ChangeNotifier {
  DocumentUploadProvider(this._repository);

  final DocumentRepository _repository;

  String? _dealId;
  bool _isUploading = false;
  bool _documentsLoaded = false;
  String? _errorMessage;
  final List<UploadedDocument> _uploadedDocuments = [];
  List<UploadedDocument> _lastUploadBatch = const [];
  List<String> _pendingMismatchWarnings = const [];

  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;
  List<UploadedDocument> get uploadedDocuments => List.unmodifiable(_uploadedDocuments);

  /// Whether [attachDeal]'s restore of this deal's existing documents has
  /// finished (successfully or not) - before this, [uploadedDocuments]
  /// being empty just means "not loaded yet", not "nothing was uploaded".
  /// Callers that decide something irreversible from an empty
  /// [uploadedDocuments] (e.g. whether to offer the final document check)
  /// must wait for this first.
  bool get documentsLoaded => _documentsLoaded;

  /// Just the documents from the most recent [upload] call - what the
  /// post-OCR celebration screen shows ("I filled these fields for you").
  List<UploadedDocument> get lastUploadBatch => List.unmodifiable(_lastUploadBatch);

  /// Warnings from the most recent [upload] call for documents that seem
  /// to be about a different subject than what's already known (e.g. a
  /// different car brand) - the page shows these once, then clears them.
  List<String> get pendingMismatchWarnings => List.unmodifiable(_pendingMismatchWarnings);

  void clearMismatchWarnings() {
    if (_pendingMismatchWarnings.isEmpty) return;
    _pendingMismatchWarnings = const [];
    notifyListeners();
  }

  /// Points this provider at [dealId] and restores the deal's documents
  /// from the backend, so re-entering an existing deal shows what was
  /// already uploaded instead of pretending nothing happened.
  void attachDeal(String dealId) {
    if (_dealId == dealId) return;
    _dealId = dealId;
    _documentsLoaded = false;
    _uploadedDocuments.clear();
    _lastUploadBatch = const [];
    _pendingMismatchWarnings = const [];
    notifyListeners();
    unawaited(_restoreDocuments(dealId));
  }

  Future<void> _restoreDocuments(String dealId) async {
    switch (await _repository.getDealDocuments(dealId)) {
      case Success(:final value):
        if (_dealId != dealId) return;
        _uploadedDocuments
          ..clear()
          ..addAll(value);
        _documentsLoaded = true;
        notifyListeners();
      case Failure():
        // Non-fatal: uploads still work, the history just starts empty -
        // but still counts as "loaded" so callers waiting on
        // documentsLoaded aren't stuck forever on a failed restore.
        if (_dealId == dealId) {
          _documentsLoaded = true;
          notifyListeners();
        }
    }
  }

  Future<bool> upload(List<(String fileName, String contentType, List<int> bytes)> files) async {
    final dealId = _dealId;
    if (dealId == null || files.isEmpty || _isUploading) return false;

    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    var success = false;
    switch (await _repository.upload(dealId, files)) {
      case Success(:final value):
        _uploadedDocuments.addAll(value);
        _lastUploadBatch = value;
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
    return success;
  }

  Future<void> deleteDocument(String documentId) async {
    final dealId = _dealId;
    if (dealId == null) return;

    switch (await _repository.delete(dealId, documentId)) {
      case Success():
        _uploadedDocuments.removeWhere((d) => d.id == documentId);
        notifyListeners();
      case Failure(:final message):
        _errorMessage = message;
        notifyListeners();
    }
  }

  /// Corrects a field the AI misread - updates locally first so the UI
  /// reflects the fix immediately, then persists it.
  Future<void> updateField(String documentId, String key, String value) async {
    final dealId = _dealId;
    if (dealId == null) return;

    final index = _uploadedDocuments.indexWhere((d) => d.id == documentId);
    if (index == -1) return;

    _uploadedDocuments[index] = _uploadedDocuments[index].withField(key, value);
    notifyListeners();

    switch (await _repository.updateField(dealId, documentId, key, value)) {
      case Success():
        break;
      case Failure(:final message):
        _errorMessage = message;
        notifyListeners();
    }
  }
}
