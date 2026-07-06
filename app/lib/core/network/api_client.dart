import 'package:app/core/config/app_config.dart';

class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final String baseUrl;
}
