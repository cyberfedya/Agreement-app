import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:app/core/config/app_config.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/network/api_exception.dart';

/// Thin, typed HTTP+JSON transport. Callers never see raw JSON — every
/// caller decodes into a domain model right after the get/post call returns.
class ApiClient {
  ApiClient({String? baseUrl, http.Client? httpClient})
    : baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
      _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;

  Future<dynamic> getJson(String path, {Map<String, String>? query}) async {
    final response = await _send(() => _http.get(_uri(path, query)));
    return _decode(response);
  }

  Future<dynamic> postJson(String path, {Object? body, Map<String, String>? query}) async {
    final response = await _send(
      () => _http.post(
        _uri(path, query),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized').replace(queryParameters: query);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(AppConstants.defaultTimeout);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const NetworkException();
    }
  }

  dynamic _decode(http.Response response) {
    final statusCode = response.statusCode;
    final dynamic body = response.body.isEmpty ? null : jsonDecode(response.body);

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    }
    if (statusCode == 404) {
      throw const NotFoundException();
    }
    throw ServerException(statusCode: statusCode, body: body);
  }
}
