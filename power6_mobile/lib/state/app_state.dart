import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:power6_mobile/models/task.dart';
import 'package:power6_mobile/models/user.dart';

/// Streak threshold (how many completed tasks earn a day of streak credit)
const int kStreakThreshold = 6;

/// Lightweight adapter. Implementations handle actual backend calls.
abstract class BackendAdapter {
  Future<List<Task>?> fetchTodayTasks(String token);
  Future<bool> updateTaskStatus(String token, String taskId, bool completed);
  Future<int?> getCurrentStreak();
  Future<bool> refreshStreak();
}

/// No-op defaults to keep the app compiling even if services are broken.
class _NoopBackendAdapter implements BackendAdapter {
  @override
  Future<List<Task>?> fetchTodayTasks(String token) async => null;

  @override
  Future<bool> updateTaskStatus(String token, String taskId, bool completed) async => true;

  @override
  Future<int?> getCurrentStreak() async => null;

  @override
  Future<bool> refreshStreak() async => true;
}

/// Global application state (tasks, auth, streak)
class AppState extends ChangeNotifier {
  // ---------------- Fields ----------------
  static const String _storageKey = 'tasks';

  final BackendAdapter _backend;
  final List<Task> _tasks = <Task>[];

  String? _authToken;
  User? _user;
  int currentStreak = 0;

  final String? apiBaseUrl;

  // ---------------- Ctors -----------------
  AppState({this.apiBaseUrl, BackendAdapter? backend}) : _backend = backend ?? _NoopBackendAdapter() {
    _loadTasks();
  }

  // ---------------- Getters --------------
  List<Task> get tasks => List.unmodifiable(_tasks);
  String? get accessToken => _authToken;
  User? get user => _user;

  int get completedCountToday {
    final todayKey = _yyyyMmDd(DateTime.now());
    return _tasks.where((t) => t.dayKey == todayKey && t.completed && t.streakBound).length;
  }

  bool get todayEarnedStreak => completedCountToday >= kStreakThreshold;

  get todayCompleted => null;

  // ---------------- Auth ------------------
  void setAuthToken(String token, {User? user}) {
    _authToken = token;
    _user = user;
    syncTasks();
    // After tasks sync completes, we'll recompute locally and also try server.
    loadStreak();
    notifyListeners();
  }

  void logout() {
    _authToken = null;
    _user = null;
    _tasks.clear();
    currentStreak = 0;
    notifyListeners();
  }

  // ---------------- Streak (Fix B) ----------------
  /// Derive a map of day_key -> earned(bool) based on locally cached tasks.
  Map<String, bool> _earnedByDayFromTasks() {
    final Map<String, int> counts = {};
    for (final t in _tasks) {
      if (!t.completed || !t.streakBound) continue;
      counts.update(t.dayKey, (v) => v + 1, ifAbsent: () => 1);
    }
    return counts.map((k, v) => MapEntry(k, v >= kStreakThreshold));
  }

  /// Compute current streak by walking back from today while each day earned streak credit.
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

  /// Recalc streak from local tasks and update state immediately.
  void recalcStreakLocal({bool notify = true}) {
    final s = _computeCurrentStreakLocal();
    if (s != currentStreak) {
      currentStreak = s;
      if (notify) notifyListeners();
    } else if (notify) {
      notifyListeners();
    }
  }

  void setCurrentStreak(int value) {
    if (currentStreak == value) return;
    currentStreak = value;
    notifyListeners();
  }

  Future<void> refreshAndLoadStreak() async {
    if (_authToken == null) return;
    await _backend.refreshStreak();
    await loadStreak();
  }

  /// Try to load streak from backend; fall back to local computation.
  Future<void> loadStreak() async {
    if (_authToken == null) return;
    try {
      final server = await _backend.getCurrentStreak();
      if (server != null) {
        setCurrentStreak(server);
        return;
      }
    } catch (_) {
      // ignore and fall back to local
    }
    recalcStreakLocal();
  }

  // ---------------- Tasks -----------------
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final taskList = prefs.getString(_storageKey);

    _tasks.clear();
    if (taskList != null) {
      final List<dynamic> jsonList = jsonDecode(taskList) as List<dynamic>;
      _tasks.addAll(jsonList
          .cast<Map<String, dynamic>>()
          .map((item) => Task.fromJson(item)));
    }
    recalcStreakLocal(notify: false);
    notifyListeners();
  }

  Future<void> syncTasks() async {
    final token = _authToken;
    if (token == null) return;
    try {
      final serverTasks = await _backend.fetchTodayTasks(token);
      if (serverTasks != null) {
        _tasks
          ..clear()
          ..addAll(serverTasks);
        await _persist();
        recalcStreakLocal();
      }
    } catch (_) {
      // keep local cache, still recompute from what we have
      recalcStreakLocal();
    }
  }

  Future<void> toggleTaskCompletion(int index, {required bool force}) async {
    final token = _authToken;
    if (token == null) return;
    if (index < 0 || index >= _tasks.length) return;

    final Task original = _tasks[index];
    final Task updated = original.copyWith(
      completed: !original.completed,
      completedAtUtc: original.completed ? null : DateTime.now().toUtc(),
      // Keep dayKey stable; it is derived at creation time from createdAtUtc.
    );

    _tasks[index] = updated;
    recalcStreakLocal();

    final ok = await _backend.updateTaskStatus(token, original.id.toString(), updated.completed);
    if (!ok) {
      _tasks[index] = original;
      recalcStreakLocal();
    } else {
      await _persist();
      // Optionally check server’s streak calculation; if unavailable, local stands.
      await loadStreak();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _tasks.map((t) => t.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }
}

// ---------------- Utilities ----------------
DateTime _truncateToLocalDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

String _yyyyMmDd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';