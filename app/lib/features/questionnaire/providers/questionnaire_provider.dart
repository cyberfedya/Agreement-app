import 'package:flutter/foundation.dart';
import 'package:app/features/questionnaire/data/questionnaire_repository.dart';
import 'package:app/features/questionnaire/domain/question.dart';
import 'package:app/shared/models/result.dart';
class QuestionnaireProvider extends ChangeNotifier {
  QuestionnaireProvider(this._repository);
  final QuestionnaireRepository _repository;
  String? _dealId;
  bool _isLoading = false;
  String? _errorMessage;
  List<Question> _questions = const [];
  final Map<int, String> _answers = {};
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Question> get questions => _questions;
  Map<int, String> get answers => Map.unmodifiable(_answers);
  bool get canSubmit =>
      _questions.isNotEmpty &&
      _questions.where((q) => q.required).every((q) => isAnswered(q.fieldId));
  String answerFor(int fieldId) => _answers[fieldId] ?? '';
  bool isAnswered(int fieldId) => answerFor(fieldId).trim().isNotEmpty;
  /// Loads questions for [dealId]. Answers are kept (auto-saved) when
  /// re-entering the same deal's questionnaire, and cleared when the user
  /// starts a different one.
  Future<void> load(String dealId)  async {
    if (_dealId != dealId) {
      _answers.clear();
      _questions = const [];
    }
    _dealId = dealId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    switch (await _repository.getQuestionsForDeal(dealId)) {
      case Success(:final value):
        _questions = value;
      case Failure(:final message):
        _errorMessage = message;
    }

    _isLoading = false;
    notifyListeners();
  }

  void setAnswer(int fieldId, String value) {
    _answers[fieldId] = value;
    notifyListeners();
  }
}
