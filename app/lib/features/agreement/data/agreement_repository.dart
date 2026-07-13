import 'package:app/core/network/api_exception.dart';
import 'package:app/core/services/api_service.dart';
import 'package:app/features/agreement/domain/agreement.dart';
import 'package:app/features/agreement/domain/deal_invite.dart';
import 'package:app/shared/models/result.dart';

abstract class AgreementRepository {
  Future<Result<Agreement>> generate(String dealId, Map<int, String> answers);
  Future<Result<Agreement>> getByDealId(String dealId);
  Future<Result<void>> signAsSecondParty(String dealId, String fullName);
  Future<Result<void>> signAsFirstParty(String dealId, String fullName);
  Future<Result<DealInvite>> getInvite(String dealId);

  /// Links [profileId] to the deal as the second party.
  Future<Result<void>> acceptInvite(String dealId, String profileId);

  /// Declines the invite with an optional reason for the first party.
  Future<Result<void>> declineInvite(String dealId, {String? reason, String? profileId});

  /// Second party's counter-offer on one field - shows up as a dispute in
  /// the first party's review.
  Future<Result<void>> proposeFieldChange(
    String dealId, {
    required int fieldId,
    required String proposedValue,
    String? reason,
    String? profileId,
  });

  /// Second party's free-form question to the first party.
  Future<Result<void>> requestClarification(String dealId, {required String message, String? profileId});
}

class ApiAgreementRepository implements AgreementRepository {
  ApiAgreementRepository(this._api);
  final ApiService _api;
  @override
  Future<Result<Agreement>> generate(String dealId, Map<int, String> answers) async {
    try {
      return Success(await _api.generateFromDeal(dealId, answers));
    } on MissingFieldsException catch (e) {
      return Failure(e.message);
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }
  @override
  Future<Result<Agreement>> getByDealId(String dealId) async {
    try {
      return Success(await _api.getDealAgreement(dealId));
    } on NotFoundException {
      return const Failure('Этот договор не найден или ещё не сформирован.');
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }
  @override
  Future<Result<void>> signAsSecondParty(String dealId, String fullName) async {
    try {
      await _api.signDealSecondParty(dealId, fullName);
      return const Success(null);
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }
  @override
  Future<Result<void>> signAsFirstParty(String dealId, String fullName) async {
    try {
      await _api.signDealFirstParty(dealId, fullName);
      return const Success(null);
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }
  @override
  Future<Result<DealInvite>> getInvite(String dealId) async {
    try {
      return Success(await _api.getDealInvite(dealId));
    } on NotFoundException {
      return const Failure('Это приглашение не найдено или уже недействительно.');
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }
  @override
  Future<Result<void>> acceptInvite(String dealId, String profileId) async {
    try {
      await _api.acceptDealInvite(dealId, profileId);
      return const Success(null);
    } on ServerException catch (e) {
      final body = e.body;
      if (e.statusCode == 409 && body is Map && body['error'] == 'own_invite') {
        return const Failure('Нельзя принять собственное приглашение.');
      }
      if (e.statusCode == 409) return const Failure('Вы уже ответили на это приглашение.');
      if (e.statusCode == 410) return const Failure('Срок действия приглашения истёк.');
      return Failure(e.message);
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<void>> declineInvite(String dealId, {String? reason, String? profileId}) async {
    try {
      await _api.declineDealInvite(dealId, reason: reason, profileId: profileId);
      return const Success(null);
    } on ServerException catch (e) {
      if (e.statusCode == 409) return const Failure('Приглашение уже принято — отклонить его нельзя.');
      return Failure(e.message);
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<void>> proposeFieldChange(
    String dealId, {
    required int fieldId,
    required String proposedValue,
    String? reason,
    String? profileId,
  }) async {
    try {
      await _api.proposeDealFieldChange(
        dealId,
        fieldId: fieldId,
        proposedValue: proposedValue,
        reason: reason,
        profileId: profileId,
      );
      return const Success(null);
    } on ServerException catch (e) {
      final body = e.body;
      if (e.statusCode == 400 && body is Map && body['error'] == 'invalid_field') {
        return const Failure('Это условие изменить нельзя.');
      }
      return Failure(e.message);
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<void>> requestClarification(String dealId, {required String message, String? profileId}) async {
    try {
      await _api.requestDealClarification(dealId, message: message, profileId: profileId);
      return const Success(null);
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }
}