import 'package:flutter/foundation.dart';

import 'package:app/features/agreement/data/agreement_repository.dart';
import 'package:app/features/agreement/domain/agreement.dart';
import 'package:app/shared/models/result.dart';

class AgreementProvider extends ChangeNotifier {
  AgreementProvider(this._repository);

  final AgreementRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  Agreement? _agreement;
  String? _secondPartyName;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Agreement? get agreement => _agreement;

  String? get secondPartyName => _secondPartyName ?? _agreement?.secondPartyName;
  bool get isFullySigned => secondPartyName != null;

  Future<bool> generate(String templateKey, Map<int, String> answers) async {
    _isLoading = true;
    _errorMessage = null;
    _secondPartyName = null;
    notifyListeners();

    var success = false;
    switch (await _repository.generate(templateKey, answers)) {
      case Success(:final value):
        _agreement = value;
        success = true;
      case Failure(:final message):
        _errorMessage = message;
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Fetches an already-generated agreement by deal id - the second
  /// party's entry point after scanning the QR code, on their own device
  /// with its own (otherwise empty) provider instance.
  Future<void> loadByDealId(String dealId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    switch (await _repository.getByDealId(dealId)) {
      case Success(:final value):
        _agreement = value;
      case Failure(:final message):
        _errorMessage = message;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Silently re-fetches the deal's agreement (no loading/error state
  /// churn) so the creator's device can notice, by polling, that the
  /// second party signed on their own separate device - there's no push
  /// mechanism, so this is how [isFullySigned] ever becomes true for the
  /// party that didn't do the signing.
  Future<void> refreshStatus(String dealId) async {
    if (await _repository.getByDealId(dealId) case Success(:final value)) {
      _agreement = value;
      notifyListeners();
    }
  }

  /// Persists the second party's signature via the backend - not just
  /// local state, so it survives on the deal regardless of which device
  /// looks at it afterwards.
  Future<bool> signAsSecondParty(String dealId, String fullName) async {
    switch (await _repository.signAsSecondParty(dealId, fullName)) {
      case Success():
        _secondPartyName = fullName;
        notifyListeners();
        return true;
      case Failure(:final message):
        _errorMessage = message;
        notifyListeners();
        return false;
    }
  }
}
