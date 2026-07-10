import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_exception.dart';
import 'package:app/features/agreement/domain/agreement.dart';
import 'package:app/features/agreement/domain/deal_invite.dart';
import 'package:app/features/deal/domain/deal.dart';
import 'package:app/features/documents/domain/interview_preview.dart';
import 'package:app/features/documents/domain/required_document.dart';
import 'package:app/features/documents/domain/uploaded_document.dart';
import 'package:app/features/profile/domain/user_profile.dart';
import 'package:app/features/questionnaire/domain/interview_step.dart';
import 'package:app/features/questionnaire/domain/question.dart';
import 'package:app/features/templates/domain/template.dart';
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
  /// the answer to the *previous* question this deal was asked, and
  /// [question] is that question's exact text - the backend uses it to
  /// classify whether [answer] actually answers it or is a side remark
  /// (all three omitted on the very first call).
  Future<InterviewStep> nextQuestion(
    String dealId, {
    int? fieldId,
    String? answer,
    String? question,
    String lang = 'ru',
  }) async {
    final json = await _client.postJson(
      '/api/deals/$dealId/next-question',
      query: {'lang': lang},
      body: {'fieldId': fieldId, 'answer': answer, 'question': question},
    );
    return InterviewStep.fromJson(json as Map<String, dynamic>);
  }

  /// Records "Continue without document" for [documentType] (the
  /// `DocumentType` enum name, e.g. `"VehicleRegistration"`, echoed back
  /// from the suggestion) so it never resurfaces for the rest of this deal.
  Future<void> dismissDocumentSuggestion(String dealId, String documentType) =>
      _client.postJson('/api/deals/$dealId/document-suggestions/dismiss', body: {'documentType': documentType});

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

  /// Fetches an already-generated agreement by deal id - the cross-device
  /// counterpart to [generateFromDeal]. This is what lets the second party
  /// (whoever scanned the QR code, on their own device) retrieve the same
  /// document rather than relying on any local state.
  Future<Agreement> getDealAgreement(String dealId) async {
    final json = await _client.getJson('/api/deals/$dealId/agreement');
    return Agreement.fromJson(json as Map<String, dynamic>);
  }

  /// Invite metadata only (type, roles, who invited, status) - shown
  /// before the second party ever sees the agreement's HTML.
  Future<DealInvite> getDealInvite(String dealId, {String lang = 'ru'}) async {
    final json = await _client.getJson('/api/deals/$dealId/invite', query: {'lang': lang});
    return DealInvite.fromJson(json as Map<String, dynamic>);
  }

  /// Links [profileId] to the deal as the second party - no HTML, no
  /// regeneration; the caller re-runs [generateFromDeal] afterwards if it
  /// wants the document to reflect the newly-linked profile.
  Future<void> acceptDealInvite(String dealId, String profileId) =>
      _client.postJson('/api/deals/$dealId/invite/accept', body: {'profileId': profileId});

  Future<void> signDealSecondParty(String dealId, String fullName) =>
      _client.postJson('/api/deals/$dealId/sign', body: {'fullName': fullName});

  /// Documents worth suggesting the user upload for this deal's template -
  /// empty when nothing useful comes to mind (never identity documents).
  Future<List<RequiredDocument>> getRequiredDocuments(String dealId, {String lang = 'ru'}) async {
    final json = await _client.getJson('/api/deals/$dealId/required-documents', query: {'lang': lang});
    return (json as List).cast<Map<String, dynamic>>().map(RequiredDocument.fromJson).toList();
  }

  Future<List<UploadedDocument>> getDealDocuments(String dealId) async {
    final json = await _client.getJson('/api/deals/$dealId/documents');
    return (json as List).cast<Map<String, dynamic>>().map(UploadedDocument.fromJson).toList();
  }

  /// Uploads one or more files at once; each gets classified and its
  /// fields extracted before the response comes back (there's no
  /// background job queue, so this can take a few seconds per file).
  Future<List<UploadedDocument>> uploadDocuments(
    String dealId,
    List<(String fileName, String contentType, List<int> bytes)> files,
  ) async {
    final json = await _client.postMultipart(
      '/api/deals/$dealId/documents',
      files: files.map((f) => ('file', f.$1, f.$2, f.$3)).toList(),
    );
    return (json as List).cast<Map<String, dynamic>>().map(UploadedDocument.fromJson).toList();
  }

  Future<void> deleteDocument(String dealId, String documentId) =>
      _client.deleteJson('/api/deals/$dealId/documents/$documentId');

  Future<void> updateDocumentField(String dealId, String documentId, String key, String value) =>
      _client.patchJson('/api/deals/$dealId/documents/$documentId/fields', body: {'key': key, 'value': value});

  /// An honest "how many questions are left" count right after upload -
  /// reuses the real extraction logic rather than a guess.
  Future<InterviewPreview> getInterviewPreview(String dealId, {String lang = 'ru'}) async {
    final json = await _client.getJson('/api/deals/$dealId/interview-preview', query: {'lang': lang});
    return InterviewPreview.fromJson(json as Map<String, dynamic>);
  }
}
