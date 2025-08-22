import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

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
  // Prefer a --dart-define at build time; falls back to Render default.
  static const String _defaultBase = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://power6-backend.onrender.com',
  );

  final String baseUrl;
  ApiService({String? baseUrl}) : baseUrl = (baseUrl ?? _defaultBase).trim();

  // Reasonable network timeout to prevent infinite spinners.
  static const Duration _timeout = Duration(seconds: 20);

  Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, {Map<String, dynamic>? query}) {
    final hasSlashEnd = baseUrl.endsWith('/');
    final hasSlashStart = path.startsWith('/');
    final joined = hasSlashEnd && hasSlashStart
        ? baseUrl + path.substring(1)
        : (!hasSlashEnd && !hasSlashStart)
            ? '$baseUrl/$path'
            : '$baseUrl$path';
    final qp = query?.map((k, v) => MapEntry(k, v?.toString()));
    return Uri.parse(joined).replace(queryParameters: qp);
  }

  Future<ApiResponse> get(String path, {String? token, Map<String, dynamic>? query}) async {
    try {
      final res = await http
          .get(_uri(path, query: query), headers: _headers(token: token))
          .timeout(ApiService._timeout);
      return _toResponse(res);
    } on TimeoutException {
      return ApiResponse.failure('Request timed out');
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  Future<ApiResponse> post(String path, {String? token, Map<String, dynamic>? body, Map<String, dynamic>? query}) async {
    try {
      final res = await http
          .post(
            _uri(path, query: query),
            headers: _headers(token: token),
            body: jsonEncode(body ?? <String, dynamic>{}),
          )
          .timeout(ApiService._timeout);
      return _toResponse(res);
    } on TimeoutException {
      return ApiResponse.failure('Request timed out');
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  // Non-breaking additions used by other parts of the app (e.g., task updates)
  Future<ApiResponse> put(String path, {String? token, Map<String, dynamic>? body, Map<String, dynamic>? query}) async {
    try {
      final res = await http
          .put(
            _uri(path, query: query),
            headers: _headers(token: token),
            body: jsonEncode(body ?? <String, dynamic>{}),
          )
          .timeout(ApiService._timeout);
      return _toResponse(res);
    } on TimeoutException {
      return ApiResponse.failure('Request timed out');
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  Future<ApiResponse> delete(String path, {String? token, Map<String, dynamic>? query}) async {
    try {
      final res = await http
          .delete(
            _uri(path, query: query),
            headers: _headers(token: token),
          )
          .timeout(ApiService._timeout);
      return _toResponse(res);
    } on TimeoutException {
      return ApiResponse.failure('Request timed out');
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  ApiResponse _toResponse(http.Response res) {
    final ok = res.statusCode >= 200 && res.statusCode < 300;

    // Try to decode JSON (Map or List). If not JSON, fall back to raw body.
    Map<String, dynamic>? jsonMap;
    dynamic decodedAny;
    try {
      if (res.body.isNotEmpty) {
        decodedAny = jsonDecode(res.body);
        if (decodedAny is Map<String, dynamic>) {
          jsonMap = decodedAny;
        }
      }
    } catch (_) {
      // Not JSON; ignore and fall back below
    }

    if (ok) {
      if (jsonMap != null) {
        return ApiResponse.success(jsonMap);
      }
      if (decodedAny is List) {
        // Wrap arrays so callers still receive a Map without breaking type
        return ApiResponse.success(<String, dynamic>{'items': decodedAny});
      }
      if (res.body.isNotEmpty) {
        return ApiResponse.success(<String, dynamic>{'raw': res.body});
      }
      return ApiResponse.success(<String, dynamic>{});
    }

    // Error path: prefer FastAPI/Stripe 'detail' or 'error' field when present
    final String message =
        (jsonMap?['detail']?.toString() ?? jsonMap?['error']?.toString() ?? res.body.toString().trim());
    return ApiResponse.failure(message.isEmpty ? 'HTTP ${res.statusCode}' : message);
  }
}

// ---- Extra helpers (non-breaking) to support additional endpoints if needed ----
extension ApiServiceExtras on ApiService {
  Future<ApiResponse> patch(String path, {String? token, Map<String, dynamic>? body, Map<String, dynamic>? query}) async {
    try {
      final res = await http
          .patch(
            _uri(path, query: query),
            headers: _headers(token: token),
            body: jsonEncode(body ?? <String, dynamic>{}),
          )
          .timeout(ApiService._timeout);
      return _toResponse(res);
    } on TimeoutException {
      return ApiResponse.failure('Request timed out');
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  Future<ApiResponse> postForm(String path, {String? token, Map<String, String>? form, Map<String, dynamic>? query}) async {
    try {
      final headers = _headers(token: token);
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
      final res = await http
          .post(
            _uri(path, query: query),
            headers: headers,
            body: form ?? <String, String>{},
          )
          .timeout(ApiService._timeout);
      return _toResponse(res);
    } on TimeoutException {
      return ApiResponse.failure('Request timed out');
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  Future<ApiResponse> head(String path, {String? token, Map<String, dynamic>? query}) async {
    try {
      final req = http.Request('HEAD', _uri(path, query: query));
      req.headers.addAll(_headers(token: token));
      final resStream = await http.Client().send(req).timeout(ApiService._timeout);
      final res = await http.Response.fromStream(resStream);
      return _toResponse(res);
    } on TimeoutException {
      return ApiResponse.failure('Request timed out');
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }
}
