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

  /// Demo-only: there is no backend endpoint yet to persist a generated
  /// agreement and fetch it back from a second device by key, so signing is
  /// simulated within the same session/device that generated it.
  String? get secondPartyName => _secondPartyName;
  bool get isFullySigned => _secondPartyName != null;

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

  void signAsSecondParty(String fullName) {
    _secondPartyName = fullName;
    notifyListeners();
  }
}
