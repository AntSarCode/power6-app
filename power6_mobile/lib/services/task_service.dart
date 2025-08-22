import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
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

  static Future<Task> addTask(Task task) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tasks}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(task.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = json.decode(response.body);
      return Task.fromJson(data);
    } else {
      throw Exception('Failed to save task: ${response.body}');
    }
  }
}
