import 'package:power6_mobile/services/api_service.dart';
import 'package:power6_mobile/config/api_constants.dart';
import 'package:power6_mobile/state/app_state.dart';
import 'package:power6_mobile/models/task.dart';

class ApiBackendAdapter implements BackendAdapter {
  final ApiService _api = ApiService(ApiConstants.baseUrl, null);

  @override
  Future<List<Task>?> fetchactiveTasks(String token) async {
    final res = await _api.get(
      ApiConstants.normalize('/tasks/active'),
      token: token,
    );

    if (!res.isSuccess || res.data == null) return <Task>[];

    final raw = res.data!;
    final list = raw is List
        ? raw
        : (raw['items'] ?? raw['data'] ?? raw['results'] ?? <dynamic>[]);

    return list
        .map((j) => Task.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<bool> updateTaskStatus(String token, String taskId, bool completed) async {
    final res = await _api.patch(
      ApiConstants.taskById(taskId),
      token: token,
      body: {'completed': completed},
    );
    return res.isSuccess;
  }

  @override
  Future<int?> getCurrentStreak() async => null;

  @override
  Future<bool> refreshStreak() async {
    await _api.post(ApiConstants.streakRefresh);
    return true;
  }
}