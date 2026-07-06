import 'package:app/features/agreement/domain/agreement.dart';

abstract class AgreementRepository {
  Future<Agreement> generate(String dealId);
  Future<String> exportPdf(String agreementId);
}
