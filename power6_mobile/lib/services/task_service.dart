// lib/services/task_service.dart
import '../config/api_constants.dart';
import 'api_service.dart';

class TaskService {
  final _api = ApiService();

  Future<ApiResponse> createTask({
    required String title,
    String? notes,
    bool streakBound = true,
    int priority = 1,
  }) {
    return _api.post(ApiConstants.tasks, body: {
      'title': title,
      if (notes?.isNotEmpty == true) 'notes': notes,
      'streak_bound': streakBound,
      'priority': priority,
      // created_at set server-side (UTC); client can send a hint if desired
    });
  }

  Future<ApiResponse> listTasks({
    required String fromYmd, // 'YYYY-MM-DD' local day window start
    required String toYmd,   // 'YYYY-MM-DD' local day window end
  }) {
    return _api.get(ApiConstants.tasks, query: {'from': fromYmd, 'to': toYmd});
  }

  Future<ApiResponse> patchReviewed(int id, String reviewedAtIsoUtc) {
    return _api.patch(ApiConstants.taskById(id), body: {
      'reviewed_at': reviewedAtIsoUtc,
    });
  }

  Future<ApiResponse> toggleComplete(int id, bool completed, {String? completedAtIsoUtc}) {
    return _api.patch(ApiConstants.taskById(id), body: {
      'completed': completed,
      if (completedAtIsoUtc != null) 'completed_at': completedAtIsoUtc,
    });
  }
}
