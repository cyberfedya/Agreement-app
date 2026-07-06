import 'package:app/features/questionnaire/domain/question.dart';

abstract class QuestionnaireRepository {
  Future<List<Question>> getMissingQuestions(String dealId);
}
