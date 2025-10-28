import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';

/// Lightweight, generic API response wrapper.
class ApiResponse {
  final bool isSuccess;
  final Map<String, dynamic>? data;
  final String? error;
  ApiResponse.success(this.data)
      : isSuccess = true,
        error = null;
  ApiResponse.failure(this.error)
      : isSuccess = false,
        data = null;
}

class ApiService {
  static final String _resolvedBase = (ApiConstants.baseUrl).trim();
  final String baseUrl;
  final http.Client _client; // re-usable client for perf

  ApiService({String? baseUrl, http.Client? client})
      : baseUrl = ((baseUrl ?? _resolvedBase).trim()),
        _client = client ?? http.Client() {
    if (this.baseUrl.isEmpty) {
      throw StateError(
        'API base URL is missing. Provide --dart-define=API_BASE_URL or set a default in ApiConstants.',
      );
    }
  }

  static const Duration _timeout = Duration(seconds: 20);

  Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Map<String, String>? _stringQuery(Map<String, dynamic>? q) {
    if (q == null) return null;
    final out = <String, String>{};
    q.forEach((k, v) {
      if (v != null) out[k] = v.toString(); // drop nulls instead of "null"
    });
    return out.isEmpty ? null : out;
  }

  Uri _uri(String path, {Map<String, dynamic>? query}) {
    final hasSlashEnd = baseUrl.endsWith('/');
    final hasSlashStart = path.startsWith('/');
    final joined = hasSlashEnd && hasSlashStart
        ? baseUrl + path.substring(1)
        : (!hasSlashEnd && !hasSlashStart)
            ? '$baseUrl/$path'
            : '$baseUrl$path';
    return Uri.parse(joined).replace(queryParameters: _stringQuery(query));
  }

  Future<ApiResponse> get(String path,
      {String? token, Map<String, dynamic>? query}) async {
    try {
      final res = await _client
          .get(_uri(path, query: query), headers: _headers(token: token))
          .timeout(_timeout);
      return _toResponse(res);
    } on TimeoutException {
      return ApiResponse.failure('Request timed out');
    } on SocketException {
      return ApiResponse.failure('Network unavailable');
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  Future<ApiResponse> post(String path,
      {String? token,
      Map<String, dynamic>? body,
      Map<String, dynamic>? query}) async {
    try {
      final res = await _client
          .post(
            _uri(path, query: query),
            headers: _headers(token: token),
            body: jsonEncode(body ?? const <String, dynamic>{}),
          )
          .timeout(_timeout);
      return _toResponse(res);
    } on TimeoutException {
      return ApiResponse.failure('Request timed out');
    } on SocketException {
      return ApiResponse.failure('Network unavailable');
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  Future<ApiResponse> put(String path,
      {String? token,
      Map<String, dynamic>? body,
      Map<String, dynamic>? query}) async {
    try {
      final res = await _client
          .put(
            _uri(path, query: query),
            headers: _headers(token: token),
            body: jsonEncode(body ?? const <String, dynamic>{}),
          )
          .timeout(_timeout);
      return _toResponse(res);
    } on TimeoutException {
      return ApiResponse.failure('Request timed out');
    } on SocketException {
      return ApiResponse.failure('Network unavailable');
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  Future<ApiResponse> patch(String path,
      {String? token,
      Map<String, dynamic>? body,
      Map<String, dynamic>? query}) async {
    try {
      final res = await _client
          .patch(
            _uri(path, query: query),
            headers: _headers(token: token),
            body: jsonEncode(body ?? const <String, dynamic>{}),
          )
          .timeout(_timeout);
      return _toResponse(res);
    } on TimeoutException {
      return ApiResponse.failure('Request timed out');
    } on SocketException {
      return ApiResponse.failure('Network unavailable');
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  Future<ApiResponse> delete(String path,
      {String? token, Map<String, dynamic>? query}) async {
    try {
      final res = await _client
          .delete(_uri(path, query: query), headers: _headers(token: token))
          .timeout(_timeout);
      return _toResponse(res);
    } on TimeoutException {
      return ApiResponse.failure('Request timed out');
    } on SocketException {
      return ApiResponse.failure('Network unavailable');
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  ApiResponse _toResponse(http.Response res) {
    final ok = res.statusCode >= 200 && res.statusCode < 300;

    Map<String, dynamic>? jsonMap;
    dynamic decodedAny;
    try {
      if (res.body.isNotEmpty) {
        decodedAny = jsonDecode(res.body);
        if (decodedAny is Map<String, dynamic>) jsonMap = decodedAny;
      }
    } catch (_) {}

    if (ok) {
      if (jsonMap != null) return ApiResponse.success(jsonMap);
      if (decodedAny is List) {
        return ApiResponse.success(<String, dynamic>{'items': decodedAny});
      }
      if (res.body.isNotEmpty) {
        return ApiResponse.success(<String, dynamic>{'raw': res.body});
      }
      return ApiResponse.success(<String, dynamic>{});
    }

    // Provide clearer auth errors to the UI.
    if (res.statusCode == 401 || res.statusCode == 403) {
      return ApiResponse.failure('Unauthorized');
    }

    final String message = (jsonMap?['detail']?.toString() ??
        jsonMap?['error']?.toString() ??
        res.body.toString().trim());
    return ApiResponse.failure(
        message.isEmpty ? 'HTTP ${res.statusCode}' : message);
  }

  void dispose() {
    _client.close(); // free sockets
  }
}
