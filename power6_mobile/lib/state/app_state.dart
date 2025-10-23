// lib/state/app_state.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:power6_mobile/models/task.dart';
import 'package:power6_mobile/models/user.dart';

/// Lightweight adapter so AppState doesn't hard-depend on networking files.
/// Inject a real implementation from your services layer in main.dart.
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

  // ---------------- Ctors -----------------
  AppState({BackendAdapter? backend, required String apiBaseUrl}) : _backend = backend ?? _NoopBackendAdapter() {
    _loadTasks();
  }

  // ---------------- Getters --------------
  List<Task> get tasks => List.unmodifiable(_tasks);
  String? get accessToken => _authToken;
  User? get user => _user;

  int get completedCount => _tasks.where((t) => t.completed).length;
  bool get todayCompleted => completedCount >= 6;

  get apiBaseUrl => null;

  // ---------------- Auth ------------------
  void setAuthToken(String token, {User? user}) {
    _authToken = token;
    _user = user;
    syncTasks();
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

  // ---------------- Streak ----------------
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

  Future<void> loadStreak() async {
    if (_authToken == null) return;
    final value = await _backend.getCurrentStreak();
    if (value != null) {
      currentStreak = value;
      notifyListeners();
    }
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
    // No defaults to avoid accidental test data; keep empty on first run.
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
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> toggleTaskCompletion(int index) async {
    final token = _authToken;
    if (token == null) return;
    if (index < 0 || index >= _tasks.length) return;

    final Task original = _tasks[index];
    final Task updated = original.copyWith(
      completed: !original.completed,
      completedAt: original.completed ? null : DateTime.now(),
    );

    _tasks[index] = updated;
    notifyListeners();

    final ok = await _backend.updateTaskStatus(token, original.id as String, updated.completed);
    if (!ok) {
      _tasks[index] = original;
      notifyListeners();
    } else {
      await _persist();
      await loadStreak();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _tasks.map((t) => t.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }
}
