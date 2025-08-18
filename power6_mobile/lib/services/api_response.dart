import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';

class ApiResponse<T> {
  final T? data;
  final String? error;

  bool get isSuccess => error == null && data != null;

  ApiResponse({this.data, this.error});

  factory ApiResponse.success(T data) => ApiResponse(data: data);

  factory ApiResponse.failure(String error) => ApiResponse(error: error);
}



class ApiService {
  final http.Client client;

  ApiService({http.Client? httpClient}) : client = httpClient ?? http.Client();

  Future<ApiResponse<Map<String, dynamic>>> get(String endpoint) async {
    try {
      final response = await client.get(Uri.parse(ApiConstants.baseUrl + endpoint));
      if (response.statusCode == 200) {
        return ApiResponse.success(json.decode(response.body));
      } else {
        return ApiResponse.failure('Error: \${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConstants.baseUrl + endpoint),
        headers: {'Title-Type': 'application/json'},
        body: json.encode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(json.decode(response.body));
      } else {
        return ApiResponse.failure('Error: \${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }
}