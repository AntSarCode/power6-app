import 'dart:convert';
import 'package:http/http.dart' as http;
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
        return ApiResponse(data: data['access_token']);
      } else {
        return ApiResponse(error: 'Login failed: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(error: e.toString());
    }
  }

  Future<ApiResponse<User>> getCurrentUser(String token) async {
    try {
      final response = await client.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.currentUser),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse(data: User.fromJson(data));
      } else {
        return ApiResponse(error: 'Failed to fetch user: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(error: e.toString());
    }
  }
}
