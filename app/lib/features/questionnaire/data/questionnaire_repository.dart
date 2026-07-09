import 'package:app/core/network/api_exception.dart';
import 'package:app/core/services/api_service.dart';
import 'package:app/features/questionnaire/domain/interview_step.dart';
import 'package:app/features/questionnaire/domain/question.dart';
import 'package:app/shared/models/result.dart';

abstract class QuestionnaireRepository {
  /// Lightweight preview (e.g. question count on the template detail page,
  /// or the full-document preview sheet during the interview) — every
  /// field the template has, regardless of what's actually asked.
  Future<Result<List<Question>>> getQuestions(String templateKey);

  /// Every field for an already-opened [Deal]'s template — same shape as
  /// [getQuestions], keyed by deal instead. Used for the preview sheet.
  Future<Result<List<Question>>> getQuestionsForDeal(String dealId);

  /// Drives the actual interview, one turn at a time.
  Future<Result<InterviewStep>> nextQuestion(String dealId, {int? fieldId, String? answer});
}

class ApiQuestionnaireRepository implements QuestionnaireRepository {
  ApiQuestionnaireRepository(this._api);

  final ApiService _api;

  @override
  Future<Result<List<Question>>> getQuestions(String templateKey) async {
    try {
      return Success(await _api.getQuestions(templateKey));
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<List<Question>>> getQuestionsForDeal(String dealId) async {
    try {
      return Success(await _api.getDealQuestions(dealId));
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<InterviewStep>> nextQuestion(String dealId, {int? fieldId, String? answer}) async {
    try {
      return Success(await _api.nextQuestion(dealId, fieldId: fieldId, answer: answer));
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }
}
