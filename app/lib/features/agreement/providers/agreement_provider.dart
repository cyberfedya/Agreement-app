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
  String? _firstPartyName;

  /// Guards [signAsSecondParty]/[signAsFirstParty] against a double tap
  /// firing two concurrent sign requests - separate from [_isLoading],
  /// which tracks generate/load instead.
  bool _isSigning = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Agreement? get agreement => _agreement;

  String? get secondPartyName => _secondPartyName ?? _agreement?.secondPartyName;
  String? get firstPartyName => _firstPartyName ?? _agreement?.firstPartyName;

  bool get isSecondPartySigned => secondPartyName != null;
  bool get isFirstPartySigned => firstPartyName != null;

  /// True only once BOTH parties have signed - one party signing alone is
  /// never enough to complete the agreement.
  bool get isFullySigned => (_agreement?.isFullySigned ?? false) || (isFirstPartySigned && isSecondPartySigned);

  Future<bool> generate(String templateKey, Map<int, String> answers) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    _secondPartyName = null;
    _firstPartyName = null;
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
  /// churn) so either device can notice, by polling, that the other party
  /// signed on their own separate device - there's no push mechanism, so
  /// this is how [isFullySigned] ever becomes true for the party that
  /// didn't do the signing.
  Future<void> refreshStatus(String dealId) async {
    if (await _repository.getByDealId(dealId) case Success(:final value)) {
      _agreement = value;
      notifyListeners();
    }
  }

  /// Persists the second party's signature via the backend - not just
  /// local state, so it survives on the deal regardless of which device
  /// looks at it afterwards. Never touches the first party's signature.
  Future<bool> signAsSecondParty(String dealId, String fullName) async {
    if (_isSigning || isSecondPartySigned) return false;
    _isSigning = true;
    try {
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
    } finally {
      _isSigning = false;
    }
  }

  /// Persists the first party's (creator's) signature via the backend.
  /// Never touches the second party's signature.
  Future<bool> signAsFirstParty(String dealId, String fullName) async {
    if (_isSigning || isFirstPartySigned) return false;
    _isSigning = true;
    try {
      switch (await _repository.signAsFirstParty(dealId, fullName)) {
        case Success():
          _firstPartyName = fullName;
          notifyListeners();
          return true;
        case Failure(:final message):
          _errorMessage = message;
          notifyListeners();
          return false;
      }
    } finally {
      _isSigning = false;
    }
  }
}
