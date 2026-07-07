import 'package:flutter/foundation.dart';

import 'package:app/features/templates/data/template_repository.dart';
import 'package:app/features/templates/domain/template.dart';
import 'package:app/shared/models/result.dart';

class TemplatesListProvider extends ChangeNotifier {
  TemplatesListProvider(this._repository);

  final TemplateRepository _repository;

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  List<TemplateSummary> _templates = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<TemplateSummary> get templates => _templates;

  /// Distinct category slugs, in catalog order.
  List<String> get categories =>
      {for (final t in _templates) t.domain}.toList();

  /// Loads once and caches; Home and the list page share the same data.
  /// Use [refresh] for pull-to-refresh.
  Future<void> load() async {
    if (_hasLoaded || _isLoading) return;
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    switch (await _repository.getTemplates()) {
      case Success(:final value):
        _templates = value;
        _hasLoaded = true;
      case Failure(:final message):
        _errorMessage = message;
    }

    _isLoading = false;
    notifyListeners();
  }
}
