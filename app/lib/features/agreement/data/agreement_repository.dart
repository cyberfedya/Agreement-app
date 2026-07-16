import 'package:app/core/localization/locale_provider.dart';
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
  Future<Result<void>> acceptInvite(String dealId, String profileId);
  Future<Result<void>> declineInvite(String dealId, {String? reason, String? profileId});
  Future<Result<void>> proposeFieldChange(
    String dealId, {
    required int fieldId,
    required String proposedValue,
    String? reason,
    String? profileId,
  });
  Future<Result<void>> requestClarification(String dealId, {required String message, String? profileId});
}

/// Domain-specific fallback messages for cases the backend signals by
/// status code/error tag alone (no `message` body) - translated here,
/// the same way [ApiErrorMessages] covers transport-level failures,
/// since this repository has no `BuildContext`/`AppLocalizations` to
/// localize against.
abstract final class _Messages {
  static const _agreementNotFound = {
    'ru': 'Этот договор не найден или ещё не сформирован.',
    'uz': 'Бу шартнома топилмади ёки ҳали шакллантирилмаган.',
    'en': "This agreement wasn't found or hasn't been generated yet.",
  };
  static const _inviteNotFound = {
    'ru': 'Это приглашение не найдено или уже недействительно.',
    'uz': 'Бу таклиф топилмади ёки аллақачон амал қилмайди.',
    'en': "This invite wasn't found or is no longer valid.",
  };
  static const _ownInvite = {
    'ru': 'Нельзя принять собственное приглашение.',
    'uz': 'Ўз таклифингизни қабул қила олмайсиз.',
    'en': "You can't accept your own invite.",
  };
  static const _alreadyResponded = {
    'ru': 'Вы уже ответили на это приглашение.',
    'uz': 'Сиз бу таклифга аллақачон жавоб бердингиз.',
    'en': "You've already responded to this invite.",
  };
  static const _inviteExpired = {
    'ru': 'Срок действия приглашения истёк.',
    'uz': 'Таклифнинг амал қилиш муддати тугаган.',
    'en': 'This invite has expired.',
  };
  static const _alreadyAccepted = {
    'ru': 'Приглашение уже принято — отклонить его нельзя.',
    'uz': 'Таклиф аллақачон қабул қилинган — уни рад этиб бўлмайди.',
    'en': "The invite has already been accepted — it can't be declined.",
  };
  static const _fieldNotEditable = {
    'ru': 'Это условие изменить нельзя.',
    'uz': 'Бу шартни ўзгартириб бўлмайди.',
    'en': "This term can't be changed.",
  };

  static String _pick(Map<String, String> table, String languageCode) => table[languageCode] ?? table['ru']!;

  static String agreementNotFound(String lang) => _pick(_agreementNotFound, lang);
  static String inviteNotFound(String lang) => _pick(_inviteNotFound, lang);
  static String ownInvite(String lang) => _pick(_ownInvite, lang);
  static String alreadyResponded(String lang) => _pick(_alreadyResponded, lang);
  static String inviteExpired(String lang) => _pick(_inviteExpired, lang);
  static String alreadyAccepted(String lang) => _pick(_alreadyAccepted, lang);
  static String fieldNotEditable(String lang) => _pick(_fieldNotEditable, lang);
}

class ApiAgreementRepository implements AgreementRepository {
  ApiAgreementRepository(this._api, this._localeProvider);
  final ApiService _api;
  final LocaleProvider _localeProvider;
  String get _lang => _localeProvider.languageCode;
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
      return Failure(_Messages.agreementNotFound(_lang));
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
      return Failure(_Messages.inviteNotFound(_lang));
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
        return Failure(_Messages.ownInvite(_lang));
      }
      if (e.statusCode == 409) return Failure(_Messages.alreadyResponded(_lang));
      if (e.statusCode == 410) return Failure(_Messages.inviteExpired(_lang));
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
      if (e.statusCode == 409) return Failure(_Messages.alreadyAccepted(_lang));
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
        return Failure(_Messages.fieldNotEditable(_lang));
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
