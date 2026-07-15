import 'package:flutter/foundation.dart';

import 'package:app/features/deal/data/deal_repository.dart';
import 'package:app/features/deal/domain/deal_history.dart';
import 'package:app/shared/models/result.dart';

class DealHistoryProvider extends ChangeNotifier {
  DealHistoryProvider(this._repository);

  static const int _pageSize = 20;

  final DealRepository _repository;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  List<DealSummary> _deals = const [];
  int _page = 1;
  bool _hasMore = false;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  List<DealSummary> get deals => _deals;
  bool get hasMore => _hasMore;

  /// Loads once and caches; use [refresh] to force a reload (pull-to-refresh
  /// or after a cancel/create action changes the list).
  Future<void> load() async {
    if (_hasLoaded || _isLoading) return;
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    switch (await _repository.listDeals(page: 1, pageSize: _pageSize)) {
      case Success(:final value):
        _deals = value.items;
        _page = value.page;
        _hasMore = value.hasMore;
        _hasLoaded = true;
      case Failure(:final message):
        _errorMessage = message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    switch (await _repository.listDeals(page: _page + 1, pageSize: _pageSize)) {
      case Success(:final value):
        _deals = [..._deals, ...value.items];
        _page = value.page;
        _hasMore = value.hasMore;
      case Failure(:final message):
        _errorMessage = message;
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  /// Cancels [dealId] and removes it from the list optimistically-adjacent:
  /// only after the server confirms, so a failed cancel leaves the card in
  /// place instead of flashing it away and back.
  Future<Result<void>> cancel(String dealId) async {
    final result = await _repository.cancelDeal(dealId);
    if (result is Success) {
      await refresh();
    }
    return result;
  }
}
