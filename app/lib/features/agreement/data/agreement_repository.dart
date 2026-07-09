import 'package:app/core/network/api_exception.dart';
import 'package:app/core/services/api_service.dart';
import 'package:app/features/agreement/domain/agreement.dart';
import 'package:app/shared/models/result.dart';

abstract class AgreementRepository {
  Future<Result<Agreement>> generate(String dealId, Map<int, String> answers);

  /// Fetches an already-generated agreement by deal id - used by the
  /// second party after scanning the QR code, on their own device.
  Future<Result<Agreement>> getByDealId(String dealId);

  /// Records the second party's signature after they identify themselves.
  Future<Result<void>> signAsSecondParty(String dealId, String fullName);
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
}
