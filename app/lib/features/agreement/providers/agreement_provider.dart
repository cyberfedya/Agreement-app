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

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Agreement? get agreement => _agreement;

  Future<bool> generate(String templateKey, Map<int, String> answers) async {
    _isLoading = true;
    _errorMessage = null;
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
}
