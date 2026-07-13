import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_exception.dart';
import 'package:app/features/agreement/domain/agreement.dart';
import 'package:app/features/agreement/domain/deal_invite.dart';
import 'package:app/features/deal/domain/deal.dart';
import 'package:app/features/documents/domain/interview_preview.dart';
import 'package:app/features/documents/domain/required_document.dart';
import 'package:app/features/documents/domain/uploaded_document.dart';
import 'package:app/features/profile/domain/user_profile.dart';
import 'package:app/features/questionnaire/domain/deal_review.dart';
import 'package:app/features/questionnaire/domain/interview_step.dart';
import 'package:app/features/questionnaire/domain/question.dart';
import 'package:app/features/templates/domain/template.dart';

class ApiService {
  ApiService(this._client);

  final ApiClient _client;

  /// Every `Model.fromJson`/cast call in this file goes through here: a
  /// 2xx response with a shape Flutter didn't expect (a renamed field, a
  /// changed type, a dropped key) throws [MalformedResponseException]
  /// instead of an uncaught `TypeError`/`type cast` error, so callers see
  /// a normal [Failure] and the app degrades gracefully instead of
  /// crashing on backend drift.
  T _parse<T>(T Function() decode) {
    try {
      return decode();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const MalformedResponseException();
    }
  }

  Future<List<TemplateSummary>> getTemplates({String lang = 'ru'}) async {
    final json = await _client.getJson('/api/templates', query: {'lang': lang});
    return _parse(() => (json as List).cast<Map<String, dynamic>>().map(TemplateSummary.fromJson).toList());
  }

  Future<TemplateDetail> getTemplate(String key, {String lang = 'ru'}) async {
    final json = await _client.getJson('/api/templates/$key', query: {'lang': lang});
    return _parse(() => TemplateDetail.fromJson(json as Map<String, dynamic>));
  }

