import 'package:app/core/network/api_exception.dart';
import 'package:app/core/services/api_service.dart';
import 'package:app/features/questionnaire/domain/question.dart';
import 'package:app/shared/models/result.dart';

abstract class QuestionnaireRepository {
  Future<Result<List<Question>>> getQuestions(String templateKey);
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
}
