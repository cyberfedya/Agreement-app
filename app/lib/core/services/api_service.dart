import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_exception.dart';
import 'package:app/features/agreement/domain/agreement.dart';
import 'package:app/features/questionnaire/domain/question.dart';
import 'package:app/features/templates/domain/template.dart';

/// The single place that knows the backend's routes and JSON shape. Every
/// method returns strongly-typed domain models — callers never handle raw
/// JSON maps.
class ApiService {
  ApiService(this._client);

  final ApiClient _client;

  Future<List<TemplateSummary>> getTemplates({String lang = 'uz'}) async {
    final json = await _client.getJson('/api/templates', query: {'lang': lang});
    return (json as List).cast<Map<String, dynamic>>().map(TemplateSummary.fromJson).toList();
  }

  Future<TemplateDetail> getTemplate(String key, {String lang = 'uz'}) async {
    final json = await _client.getJson('/api/templates/$key', query: {'lang': lang});
    return TemplateDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<List<Question>> getQuestions(String key) async {
    final json = await _client.getJson('/api/templates/$key/questions');
    return (json as List).cast<Map<String, dynamic>>().map(Question.fromJson).toList();
  }

  Future<Agreement> generateAgreement(String key, Map<int, String> answers) async {
    try {
      final json = await _client.postJson(
        '/api/templates/$key/generate',
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
