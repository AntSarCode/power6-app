// app_state.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:power6_mobile/models/task.dart';
import 'package:power6_mobile/models/user.dart';

const int kStreakThreshold = 6;

abstract class BackendAdapter {
  Future<List<Task>?> fetchactiveTasks(String token);
  Future<bool> updateTaskStatus(String token, String taskId, bool completed);
  Future<int?> getCurrentStreak(String token);
  Future<bool> refreshStreak(String token);
}

class _NoopBackendAdapter implements BackendAdapter {
  @override
  Future<List<Task>?> fetchactiveTasks(String token) async => null;

  @override
  Future<bool> updateTaskStatus(String token, String taskId, bool completed) async => true;

  @override
  Future<int?> getCurrentStreak(String token) async => null;

  @override
  Future<bool> refreshStreak(String token) async => true;
}

class AppState extends ChangeNotifier {
  static const String _storageKey = 'tasks';

  final BackendAdapter _backend;
  final List<Task> _tasks = <Task>[];

  String? _authToken;
  User? _user;
  int currentStreak = 0;

  final String? apiBaseUrl;

  AppState({this.apiBaseUrl, BackendAdapter? backend})
      : _backend = backend ?? _NoopBackendAdapter() {
    _loadTasks();
  }

  List<Task> get tasks => List.unmodifiable(_tasks);
  String? get accessToken => _authToken;
  User? get user => _user;

  String get _todayKey => _yyyyMmDd(DateTime.now());

  String _taskLocalDayKey(Task task) => task.localDayKey;

  List<Task> get todayTasks {
    final key = _todayKey;
    final items = _tasks.where((t) => _taskLocalDayKey(t) == key).toList()
      ..sort((a, b) {
        if (a.completed != b.completed) return a.completed ? 1 : -1;
        return a.createdAtUtc.compareTo(b.createdAtUtc);
      });
    return List.unmodifiable(items);
  }

  List<Task> get todayCreatedTasks => List.unmodifiable(todayTasks);

  List<Task> get todayActiveTasks =>
      List.unmodifiable(todayTasks.where((t) => !t.completed).toList());

  List<Task> get todayCompletedTasks =>
      List.unmodifiable(todayTasks.where((t) => t.completed).toList());

  List<Task> get reviewTasks {
    final items = _tasks.where((t) {
      if (!t.completed) return true;
      return _taskLocalDayKey(t) == _todayKey;
    }).toList()
      ..sort((a, b) {
        final aOpen = !a.completed;
        final bOpen = !b.completed;
        if (aOpen != bOpen) return aOpen ? -1 : 1;

        final aKey = _taskLocalDayKey(a);
        final bKey = _taskLocalDayKey(b);
        if (aKey != bKey) return aKey.compareTo(bKey);

        return a.createdAtUtc.compareTo(b.createdAtUtc);
      });
    return List.unmodifiable(items);
  }

  List<Task> get openReviewTasks =>
      List.unmodifiable(reviewTasks.where((t) => !t.completed).toList());

  List<Task> get completedReviewTasks =>
      List.unmodifiable(reviewTasks.where((t) => t.completed).toList());

  List<Task> get todayCompletedStreakTasks => List.unmodifiable(
        todayTasks.where((t) => t.completed && t.streakBound).toList(),
      );

  int get todayTaskCount => todayTasks.length;
  int get todayCreatedCount => todayCreatedTasks.length;
  int get todayActiveCount => todayActiveTasks.length;
  int get todayCompletedCount => todayCompletedTasks.length;
  int get reviewTaskCount => reviewTasks.length;
  int get openReviewTaskCount => openReviewTasks.length;
  int get completedCountToday => todayCompletedStreakTasks.length;
  bool get todayEarnedStreak => completedCountToday >= kStreakThreshold;
  bool get todayCompleted => todayCompletedCount > 0;
  double get todayProgressPercent =>
      todayTaskCount == 0 ? 0 : (todayCompletedCount / todayTaskCount).clamp(0, 1).toDouble();

  Future<void> setAuthToken(String token, {User? user}) async {
    _authToken = token;
    _user = user;
    notifyListeners();
    await syncTasks();
    await loadStreak();
  }

  Future<void> logout() async {
    _authToken = null;
    _user = null;
    _tasks.clear();
    currentStreak = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }

  Map<String, bool> _earnedByDayFromTasks() {
    final Map<String, int> counts = <String, int>{};
    for (final t in _tasks) {
      if (!t.completed || !t.streakBound) continue;
      counts.update(_taskLocalDayKey(t), (v) => v + 1, ifAbsent: () => 1);
    }
    return counts.map((k, v) => MapEntry(k, v >= kStreakThreshold));
  }

