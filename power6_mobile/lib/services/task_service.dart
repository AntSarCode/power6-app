import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';
import '../models/task.dart';
import 'api_response.dart';

class TaskService {
  static Future<ApiResponse<List<Task>>> fetchTodayTasks(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.tasks),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final tasks = data.map((json) => Task.fromJson(json)).toList().cast<Task>();
        return ApiResponse.success(tasks);
      } else {
        return ApiResponse.failure('Failed to fetch tasks');
      }
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  static Future<ApiResponse<bool>> updateTaskStatus(String token, int id, bool completed) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConstants.baseUrl + '${ApiConstants.tasks}/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'completed': completed}),
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.failure('Failed to update task');
      }
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  static Future<ApiResponse<bool>> addTask(Task task) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return ApiResponse.failure('Missing token');

      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.tasks),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(task.toJson()),
      );

      if (response.statusCode == 201) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.failure('Failed to add task');
      }
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }
}
