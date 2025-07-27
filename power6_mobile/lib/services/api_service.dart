import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';
import '../services/api_response.dart';

class ApiService {
  final http.Client client;

  ApiService({http.Client? httpClient}) : client = httpClient ?? http.Client();

  Future<ApiResponse<Map<String, dynamic>>> get(String endpoint,
      {String? token}) async {
    try {
      final response = await client.get(
        Uri.parse(ApiConstants.baseUrl + endpoint),
        headers: {
          'Title-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(json.decode(response.body));
      } else {
        return ApiResponse.failure(
            'Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }


  Future<ApiResponse<Map<String, dynamic>>> post(String endpoint,
      Map<String, dynamic> body, {String? token}) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConstants.baseUrl + endpoint),
        headers: {
          'Title-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(json.decode(response.body));
      } else {
        return ApiResponse.failure(
            'Error: ${response.statusCode} → ${response.body}');
      }
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }
}
