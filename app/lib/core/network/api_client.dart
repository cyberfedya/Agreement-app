import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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

  /// Uploads one or more files as multipart/form-data. Each entry in
  /// [files] is (fieldName, fileName, contentType, bytes). Uses a longer
  /// timeout than [AppConstants.defaultTimeout] - the backend OCRs each
  /// file synchronously before responding (no background job queue), so
  /// this can genuinely take much longer than a normal JSON call.
  Future<dynamic> postMultipart(
    String path, {
    required List<(String field, String fileName, String contentType, List<int> bytes)> files,
    Map<String, String>? query,
  }) async {
    final response = await _send(() async {
      final request = http.MultipartRequest('POST', _uri(path, query));
      for (final (field, fileName, contentType, bytes) in files) {
        request.files.add(
          http.MultipartFile.fromBytes(
            field,
            bytes,
            filename: fileName,
            contentType: MediaType.parse(contentType),
          ),
        );
      }
      final streamed = await _http.send(request);
      return http.Response.fromStream(streamed);
    }, timeout: AppConstants.uploadTimeout);
    return _decode(response);
  }

  Future<dynamic> putJson(String path, {Object? body, Map<String, String>? query}) async {
    final response = await _send(
      () => _http.put(
        _uri(path, query),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<dynamic> patchJson(String path, {Object? body, Map<String, String>? query}) async {
    final response = await _send(
      () => _http.patch(
        _uri(path, query),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<void> deleteJson(String path, {Map<String, String>? query}) async {
    final response = await _send(() => _http.delete(_uri(path, query)));
    _decode(response);
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized').replace(queryParameters: query);
  }

  Future<http.Response> _send(Future<http.Response> Function() request, {Duration? timeout}) async {
    try {
      return await request().timeout(timeout ?? AppConstants.defaultTimeout);
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
