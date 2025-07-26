import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';
import '../services/api_response.dart';

class StreakService {
  final http.Client client;

  StreakService({http.Client? httpClient}) : client = httpClient ?? http.Client();

  Future<ApiResponse<int>> getCurrentStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return ApiResponse.failure('No token found');

      final response = await client.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.streak),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['streak']);
      } else {
        return ApiResponse.failure('Failed to fetch streak: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  Future<ApiResponse<bool>> refreshStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return ApiResponse.failure('No token found');

      final response = await client.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.streakRefresh),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.failure('Failed to refresh streak: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }
}
