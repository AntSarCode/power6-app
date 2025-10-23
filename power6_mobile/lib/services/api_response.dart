import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';

/// Lightweight, generic API response wrapper.
class ApiResponse<T> {
  final T? data;
  final String? error;
  final int? statusCode;

  /// Success is defined as "no error"; `data` may be null for endpoints
  /// that don't return a body (e.g., POST refresh).
  bool get isSuccess => error == null;

  const ApiResponse({this.data, this.error, this.statusCode});

  factory ApiResponse.success(T data, {int? statusCode}) =>
      ApiResponse<T>(data: data, statusCode: statusCode);

  factory ApiResponse.failure(String error, {int? statusCode}) =>
      ApiResponse<T>(error: error, statusCode: statusCode);
}

/// Simple HTTP helper used by some services. Most services can also call
/// `http` directly; this is just a convenience.
class ApiService {
  final http.Client client;

  ApiService({http.Client? httpClient}) : client = httpClient ?? http.Client();

  Map<String, String> _defaultHeaders({Map<String, String>? extra}) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...?extra,
      };

  Future<ApiResponse<Map<String, dynamic>>> get(String endpoint,
      {Map<String, String>? headers}) async {
    try {
      final res = await client.get(
        Uri.parse(ApiConstants.baseUrl + endpoint),
        headers: _defaultHeaders(extra: headers),
      );

      if (res.statusCode == 200) {
        final body = res.body.isEmpty
            ? <String, dynamic>{}
            : (json.decode(res.body) as Map<String, dynamic>);
        return ApiResponse.success(body, statusCode: res.statusCode);
      }
      return ApiResponse.failure('Error: ${res.statusCode}', statusCode: res.statusCode);
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> post(String endpoint,
      {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    try {
      final res = await client.post(
        Uri.parse(ApiConstants.baseUrl + endpoint),
        headers: _defaultHeaders(extra: headers),
        body: body == null ? null : json.encode(body),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final decoded = res.body.isEmpty
            ? <String, dynamic>{}
            : (json.decode(res.body) as Map<String, dynamic>);
        return ApiResponse.success(decoded, statusCode: res.statusCode);
      }
      return ApiResponse.failure('Error: ${res.statusCode}', statusCode: res.statusCode);
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }
}
