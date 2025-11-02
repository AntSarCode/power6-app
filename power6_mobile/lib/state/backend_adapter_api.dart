import 'package:power6_mobile/services/api_service.dart';
import 'package:power6_mobile/config/api_constants.dart';
import 'package:power6_mobile/state/app_state.dart';
import 'package:power6_mobile/models/task.dart';

class ApiBackendAdapter implements BackendAdapter {
  final ApiService _api = ApiService(ApiConstants.baseUrl, null);

  @override
  Future<List<Task>?> fetchTodayTasks(String token) async {
    final res = await _api.get(ApiConstants.normalize('/tasks/today'), token: token);
    if (!res.isSuccess || res.data == null) return <Task>[];
    final list = (res.data!['items'] ?? res.data!['data'] ?? res.data!['results'] ?? res.data) as List<dynamic>;
    return list.map((j) => Task.fromJson(j as Map<String, dynamic>)).toList();
  }

  @override
  Future<bool> updateTaskStatus(String token, String taskId, bool completed) async {
    final res = await _api.patch(ApiConstants.taskById(taskId),
        token: token, body: {'completed': completed});
    return res.isSuccess;
  }

  @override
  Future<int?> getCurrentStreak() async => null; // optional for now

  @override
  Future<bool> refreshStreak() async {
    String? token;
    await _api.post(ApiConstants.streakRefresh, token: token);
    return true;
  }
}
