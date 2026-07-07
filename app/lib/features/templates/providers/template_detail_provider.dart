import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:app/features/questionnaire/data/questionnaire_repository.dart';
import 'package:app/features/templates/data/template_repository.dart';
import 'package:app/features/templates/domain/template.dart';
import 'package:app/shared/models/result.dart';

class TemplateDetailProvider extends ChangeNotifier {
  TemplateDetailProvider(this._repository, this._questionnaireRepository);

  final TemplateRepository _repository;
  final QuestionnaireRepository _questionnaireRepository;

  bool _isLoading = false;
  String? _errorMessage;
  TemplateDetail? _template;
  int? _questionCount;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  TemplateDetail? get template => _template;

  /// Number of questions in the questionnaire, when known. Loaded alongside
  /// the template; null (not an error) if that lookup fails.
  int? get questionCount => _questionCount;

  /// Rough completion estimate: ~30s per answer, minimum one minute.
  int? get estimatedMinutes => _questionCount == null ? null : ((_questionCount! * 30) / 60).ceil().clamp(1, 99);

  Future<void> load(String key) async {
    _isLoading = true;
    _errorMessage = null;
    _template = null;
    _questionCount = null;
    notifyListeners();

    final (templateResult, questionsResult) = await (
      _repository.getTemplate(key),
      _questionnaireRepository.getQuestions(key),
    ).wait;

    switch (templateResult) {
      case Success(:final value):
        _template = value;
      case Failure(:final message):
        _errorMessage = message;
    }

    // Question count is a nice-to-have; a failure here never blocks the page.
    if (questionsResult case Success(:final value)) {
      _questionCount = value.length;
    }

    _isLoading = false;
    notifyListeners();
  }
}
