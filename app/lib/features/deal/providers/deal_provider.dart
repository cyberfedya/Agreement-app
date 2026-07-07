import 'package:app/features/deal/data/deal_repository.dart';

/// Scaffold for the V2 deals feature. Not wired into routing yet.
class DealProvider {
  DealProvider(this.repository);

  final DealRepository repository;
}
