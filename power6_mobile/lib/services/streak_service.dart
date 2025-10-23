import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';
import '../services/api_response.dart';

class StreakService {
  final http.Client client;
  final Duration _timeout = const Duration(seconds: 15);

  StreakService({http.Client? httpClient}) : client = httpClient ?? http.Client();

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      throw StateError('No token found');
    }
    return <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Uri _uri(String path) => Uri.parse(ApiConstants.baseUrl + path);

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is String) {
      final parsed = int.tryParse(v);
      return parsed;
    }
    return null;
  }

  /// GET /users/streak
  Future<ApiResponse<int>> getCurrentStreak() async {
    try {
      final headers = await _authHeaders();
      final res = await client
          .get(_uri(ApiConstants.streak), headers: headers)
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final body = (res.body.isEmpty) ? <String, dynamic>{} : json.decode(res.body) as Map<String, dynamic>;
        final val = _asInt(body['streak']);
        if (val == null) return ApiResponse.failure('Malformed response: missing `streak`');
        return ApiResponse.success(val);
      }

      return ApiResponse.failure('Failed to fetch streak: ${res.statusCode}');
    } on TimeoutException {
      return ApiResponse.failure('Timeout fetching streak');
    } on StateError catch (e) {
      return ApiResponse.failure(e.message);
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  /// POST /users/streak/refresh
  Future<ApiResponse<bool>> refreshStreak() async {
    try {
      final headers = await _authHeaders();
      final res = await client
          .post(_uri(ApiConstants.streakRefresh), headers: headers)
          .timeout(_timeout);

      if (res.statusCode == 200) {
        return ApiResponse.success(true);
      }
      return ApiResponse.failure('Failed to refresh streak: ${res.statusCode}');
    } on TimeoutException {
      return ApiResponse.failure('Timeout refreshing streak');
    } on StateError catch (e) {
      return ApiResponse.failure(e.message);
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }
}
