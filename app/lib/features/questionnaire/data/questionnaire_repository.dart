import 'package:app/core/network/api_exception.dart';
import 'package:app/core/services/api_service.dart';
import 'package:app/features/questionnaire/domain/question.dart';
import 'package:app/shared/models/result.dart';

abstract class QuestionnaireRepository {
  /// Lightweight preview (e.g. question count on the template detail page)
  /// — doesn't require an open deal.
  Future<Result<List<Question>>> getQuestions(String templateKey);

  /// The actual interview flow: questions for an already-opened [Deal].
  Future<Result<List<Question>>> getQuestionsForDeal(String dealId);
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
}
