import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app/features/documents/data/document_repository.dart';
import 'package:app/features/documents/domain/interview_preview.dart';
import 'package:app/features/questionnaire/data/questionnaire_repository.dart';
import 'package:app/features/questionnaire/domain/deal_review.dart';
import 'package:app/features/questionnaire/domain/interview_step.dart';
import 'package:app/features/questionnaire/domain/question.dart';
import 'package:app/shared/models/result.dart';

class QuestionnaireProvider extends ChangeNotifier {
  QuestionnaireProvider(this._repository, this._documentRepository);

  final QuestionnaireRepository _repository;
  final DocumentRepository _documentRepository;

  String? _dealId;
  bool _isLoading = false;
  String? _errorMessage;
  Question? _currentQuestion;
  InterviewStage? _currentStage;
  bool _readyToGenerate = false;
  String? _closingMessage;
  DocumentSuggestion? _documentSuggestion;
  List<Question> _allFields = const [];
  InterviewPreview? _preview;
  DealReview? _review;
  final Map<int, String> _answers = {};
  final List<Question> _history = [];
  final List<InterviewStage?> _stageHistory = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Question? get currentQuestion => _currentQuestion;

  /// The stage [currentQuestion] belongs to (e.g. "🚗 Автомобиль"), already
  /// localized by the backend. Null once [readyToGenerate] is true - there
  /// is no "current field" left to stage.
  InterviewStage? get currentStage => _currentStage;
  bool get readyToGenerate => _readyToGenerate;
  String? get closingMessage => _closingMessage;

  /// Backend-computed progress (`GET /interview-preview`): how many fields
  /// are askable and how many questions genuinely remain, accounting for
  /// documents, profile data and dependencies. Null until the first fetch.
  InterviewPreview? get preview => _preview;

  /// Backend-computed pre-generation review (`GET /review`): every field
  /// grouped into auto-filled/manual/corrected/missing/skipped with
  /// source, confidence and reason. Non-null shortly after
  /// [readyToGenerate] turns true (fetched asynchronously).
  DealReview? get review => _review;

  /// Non-mandatory "upload this instead of typing N fields" suggestion for
  /// the current turn - non-null only while it hasn't been resolved yet
  /// (by uploading, via [resumeAfterDocumentUpload], or by dismissing, via
  /// [dismissDocumentSuggestion]).
  DocumentSuggestion? get documentSuggestion => _documentSuggestion;

  /// Every field the template has, for the full-document preview sheet —
  /// not the (much shorter) set actually asked during the interview.
  List<Question> get allFields => _allFields;

  Map<int, String> get answers => Map.unmodifiable(_answers);

  /// [answers] merged with values the backend already knows without
  /// asking — mainly the creator's own profile fields (name, address,
  /// passport), resolved by [GetDealFieldStatesUseCase] as soon as the
  /// deal's template and profile are known, not just once the interview
  /// finishes. Interview answers win if a field is somehow in both.
  Map<int, String> get displayValues {
    final merged = <int, String>{};
    for (final state in _review?.fieldStates ?? const []) {
      if (state.value != null && state.value!.trim().isNotEmpty) {
        merged[state.fieldId] = state.value!;
      }
    }
    merged.addAll(_answers);
    return merged;
  }

  /// Fraction of every template field ([allFields]) that currently has a
  /// value in [displayValues] - the one "how much of the document is
  /// filled" number, shown identically by the header's percent icon and
  /// the live document preview sheet ([AgreementPreviewSheet] used to
  /// compute its own, different ratio - askable-fields-remaining instead
  /// of fields-actually-filled - so the two disagreed on screen).
  double get documentFillProgress {
    if (_readyToGenerate) return 1;
    if (_allFields.isEmpty) return 0;
    final values = displayValues;
    final filled = _allFields.where((q) => (values[q.fieldId] ?? '').trim().isNotEmpty).length;
    return (filled / _allFields.length).clamp(0.0, 1.0);
  }

  bool get canGoBack => _history.isNotEmpty;

  /// 1-based position of [currentQuestion] in the sequence shown so far —
  /// tracks `_history`, not total answers, so it decreases on [goBack].
  int get position => _history.length + 1;

  String answerFor(int fieldId) => _answers[fieldId] ?? '';

  /// Starts (or resumes) the interview for [dealId]. Answers are kept
  /// (auto-saved) when re-entering the same deal, cleared for a new one.
  Future<void> start(String dealId) async {
    if (_dealId != dealId) {
      _answers.clear();
      _history.clear();
      _stageHistory.clear();
      _currentQuestion = null;
      _currentStage = null;
      _readyToGenerate = false;
      _documentSuggestion = null;
      _preview = null;
      _review = null;
      // Otherwise the previous deal's template fields (e.g. a vehicle
      // sale) stay visible in the live document preview / fill-progress
      // until this deal's own fetch below completes - or indefinitely, if
      // that fetch fails - because every other piece of per-deal state is
      // reset here but this one was missed.
      _allFields = const [];
    }
    _dealId = dealId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    switch (await _repository.getQuestionsForDeal(dealId)) {
      case Success(:final value):
        _allFields = value;
      case Failure():
        // The preview sheet just won't have anything to show — not fatal.
        break;
    }

    await _advance();
    _isLoading = false;
    notifyListeners();
    unawaited(refreshDerivedState());
  }

