import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';
import '../services/api_response.dart';

class ApiService {
  final http.Client client;

  ApiService({http.Client? httpClient}) : client = httpClient ?? http.Client();

  Future<ApiResponse<Map<String, dynamic>>> get(String endpoint) async {
    try {
      final response = await client.get(Uri.parse(ApiConstants.baseUrl + endpoint));
      if (response.statusCode == 200) {
        return ApiResponse(data: json.decode(response.body));
      } else {
        return ApiResponse(error: 'Error: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(error: e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConstants.baseUrl + endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(data: json.decode(response.body));
      } else {
        return ApiResponse(error: 'Error: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(error: e.toString());
    }
  }
}
