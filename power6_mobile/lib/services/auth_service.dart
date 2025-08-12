import 'dart:convert';
import 'package:flutter/foundation.dart';                   // + for kReleaseMode
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';
import '../models/user.dart';
import 'api_response.dart';

class AuthService {
  final http.Client client;

  AuthService({http.Client? httpClient}) : client = httpClient ?? http.Client();

  // Resolve base URL:
  // 1) --dart-define=BASE_URL takes priority
  // 2) Release builds default to your live backend
  // 3) Otherwise use whatever is in ApiConstants.baseUrl (usually localhost for dev)
  String get _baseUrl {
    const env = String.fromEnvironment('BASE_URL', defaultValue: '');
    if (env.isNotEmpty) return env;
    if (kReleaseMode) return 'https://power6-backend.onrender.com'; // <- Render URL
    return ApiConstants.baseUrl;
  }

  // Safe join helper (handles trailing/leading slashes; accepts full URLs too)
  String _join(String base, String endpoint) {
    if (endpoint.startsWith('http')) return endpoint;
    final b = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final e = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$b$e';
  }

  Uri _u(String endpoint) => Uri.parse(_join(_baseUrl, endpoint));

  /// Login and persist tokens
  Future<ApiResponse<String>> login(String username, String password) async {
    try {
      final res = await client.post(
        _u(ApiConstants.login), // e.g. '/auth/login'
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final access = (data['access_token'] ?? data['token']) as String?;
        final refresh = data['refresh_token'] as String?;
        if (access == null) {
          return ApiResponse.failure('No access token returned from server.');
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', access);
        if (refresh != null) {
          await prefs.setString('refresh_token', refresh);
        } else {
          await prefs.remove('refresh_token');
        }
        return ApiResponse.success(access);
      }

      // Try to surface server error detail
      String msg = 'Login failed: ${res.statusCode}';
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['detail'] != null) msg = body['detail'].toString();
        if (body is Map && body['message'] != null) msg = body['message'].toString();
      } catch (_) {}
      return ApiResponse.failure(msg);
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  /// Register + auto-login (stores token like login)
  Future<ApiResponse<String>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final res = await client.post(
        _u(ApiConstants.register), // e.g. '/auth/register'
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final access = (data['access_token'] ?? data['token']) as String?;
        if (access == null) {
          return ApiResponse.failure('No access token returned from server.');
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', access);
        final refresh = data['refresh_token'] as String?;
        if (refresh != null) {
          await prefs.setString('refresh_token', refresh);
        } else {
          await prefs.remove('refresh_token');
        }
        return ApiResponse.success(access);
      }

      String msg = 'Sign-up failed: ${res.statusCode}';
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['detail'] != null) msg = body['detail'].toString();
        if (body is Map && body['message'] != null) msg = body['message'].toString();
      } catch (_) {}
      return ApiResponse.failure(msg);
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  /// Fetch the current user
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return ApiResponse.failure('No token found');

      final res = await client.get(
        _u(ApiConstants.currentUser), // e.g. '/users/me'
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        final user = User.fromJson(data);
        await prefs.setBool('is_superuser', user.isSuperuser);
        return ApiResponse.success(user);
      }

      String msg = 'Failed to fetch user: ${res.statusCode}';
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['detail'] != null) msg = body['detail'].toString();
      } catch (_) {}
      return ApiResponse.failure(msg);
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('is_superuser');
  }

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return token != null;
  }

  Future<bool> isSuperuser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_superuser') ?? false;
  }

  /// Static helper to retrieve token for authorized API calls
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
}
