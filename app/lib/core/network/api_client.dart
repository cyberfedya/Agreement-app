import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
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
    final response = await _send('GET', path, () => _http.get(_uri(path, query)));
    return _decode(response);
  }

  Future<dynamic> postJson(String path, {Object? body, Map<String, String>? query}) async {
    final response = await _send(
      'POST',
      path,
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
    final response = await _send('POST', path, () async {
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
      'PUT',
      path,
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
      'PATCH',
      path,
      () => _http.patch(
        _uri(path, query),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<void> deleteJson(String path, {Map<String, String>? query}) async {
    final response = await _send('DELETE', path, () => _http.delete(_uri(path, query)));
    _decode(response);
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized').replace(queryParameters: query);
  }

  Future<http.Response> _send(
    String method,
    String path,
    Future<http.Response> Function() request, {
    Duration? timeout,
  }) async {
    final stopwatch = kDebugMode ? (Stopwatch()..start()) : null;
    try {
      final response = await request().timeout(timeout ?? AppConstants.defaultTimeout);
      _log(method, path, response.statusCode, response.body.length, stopwatch);
      return response;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      _log(method, path, null, null, stopwatch, error: 'timeout');
      throw const ApiTimeoutException();
    } on SocketException {
      // No route to the server at all - offline or DNS/connection failure.
      _log(method, path, null, null, stopwatch, error: 'offline');
      throw const NetworkException();
    } catch (e) {
      _log(method, path, null, null, stopwatch, error: e.toString());
      throw const NetworkException();
    }
  }

  dynamic _decode(http.Response response) {
    final statusCode = response.statusCode;
    final dynamic body;
    try {
      body = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      // 2xx with a body that isn't valid JSON at all - treat as malformed
      // rather than letting jsonDecode's raw exception escape to callers.
      throw const MalformedResponseException();
    }

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    }
    if (statusCode == 404) {
      throw const NotFoundException();
    }
    throw ServerException(statusCode: statusCode, body: body);
  }

  /// Debug-only network trace: method, path, status, response size and
  /// duration. Compiled out of release builds - [kDebugMode] is a
  /// compile-time constant, so the release binary never contains this
  /// branch's string formatting or the [debugPrint] call.
  void _log(String method, String path, int? statusCode, int? bodyBytes, Stopwatch? stopwatch, {String? error}) {
    if (!kDebugMode) return;
    final ms = stopwatch?.elapsedMilliseconds;
    if (error != null) {
      debugPrint('[api] $method $path -> $error (${ms}ms)');
    } else {
      debugPrint('[api] $method $path -> $statusCode (${bodyBytes}b, ${ms}ms)');
    }
  }
}
