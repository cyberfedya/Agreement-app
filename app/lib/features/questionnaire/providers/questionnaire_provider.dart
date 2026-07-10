import 'package:flutter/foundation.dart';

import 'package:app/features/questionnaire/data/questionnaire_repository.dart';
import 'package:app/features/questionnaire/domain/question.dart';
import 'package:app/shared/models/result.dart';

/// Drives a one-question-at-a-time interview: each answer is sent to the
/// backend's Interview Planner, which decides the next question (or that
/// enough is known to generate) — the field list is never fetched upfront.
class QuestionnaireProvider extends ChangeNotifier {
  QuestionnaireProvider(this._repository);

  final QuestionnaireRepository _repository;

  String? _dealId;
  bool _isLoading = false;
  String? _errorMessage;
  Question? _currentQuestion;
  bool _readyToGenerate = false;
  String? _closingMessage;
  List<Question> _allFields = const [];
  final Map<int, String> _answers = {};
  final List<Question> _history = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Question? get currentQuestion => _currentQuestion;
  bool get readyToGenerate => _readyToGenerate;
  String? get closingMessage => _closingMessage;

  /// Every field the template has, for the full-document preview sheet —
  /// not the (much shorter) set actually asked during the interview.
  List<Question> get allFields => _allFields;

  Map<int, String> get answers => Map.unmodifiable(_answers);
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
      _currentQuestion = null;
      _readyToGenerate = false;
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
  }

  /// Submits [text] as the answer to the current question and fetches the
  /// next one. The backend classifies whether [text] actually answers
  /// [field] before touching anything - a side question, an off-topic
  /// remark, or a cancel/change-topic request comes back as the *same*
  /// field repeated with a reply woven in, so only commit to history/
  /// answers once the interview has genuinely moved past this field.
  Future<void> submitAnswer(String text) async {
    final field = _currentQuestion;
    if (field == null) return;

    _isLoading = true;
    notifyListeners();

    await _advance(fieldId: field.fieldId, answer: text, question: field.fieldName);
    _isLoading = false;

    final movedOn = _readyToGenerate || _currentQuestion?.fieldId != field.fieldId;
    if (movedOn) {
      _answers[field.fieldId] = text;
      _history.add(field);
    }
    notifyListeners();
  }

  /// Corrects an already-collected answer from the Review & Confirm
  /// screen - persists it the same way a normal answer is, but without
  /// treating this as "moving on" to a new question the way [submitAnswer]
  /// does, since the interview has already finished by the time this is
  /// reachable.
  Future<bool> editAnswer(int fieldId, String label, String value) async {
    final dealId = _dealId;
    final trimmed = value.trim();
    if (dealId == null || trimmed.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    switch (await _repository.nextQuestion(dealId, fieldId: fieldId, answer: trimmed, question: label)) {
      case Success(value: var result):
        _answers[fieldId] = trimmed;
        _readyToGenerate = result.readyToGenerate;
        _currentQuestion = result.question;
        _closingMessage = result.closingMessage;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      case Failure(:final message):
        _errorMessage = message;
        _isLoading = false;
        notifyListeners();
        return false;
    }
  }

  /// Re-shows the previous question (its answer stays editable via
  /// [answerFor]) without a network round-trip.
  void goBack() {
    if (_history.isEmpty) return;
    _currentQuestion = _history.removeLast();
    _readyToGenerate = false;
    notifyListeners();
  }

  Future<void> _advance({int? fieldId, String? answer, String? question}) async {
    final dealId = _dealId;
    if (dealId == null) return;

    switch (await _repository.nextQuestion(dealId, fieldId: fieldId, answer: answer, question: question)) {
      case Success(:final value):
        _readyToGenerate = value.readyToGenerate;
        _currentQuestion = value.question;
        _closingMessage = value.closingMessage;
        _errorMessage = null;
      case Failure(:final message):
        _errorMessage = message;
    }
  }
}
