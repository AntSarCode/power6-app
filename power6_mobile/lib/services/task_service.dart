import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';
import '../models/task.dart';
import 'api_response.dart';

class TaskService {
  static Future<ApiResponse<List<Task>>> fetchTodayTasks(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.tasks + '/today'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final tasks = data.map((json) => Task.fromJson(json)).toList().cast<Task>();
        return ApiResponse.success(tasks);
      } else {
        return ApiResponse.failure('Failed to fetch today tasks');
      }
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  static Future<ApiResponse<List<Task>>> fetchCompletedHistory(String token, {DateTime? from, DateTime? to}) async {
    try {
      final query = StringBuffer('?');
      if (from != null) query.write('from_date=${from.toIso8601String()}&');
      if (to != null) query.write('to_date=${to.toIso8601String()}');
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.tasks + '/history${query.toString()}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final tasks = data.map((json) => Task.fromJson(json)).toList().cast<Task>();
        return ApiResponse.success(tasks);
      } else {
        return ApiResponse.failure('Failed to fetch history');
      }
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  static Future<ApiResponse<Task>> saveTask(Task task, String token) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.tasks),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(task.toJson(forCreate: true)),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(Task.fromJson(data));
      } else {
        return ApiResponse.failure('Failed to create task');
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
}