  /// Submits [text] as the answer to the current question and fetches the
  /// next one. The backend classifies whether [text] actually answers
  /// [field] before touching anything - a side question, an off-topic
  /// remark, or a cancel/change-topic request comes back as the *same*
  /// field repeated with a reply woven in, so only commit to history/
  /// answers once the interview has genuinely moved past this field.
  Future<void> submitAnswer(String text) async {
    final field = _currentQuestion;
    if (field == null || _isLoading) return;
    final fieldStage = _currentStage;

    _isLoading = true;
    notifyListeners();

    await _advance(fieldId: field.fieldId, answer: text, question: field.fieldName);
    _isLoading = false;

    final movedOn = _readyToGenerate || _currentQuestion?.fieldId != field.fieldId;
    if (movedOn) {
      _answers[field.fieldId] = text;
      _history.add(field);
      _stageHistory.add(fieldStage);
    }
    notifyListeners();
    unawaited(refreshDerivedState());
  }

  /// Corrects an already-collected answer from the Review & Confirm
  /// screen - persists it the same way a normal answer is, but without
  /// treating this as "moving on" to a new question the way [submitAnswer]
  /// does, since the interview has already finished by the time this is
  /// reachable.
  Future<bool> editAnswer(int fieldId, String label, String value) async {
    final dealId = _dealId;
    final trimmed = value.trim();
    if (dealId == null || trimmed.isEmpty || _isLoading) return false;

    _isLoading = true;
    notifyListeners();

    switch (await _repository.nextQuestion(dealId, fieldId: fieldId, answer: trimmed, question: label)) {
      case Success(value: final result):
        _answers[fieldId] = trimmed;
        _readyToGenerate = result.readyToGenerate;
        _currentQuestion = result.question;
        _currentStage = result.stage;
        _closingMessage = result.closingMessage;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        unawaited(refreshDerivedState());
        return true;
      case Failure(:final message):
        _errorMessage = message;
        _isLoading = false;
        notifyListeners();
        return false;
    }
  }

  /// Re-shows the previous question (its answer stays editable via
  /// [answerFor]) without a network round-trip. The stale review is
  /// dropped - the backend recomputes it when the interview is ready again.
  void goBack() {
    if (_history.isEmpty) return;
    _currentQuestion = _history.removeLast();
    _currentStage = _stageHistory.removeLast();
    _readyToGenerate = false;
    _review = null;
    notifyListeners();
  }

  /// Call after the caller has already uploaded the suggested document
  /// (e.g. via `DocumentUploadProvider.upload`) - re-asks the planner for
  /// the next step, which now skips whatever the upload just filled.
  Future<void> resumeAfterDocumentUpload() async {
    if (_dealId == null || _isLoading) return;

    _documentSuggestion = null;
    _isLoading = true;
    notifyListeners();

    await _advance();
    _isLoading = false;
    notifyListeners();
    unawaited(refreshDerivedState());
  }

  /// "Continue without document" - never shows this document's suggestion
  /// again for this deal, then continues the interview normally.
  Future<void> dismissDocumentSuggestion() async {
    final dealId = _dealId;
    final suggestion = _documentSuggestion;
    if (dealId == null || suggestion == null || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    await _repository.dismissDocumentSuggestion(dealId, suggestion.documentType);
    _documentSuggestion = null;
    await _advance();
    _isLoading = false;
    notifyListeners();
    unawaited(refreshDerivedState());
  }

  /// Re-fetches everything the backend derives about this deal's
  /// progress: the interview preview, and the pre-generation field
  /// review (deterministic, no LLM calls, safe on every turn — see
  /// `GetDealReviewUseCase`). The review is fetched from the very first
  /// turn, not just once ready to generate, so profile-resolved fields
  /// (name, address, passport) show up in the live document preview
  /// immediately instead of staying blank until the interview ends.
  /// Failures are non-fatal - the UI keeps the last known values rather
  /// than blocking the flow.
  Future<void> refreshDerivedState() async {
    final dealId = _dealId;
    if (dealId == null) return;

    final previewResult = await _documentRepository.getInterviewPreview(dealId);
    if (_dealId != dealId) return;
    if (previewResult case Success(:final value)) {
      _preview = value;
      notifyListeners();
    }

    final reviewResult = await _repository.getReview(dealId);
    if (_dealId != dealId) return;
    if (reviewResult case Success(:final value)) {
      _review = value;
      notifyListeners();
    }
  }

  Future<void> _advance({int? fieldId, String? answer, String? question}) async {
    final dealId = _dealId;
    if (dealId == null) return;

    switch (await _repository.nextQuestion(dealId, fieldId: fieldId, answer: answer, question: question)) {
      case Success(:final value):
        _readyToGenerate = value.readyToGenerate;
        _currentQuestion = value.question;
        _currentStage = value.stage;
        _closingMessage = value.closingMessage;
        _documentSuggestion = value.documentSuggestion;
        _errorMessage = null;
      case Failure(:final message):
        _errorMessage = message;
    }
  }
}
 