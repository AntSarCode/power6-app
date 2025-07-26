import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';
import '../models/user.dart';
import 'api_response.dart';

class AuthService {
  final http.Client client;

  AuthService({http.Client? httpClient}) : client = httpClient ?? http.Client();

  Future<ApiResponse<String>> login(String username, String password) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access_token']);
        await prefs.setString('refresh_token', data['refresh_token']);
        return ApiResponse.success(data['access_token']);
      } else {
        return ApiResponse.failure('Login failed: \${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return ApiResponse.failure('No token found');

      final response = await client.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.currentUser),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = User.fromJson(data);
        await prefs.setBool('is_superuser', user.isSuperuser);
        return ApiResponse.success(user);
      } else {
        return ApiResponse.failure('Failed to fetch user: \${response.statusCode}');
      }
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
}
