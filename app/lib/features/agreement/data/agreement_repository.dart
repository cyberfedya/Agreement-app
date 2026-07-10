import 'package:app/core/network/api_exception.dart';
import 'package:app/core/services/api_service.dart';
import 'package:app/features/agreement/domain/agreement.dart';
import 'package:app/features/agreement/domain/deal_invite.dart';
import 'package:app/shared/models/result.dart';

abstract class AgreementRepository {
  Future<Result<Agreement>> generate(String dealId, Map<int, String> answers);
  Future<Result<Agreement>> getByDealId(String dealId);
  Future<Result<void>> signAsSecondParty(String dealId, String fullName);
  Future<Result<DealInvite>> getInvite(String dealId);
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
  Future<Result<DealInvite>> getInvite(String dealId) async {
    try {
      return Success(await _api.getDealInvite(dealId));
    } on NotFoundException {
      return const Failure('Это приглашение не найдено или уже недействительно.');
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }
}