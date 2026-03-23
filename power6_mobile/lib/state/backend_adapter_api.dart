// backend_adapter_api

import 'package:flutter/foundation.dart';
import 'package:power6_mobile/config/api_constants.dart';
import 'package:power6_mobile/models/task.dart';
import 'package:power6_mobile/services/api_service.dart';
import 'package:power6_mobile/state/app_state.dart';

class ApiBackendAdapter implements BackendAdapter {
  final ApiService _api = ApiService(ApiConstants.baseUrl, null);

  @override
  Future<List<Task>?> fetchactiveTasks(String token) async {
    final res = await _api.get(
      ApiConstants.normalize('/tasks/active'),
      token: token,
    );

    if (!res.isSuccess || res.data == null) {
      return <Task>[];
    }

    final raw = res.data!;
    final dynamic items = raw['items'] ?? raw['data'] ?? raw['results'] ?? raw;
    final List<dynamic> list = items is List ? items : <dynamic>[];

    return list
        .whereType<Map<String, dynamic>>()
        .map(Task.fromJson)
        .toList();
  }

  @override
  Future<bool> updateTaskStatus(String token, String taskId, bool completed) async {
    debugPrint('[API] PATCH /tasks/$taskId -> completed=$completed');

    final res = await _api.patch(
      ApiConstants.taskById(taskId),
      token: token,
      body: <String, dynamic>{'completed': completed},
    );

    debugPrint('[API] PATCH result -> success=${res.isSuccess}, error=${res.error}, data=${res.data}');
    return res.isSuccess;
  }

  @override
  Future<int?> getCurrentStreak(String token) async {
    final res = await _api.get(ApiConstants.streak, token: token);
    if (!res.isSuccess || res.data == null) return null;

    final raw = res.data!;
    final dynamic streakValue = raw['streak_count'] ?? raw['streak'] ?? raw['current_streak'] ?? raw['count'];
    if (streakValue is int) return streakValue;
    if (streakValue is String) return int.tryParse(streakValue);
    return null;
  }

  @override
  Future<bool> refreshStreak(String token) async {
    final res = await _api.post(ApiConstants.streakRefresh, token: token);
    return res.isSuccess;
  }
}
