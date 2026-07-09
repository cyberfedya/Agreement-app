import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_exception.dart';
import 'package:app/features/agreement/domain/agreement.dart';
import 'package:app/features/deal/domain/deal.dart';
import 'package:app/features/profile/domain/user_profile.dart';
import 'package:app/features/questionnaire/domain/interview_step.dart';
import 'package:app/features/questionnaire/domain/question.dart';
import 'package:app/features/templates/domain/template.dart';

/// The single place that knows the backend's routes and JSON shape. Every
/// method returns strongly-typed domain models — callers never handle raw
/// JSON maps.
class ApiService {
  ApiService(this._client);

  final ApiClient _client;

  Future<List<TemplateSummary>> getTemplates({String lang = 'ru'}) async {
    final json = await _client.getJson('/api/templates', query: {'lang': lang});
    return (json as List).cast<Map<String, dynamic>>().map(TemplateSummary.fromJson).toList();
  }

  Future<TemplateDetail> getTemplate(String key, {String lang = 'ru'}) async {
    final json = await _client.getJson('/api/templates/$key', query: {'lang': lang});
    return TemplateDetail.fromJson(json as Map<String, dynamic>);
  }

  /// Lightweight preview only — the interview flow uses [getDealQuestions].
  Future<List<Question>> getQuestions(String key) async {
    final json = await _client.getJson('/api/templates/$key/questions');
    return (json as List).cast<Map<String, dynamic>>().map(Question.fromJson).toList();
  }

  /// Matches free-form [text] (or a direct [templateKey]) to a template and
  /// opens a [Deal] for it. Returns null when the AI found no reasonable
  /// match (HTTP 422) — callers fall back to manual template selection.
  Future<Deal?> createDeal({String? text, String? templateKey, required String profileId, String lang = 'ru'}) async {
    try {
      final json = await _client.postJson(
        '/api/deals',
        query: {'lang': lang},
        body: {'text': text, 'templateKey': templateKey, 'profileId': profileId},
      );
      return Deal.fromJson(json as Map<String, dynamic>);
    } on ServerException catch (e) {
      if (e.statusCode == 422) return null;
      rethrow;
    }
  }

  Future<UserProfile> getProfile(String id) async {
    final json = await _client.getJson('/api/profile/$id');
    return UserProfile.fromJson(json as Map<String, dynamic>);
  }

  Future<UserProfile> saveProfile(String id, UserProfile profile) async {
    final json = await _client.putJson('/api/profile/$id', body: profile.toJson());
    return UserProfile.fromJson(json as Map<String, dynamic>);
  }

  Future<void> deleteProfile(String id) => _client.deleteJson('/api/profile/$id');

  /// Every field the template has — used to render the full-document
  /// preview sheet. The interview itself is driven by [nextQuestion], one
  /// field at a time.
  Future<List<Question>> getDealQuestions(String dealId) async {
    final json = await _client.getJson('/api/deals/$dealId/questions');
    return (json as List).cast<Map<String, dynamic>>().map(Question.fromJson).toList();
  }

  /// Asks the Interview Planner what to do next: either the next question
  /// to show, or that enough is known to generate. [fieldId]/[answer] are
  /// the answer to the *previous* question this deal was asked (omit both
  /// on the very first call).
  Future<InterviewStep> nextQuestion(String dealId, {int? fieldId, String? answer, String lang = 'ru'}) async {
    final json = await _client.postJson(
      '/api/deals/$dealId/next-question',
      query: {'lang': lang},
      body: {'fieldId': fieldId, 'answer': answer},
    );
    return InterviewStep.fromJson(json as Map<String, dynamic>);
  }

  Future<Agreement> generateFromDeal(String dealId, Map<int, String> answers) async {
    try {
      final json = await _client.postJson(
        '/api/deals/$dealId/generate',
        body: {'answers': answers.map((fieldId, value) => MapEntry(fieldId.toString(), value))},
      );
      return Agreement.fromJson(json as Map<String, dynamic>);
    } on ServerException catch (e) {
      final body = e.body;
      if (e.statusCode == 400 && body is Map && body['error'] == 'missing_required_fields') {
        final ids = (body['missingFieldIds'] as List).cast<int>();
        throw MissingFieldsException(ids);
      }
      rethrow;
    }
  }
}
