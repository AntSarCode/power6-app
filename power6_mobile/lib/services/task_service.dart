import '../config/api_constants.dart';
import 'api_service.dart';

class TaskService {
  final ApiService _api = ApiService(ApiConstants.baseUrl, null);

  Future<ApiResponse> createTask({
    required String title,
    String? notes,
    bool streakBound = true,
    int priority = 1,
    String? token,
  }) {
    return _api.post(
      ApiConstants.tasks,
      token: token,
      body: <String, dynamic>{
        'title': title,
        if (notes?.isNotEmpty == true) 'notes': notes,
        'streak_bound': streakBound,
        'priority': priority,
      },
    );
  }

  Future<ApiResponse> listTasks({
    required String fromYmd,
    required String toYmd,
    String? token,
  }) {
    return _api.get(
      ApiConstants.tasks,
      token: token,
      query: <String, dynamic>{'from': fromYmd, 'to': toYmd},
    );
  }

  Future<ApiResponse> patchReviewed(int id, String reviewedAtIsoUtc, {String? token}) {
    return _api.patch(
      ApiConstants.taskById(id.toString()),
      token: token,
      body: <String, dynamic>{'reviewed_at': reviewedAtIsoUtc},
    );
  }

  Future<ApiResponse> toggleComplete(int id, bool completed, {String? completedAtIsoUtc, String? token}) {
    return _api.patch(
      ApiConstants.taskById(id.toString()),
      token: token,
      body: <String, dynamic>{
        'completed': completed,
        if (completedAtIsoUtc != null) 'completed_at': completedAtIsoUtc,
      },
    );
  }
}
