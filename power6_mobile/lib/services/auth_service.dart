import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';
import '../models/user.dart';
import 'api_service.dart';

/// AuthService aligned with ApiService & ApiConstants
/// - Single source of truth for base URL: ApiConstants.baseUrl
/// - Returns ApiResponse from api_service.dart (non-generic)
class AuthService {
  final http.Client client;

  AuthService({http.Client? httpClient}) : client = httpClient ?? http.Client();

  String get _baseUrl {
    final base = (ApiConstants.baseUrl).trim();
    if (base.isEmpty) {
      throw StateError(
        'API base URL is missing. Provide --dart-define=API_BASE_URL or set a default in ApiConstants.',
      );
    }
    return base;
  }

  Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  String _join(String base, String endpoint) {
    if (endpoint.startsWith('http')) return endpoint;
    final b = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final e = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$b$e';
  }

  Uri _u(String endpoint) => Uri.parse(_join(_baseUrl, endpoint));

  Future<ApiResponse> login(String usernameOrEmail, String password) async {
    try {
      final res = await client.post(
        _u(ApiConstants.login),
        headers: _headers(),
        body: jsonEncode({
          'username_or_email': usernameOrEmail.trim(),
          'password': password,
        }),
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
        return ApiResponse.success(<String, dynamic>{
          'access_token': access,
          if (refresh != null) 'refresh_token': refresh,
        });
      }

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

  Future<ApiResponse> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final res = await client.post(
        _u(ApiConstants.register),
        headers: _headers(),
        body: jsonEncode({
          'username': username.trim(),
          'email': email.trim(),
          'password': password,
        }),
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
        return ApiResponse.success(<String, dynamic>{
          'access_token': access,
          if (refresh != null) 'refresh_token': refresh,
        });
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

  Future<ApiResponse> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return ApiResponse.failure('No token found');

      // Prefer a constant endpoint; keep fallback if constant not available
      final meEndpoint = ApiConstants.me;

      final res = await client.get(
        _u(meEndpoint),
        headers: _headers(token: token),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        final user = User.fromJson(data);
        await prefs.setBool('is_admin', user.isAdmin);
        await prefs.setBool('is_superuser', user.isAdmin);
        return ApiResponse.success(<String, dynamic>{'user': user.toJson()});
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
    await prefs.remove('is_admin');
  }

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return token != null;
  }

  Future<bool> isSuperuser() async {
    final prefs = await SharedPreferences.getInstance();
    final adminFlag = prefs.getBool('is_admin');
    if (adminFlag != null) return adminFlag;
    return prefs.getBool('is_superuser') ?? false;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
}
