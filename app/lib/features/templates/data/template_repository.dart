import 'package:app/core/network/api_exception.dart';
import 'package:app/core/services/api_service.dart';
import 'package:app/features/templates/domain/template.dart';
import 'package:app/shared/models/result.dart';

abstract class TemplateRepository {
  Future<Result<List<TemplateSummary>>> getTemplates();
  Future<Result<TemplateDetail>> getTemplate(String key);
}

class ApiTemplateRepository implements TemplateRepository {
  ApiTemplateRepository(this._api);

  final ApiService _api;

  @override
  Future<Result<List<TemplateSummary>>> getTemplates() async {
    try {
      return Success(await _api.getTemplates());
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<TemplateDetail>> getTemplate(String key) async {
    try {
      return Success(await _api.getTemplate(key));
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }
}
