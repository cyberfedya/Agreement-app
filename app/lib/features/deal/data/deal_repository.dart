import 'package:app/core/localization/locale_provider.dart';
import 'package:app/core/network/api_exception.dart';
import 'package:app/core/services/api_service.dart';
import 'package:app/features/deal/domain/deal.dart';
import 'package:app/features/deal/domain/deal_history.dart';
import 'package:app/features/profile/data/profile_repository.dart';
import 'package:app/shared/models/result.dart';

abstract class DealRepository {
  /// Matches free-form [text] to a template via the AI and opens a deal for
  /// it. `Success(null)` means the AI found no reasonable match — the
  /// caller should fall back to manual template selection.
  Future<Result<Deal?>> createFromText(String text);

  /// Opens a deal for a manually-picked template — same downstream flow as
  /// [createFromText], just skipping AI classification.
  Future<Result<Deal>> createFromTemplate(String templateKey);

  /// Deals for the current profile, newest first — feeds Deal History.
  Future<Result<DealHistoryPage>> listDeals({int page = 1, int pageSize = 20});

  /// Cancels a deal that hasn't been fully signed yet.
  Future<Result<void>> cancelDeal(String dealId);
}

class ApiDealRepository implements DealRepository {
  ApiDealRepository(this._api, this._profiles, this._localeProvider);

  final ApiService _api;
  final ProfileRepository _profiles;
  final LocaleProvider _localeProvider;

  @override
  Future<Result<Deal?>> createFromText(String text) async {
    try {
      final profileId = await _profiles.getProfileId();
      return Success(await _api.createDeal(text: text, profileId: profileId, lang: _localeProvider.languageCode));
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<Deal>> createFromTemplate(String templateKey) async {
    try {
      final profileId = await _profiles.getProfileId();
      final deal = await _api.createDeal(
        templateKey: templateKey,
        profileId: profileId,
        lang: _localeProvider.languageCode,
      );
      // The template key came from our own catalog, so a null (no-match)
      // response here would mean the backend and app disagree about what
      // exists — treat it as a server error, not a normal outcome.
      if (deal == null) return const Failure('Could not open this template.');
      return Success(deal);
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<DealHistoryPage>> listDeals({int page = 1, int pageSize = 20}) async {
    try {
      final profileId = await _profiles.getProfileId();
      final result = await _api.listDeals(
        profileId,
        page: page,
        pageSize: pageSize,
        lang: _localeProvider.languageCode,
      );
      return Success(result);
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<void>> cancelDeal(String dealId) async {
    try {
      await _api.cancelDeal(dealId);
      return const Success(null);
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }
}
