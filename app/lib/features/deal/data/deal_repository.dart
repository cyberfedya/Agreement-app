import 'package:app/features/deal/domain/deal.dart';

abstract class DealRepository {
  Future<Deal> createDeal();
  Future<Deal> getDeal(String id);
}
