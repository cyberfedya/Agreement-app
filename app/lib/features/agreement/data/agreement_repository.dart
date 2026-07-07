import 'package:app/core/network/api_exception.dart';
import 'package:app/core/services/api_service.dart';
import 'package:app/features/agreement/domain/agreement.dart';
import 'package:app/shared/models/result.dart';

abstract class AgreementRepository {
  Future<Result<Agreement>> generate(String templateKey, Map<int, String> answers);
}

class ApiAgreementRepository implements AgreementRepository {
  ApiAgreementRepository(this._api);

  final ApiService _api;

  @override
  Future<Result<Agreement>> generate(String templateKey, Map<int, String> answers) async {
    try {
      return Success(await _api.generateAgreement(templateKey, answers));
    } on MissingFieldsException catch (e) {
      return Failure(e.message);
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }
}
