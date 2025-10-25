// lib/services/task_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';
import '../services/api_response.dart';
import '../models/task.dart';

class TaskService {
  final http.Client client;
  final Duration _timeout = const Duration(seconds: 20);

  TaskService({http.Client? httpClient}) : client = httpClient ?? http.Client();

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      throw StateError('No token found');
    }
    return <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Uri _uri(String path) => Uri.parse(ApiConstants.baseUrl + path);

  // GET /tasks/review  -> today’s tasks for the review screen
  Future<ApiResponse<List<Task>>> fetchTodayTasks() async {
    try {
      final headers = await _authHeaders();
      final res = await client
          .get(_uri(ApiConstants.taskReview), headers: headers)
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final body = (res.body.isEmpty) ? <dynamic>[] : json.decode(res.body) as List<dynamic>;
        final tasks = body
            .cast<Map<String, dynamic>>()
            .map((j) => Task.fromJson(j))
            .toList();
        return ApiResponse.success(tasks);
      }
      return ApiResponse.failure('Failed to fetch tasks: ${res.statusCode}');
    } on TimeoutException {
      return ApiResponse.failure('Timeout fetching tasks');
    } on StateError catch (e) {
      return ApiResponse.failure(e.message);
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  // PATCH /tasks/{id} { completed: bool }
  Future<ApiResponse<bool>> updateTaskStatus(String taskId, bool completed) async {
    try {
      final headers = await _authHeaders();
      final res = await client
          .patch(
            _uri('${ApiConstants.tasks}/$taskId'),
            headers: headers,
            body: jsonEncode(<String, dynamic>{'completed': completed}),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        return ApiResponse.success(true);
      }
      return ApiResponse.failure('Failed to update task: ${res.statusCode}');
    } on TimeoutException {
      return ApiResponse.failure('Timeout updating task');
    } on StateError catch (e) {
      return ApiResponse.failure(e.message);
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  // POST /tasks/submit  -> create new task (if you need it from input screen)
  Future<ApiResponse<bool>> createTask(Task task) async {
    try {
      final headers = await _authHeaders();
      final res = await client
          .post(
            _uri(ApiConstants.taskSubmit),
            headers: headers,
            body: jsonEncode(task.toJson()),
          )
          .timeout(_timeout);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return ApiResponse.success(true);
      }
      return ApiResponse.failure('Failed to create task: ${res.statusCode}');
    } on TimeoutException {
      return ApiResponse.failure('Timeout creating task');
    } on StateError catch (e) {
      return ApiResponse.failure(e.message);
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }
}