  /// Lightweight preview only — the interview flow uses [getDealQuestions].
  Future<List<Question>> getQuestions(String key) async {
    final json = await _client.getJson('/api/templates/$key/questions');
    return _parse(() => (json as List).cast<Map<String, dynamic>>().map(Question.fromJson).toList());
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
      return _parse(() => Deal.fromJson(json as Map<String, dynamic>));
    } on ServerException catch (e) {
      if (e.statusCode == 422) return null;
      rethrow;
    }
  }

  Future<UserProfile> getProfile(String id) async {
    final json = await _client.getJson('/api/profile/$id');
    return _parse(() => UserProfile.fromJson(json as Map<String, dynamic>));
  }

  Future<UserProfile> saveProfile(String id, UserProfile profile) async {
    final json = await _client.putJson('/api/profile/$id', body: profile.toJson());
    return _parse(() => UserProfile.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deleteProfile(String id) => _client.deleteJson('/api/profile/$id');

  /// Every field the template has — used to render the full-document
  /// preview sheet. The interview itself is driven by [nextQuestion], one
  /// field at a time.
  Future<List<Question>> getDealQuestions(String dealId) async {
    final json = await _client.getJson('/api/deals/$dealId/questions');
    return _parse(() => (json as List).cast<Map<String, dynamic>>().map(Question.fromJson).toList());
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
    return _parse(() => InterviewStep.fromJson(json as Map<String, dynamic>));
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
      return _parse(() => Agreement.fromJson(json as Map<String, dynamic>));
    } on ServerException catch (e) {
      final body = e.body;
      if (e.statusCode == 400 && body is Map && body['error'] == 'missing_required_fields') {
        final ids = _parse(() => (body['missingFieldIds'] as List).cast<int>());
        throw MissingFieldsException(ids);
      }
      if (e.statusCode == 409 && body is Map && body['error'] == 'legal_review_required') {
        throw const LegalReviewRequiredException();
      }
      rethrow;
    }
  }

  /// The backend's deterministic pre-generation review: every template
  /// field grouped into auto-filled / manual / corrected / missing /
  /// skipped, with source, confidence and reason. No LLM calls, no
  /// mutation - safe to call on every review-screen build.
  Future<DealReview> getDealReview(String dealId) async {
    final json = await _client.getJson('/api/deals/$dealId/review');
    return _parse(() => DealReview.fromJson(json as Map<String, dynamic>));
  }

  /// Fetches an already-generated agreement by deal id - the cross-device
  /// counterpart to [generateFromDeal]. This is what lets the second party
  /// (whoever scanned the QR code, on their own device) retrieve the same
  /// document rather than relying on any local state.
  Future<Agreement> getDealAgreement(String dealId) async {
    final json = await _client.getJson('/api/deals/$dealId/agreement');
    return _parse(() => Agreement.fromJson(json as Map<String, dynamic>));
  }

  /// Invite metadata only (type, roles, who invited, status) - shown
  /// before the second party ever sees the agreement's HTML.
  Future<DealInvite> getDealInvite(String dealId, {String lang = 'ru'}) async {
    final json = await _client.getJson('/api/deals/$dealId/invite', query: {'lang': lang});
    return _parse(() => DealInvite.fromJson(json as Map<String, dynamic>));
  }

  /// Links [profileId] to the deal as the second party - no HTML, no
  /// regeneration; the caller re-runs [generateFromDeal] afterwards if it
  /// wants the document to reflect the newly-linked profile.
  Future<void> acceptDealInvite(String dealId, String profileId) =>
      _client.postJson('/api/deals/$dealId/invite/accept', body: {'profileId': profileId});

  /// Declines the invite, optionally with a human-readable [reason] the
  /// first party will see. 409 `already_accepted` when it's too late.
  Future<void> declineDealInvite(String dealId, {String? reason, String? profileId}) =>
      _client.postJson('/api/deals/$dealId/invite/decline', body: {'reason': reason, 'profileId': profileId});

  /// Second party's counter-offer on one field ("не 18 000, а 17 500") -
  /// recorded on the deal; the first party sees it as a dispute in the
  /// review's field states.
  Future<void> proposeDealFieldChange(
    String dealId, {
    required int fieldId,
    required String proposedValue,
    String? reason,
    String? profileId,
  }) =>
      _client.postJson(
        '/api/deals/$dealId/invite/propose-change',
        body: {'fieldId': fieldId, 'proposedValue': proposedValue, 'reason': reason, 'profileId': profileId},
      );

  /// Second party asks the first party a free-form question before
  /// deciding - recorded on the deal (invite status becomes
  /// ClarificationRequested).
  Future<void> requestDealClarification(String dealId, {required String message, String? profileId}) =>
      _client.postJson('/api/deals/$dealId/invite/clarification', body: {'message': message, 'profileId': profileId});

  Future<void> signDealSecondParty(String dealId, String fullName) =>
      _client.postJson('/api/deals/$dealId/sign', body: {'fullName': fullName});

  Future<void> signDealFirstParty(String dealId, String fullName) =>
      _client.postJson('/api/deals/$dealId/sign/first', body: {'fullName': fullName});

  /// Documents worth suggesting the user upload for this deal's template -
  /// empty when nothing useful comes to mind (never identity documents).
  Future<List<RequiredDocument>> getRequiredDocuments(String dealId, {String lang = 'ru'}) async {
    final json = await _client.getJson('/api/deals/$dealId/required-documents', query: {'lang': lang});
    return _parse(() => (json as List).cast<Map<String, dynamic>>().map(RequiredDocument.fromJson).toList());
  }

  Future<List<UploadedDocument>> getDealDocuments(String dealId) async {
    final json = await _client.getJson('/api/deals/$dealId/documents');
    return _parse(() => (json as List).cast<Map<String, dynamic>>().map(UploadedDocument.fromJson).toList());
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
    return _parse(() => (json as List).cast<Map<String, dynamic>>().map(UploadedDocument.fromJson).toList());
  }

  Future<void> deleteDocument(String dealId, String documentId) =>
      _client.deleteJson('/api/deals/$dealId/documents/$documentId');

  Future<void> updateDocumentField(String dealId, String documentId, String key, String value) =>
      _client.patchJson('/api/deals/$dealId/documents/$documentId/fields', body: {'key': key, 'value': value});

  /// An honest "how many questions are left" count right after upload -
  /// reuses the real extraction logic rather than a guess.
  Future<InterviewPreview> getInterviewPreview(String dealId, {String lang = 'ru'}) async {
    final json = await _client.getJson('/api/deals/$dealId/interview-preview', query: {'lang': lang});
    return _parse(() => InterviewPreview.fromJson(json as Map<String, dynamic>));
  }
}
