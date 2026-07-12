import 'package:app/core/network/api_exception.dart';
import 'package:app/core/services/api_service.dart';
import 'package:app/features/questionnaire/domain/deal_review.dart';
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

  /// Drives the actual interview, one turn at a time. [question] is the
  /// exact text of the question [answer] is replying to - the backend
  /// uses it to tell a real answer apart from a side remark.
  Future<Result<InterviewStep>> nextQuestion(String dealId, {int? fieldId, String? answer, String? question});

  /// Records "Continue without document" so this [documentType]'s
  /// suggestion never resurfaces for the rest of this deal's interview.
  Future<Result<void>> dismissDocumentSuggestion(String dealId, String documentType);

  /// The backend's pre-generation review: every field grouped and
  /// classified server-side (source, confidence, status, reason). The
  /// review screen renders this verbatim - nothing is derived locally.
  Future<Result<DealReview>> getReview(String dealId);
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
  Future<Result<InterviewStep>> nextQuestion(String dealId, {int? fieldId, String? answer, String? question}) async {
    try {
      return Success(await _api.nextQuestion(dealId, fieldId: fieldId, answer: answer, question: question));
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<void>> dismissDocumentSuggestion(String dealId, String documentType) async {
    try {
      await _api.dismissDocumentSuggestion(dealId, documentType);
      return const Success(null);
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<DealReview>> getReview(String dealId) async {
    try {
      return Success(await _api.getDealReview(dealId));
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }
}