  int _computeCurrentStreakLocal({DateTime? now}) {
    final earned = _earnedByDayFromTasks();
    DateTime cursor = _truncateToLocalDay(now ?? DateTime.now());
    int streak = 0;
    while (true) {
      final key = _yyyyMmDd(cursor);
      final ok = earned[key] ?? false;
      if (!ok) break;
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  void recalcStreakLocal({bool notify = true}) {
    final s = _computeCurrentStreakLocal();
    if (s != currentStreak) {
      currentStreak = s;
    }
    if (notify) notifyListeners();
  }

  void setCurrentStreak(int value) {
    if (currentStreak == value) return;
    currentStreak = value;
    notifyListeners();
  }

  Future<void> refreshAndLoadStreak() async {
    final token = _authToken;
    if (token == null || token.isEmpty) return;
    await _backend.refreshStreak(token);
    await loadStreak();
  }

  Future<void> loadStreak() async {
    final token = _authToken;
    if (token == null || token.isEmpty) return;
    try {
      final server = await _backend.getCurrentStreak(token);
      if (server != null) {
        setCurrentStreak(server);
        return;
      }
    } catch (_) {}
    recalcStreakLocal();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final taskList = prefs.getString(_storageKey);

    _tasks.clear();
    if (taskList != null && taskList.isNotEmpty) {
      final List<dynamic> jsonList = jsonDecode(taskList) as List<dynamic>;
      _tasks.addAll(
        jsonList
            .whereType<Map<String, dynamic>>()
            .map(Task.fromJson)
            .map((task) => task.normalizeLocalDayKey()),
      );
    }
    recalcStreakLocal(notify: false);
    notifyListeners();
  }

  Future<void> syncTasks() async {
    final token = _authToken;
    if (token == null || token.isEmpty) return;
    try {
      final serverTasks = await _backend.fetchactiveTasks(token);
      if (serverTasks != null) {
        _mergeServerTasks(
          serverTasks.map((task) => task.normalizeLocalDayKey()).toList(),
        );
        await _persist();
      }
      recalcStreakLocal();
    } catch (_) {
      recalcStreakLocal();
    }
  }

  void _mergeServerTasks(List<Task> serverTasks) {
    final Map<int, Task> merged = <int, Task>{
      for (final task in serverTasks) task.id: task,
    };

    for (final local in _tasks) {
      final keepLocalCompleted = local.completed && _isToday(local);
      final keepReviewedTask = local.reviewedAtUtc != null && _isToday(local);
      if ((keepLocalCompleted || keepReviewedTask) && !merged.containsKey(local.id)) {
        merged[local.id] = local;
      }
    }

    final List<Task> next = merged.values.toList()
      ..sort((a, b) {
        final aKey = _taskLocalDayKey(a);
        final bKey = _taskLocalDayKey(b);
        if (aKey != bKey) return aKey.compareTo(bKey);
        if (a.completed != b.completed) return a.completed ? 1 : -1;
        return a.createdAtUtc.compareTo(b.createdAtUtc);
      });

    _tasks
      ..clear()
      ..addAll(next);
  }

  bool _isToday(Task task) => _taskLocalDayKey(task) == _todayKey;

  Future<void> toggleTaskCompletion(int index, {required bool force}) async {
    final token = _authToken;
    if (token == null || token.isEmpty) {
      debugPrint('[APPSTATE] toggle abort: no token');
      return;
    }
    if (index < 0 || index >= _tasks.length) {
      debugPrint('[APPSTATE] toggle abort: bad index $index');
      return;
    }

    final Task original = _tasks[index];
    final bool newCompletedState = force;
    if (original.completed == newCompletedState) {
      return;
    }

    final Task updated = original.copyWith(
      completed: newCompletedState,
      completedAtUtc: newCompletedState ? DateTime.now().toUtc() : null,
      clearCompletedAtUtc: !newCompletedState,
    );

    _tasks[index] = updated;
    recalcStreakLocal();
    notifyListeners();

    final ok = await _backend.updateTaskStatus(
      token,
      original.id.toString(),
      newCompletedState,
    );

    if (!ok) {
      _tasks[index] = original;
      recalcStreakLocal();
      notifyListeners();
      return;
    }

    await _persist();
    await syncTasks();
    await loadStreak();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _tasks.map((t) => t.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }
}

DateTime _truncateToLocalDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

String _yyyyMmDd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
