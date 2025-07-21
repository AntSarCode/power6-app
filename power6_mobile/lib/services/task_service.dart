import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';
import '../models/task.dart';
import 'api_response.dart';

class TaskService {
  final http.Client client;

  TaskService({http.Client? httpClient}) : client = httpClient ?? http.Client();

  Future<ApiResponse<List<Task>>> fetchTasks(String token) async {
    try {
      final response = await client.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.tasks),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final tasks = data.map((json) => Task.fromJson(json)).toList();
        return ApiResponse(data: tasks);
      } else {
        return ApiResponse(error: 'Failed to fetch tasks: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(error: e.toString());
    }
  }

  Future<ApiResponse<Task>> submitTask(String token, Task task) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.taskSubmit),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(task.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse(data: Task.fromJson(json.decode(response.body)));
      } else {
        return ApiResponse(error: 'Failed to submit task: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(error: e.toString());
    }
  }
}
