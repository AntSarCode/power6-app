import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/streak_service.dart';

class AppState extends ChangeNotifier {
  final String _storageKey = 'tasks';
  List<Task> _tasks = [];
  String? _authToken;
  int currentStreak = 0;
  String? username;

  AppState() {
    _loadTasks();
    loadStreak();
  }

  List<Task> get tasks => _tasks;
  String? get accessToken => _authToken;
  int get completedCount => _tasks.where((task) => task.completed).length;
  bool get todayCompleted => completedCount >= 6;

  void setAuthToken(String token, {String? user}) {
    _authToken = token;
    username = user;
    syncTasks(token);
    loadStreak();
    notifyListeners();
  }

  void toggleTaskCompletion(int index) async {
    final token = _authToken;
    if (token == null) return;

    final task = _tasks[index];
    final updated = task.copyWith(
      completed: !task.completed,
      completedAt: task.completed ? null : DateTime.now(),
    );

    _tasks[index] = updated;
    notifyListeners();

    final response = await TaskService.updateTaskStatus(token, task.id, updated.completed);
    if (response.error != null) {
      _tasks[index] = task;
      notifyListeners();
      debugPrint("Task status update failed: \${response.error}");
    }

    await _persist();
    loadStreak();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final taskList = prefs.getString(_storageKey);

    if (taskList != null) {
      final List<dynamic> jsonList = jsonDecode(taskList);
      _tasks = jsonList.map((item) => Task.fromJson(item)).toList();
    } else {
      _tasks = _defaultTasks();
      await _persist();
    }

    notifyListeners();
  }

  Future<void> syncTasks(String token) async {
    try {
      final response = await TaskService.fetchTodayTasks(token);
      if (response.isSuccess && response.data != null) {
        _tasks = response.data!;
        await _persist();
        notifyListeners();
      } else {
        debugPrint('Sync failed: \${response.error}');
      }
    } catch (e) {
      print('Task sync failed: \$e');
    }
  }

  Future<void> loadStreak() async {
    final token = _authToken;
    if (token == null) return;

    final response = await StreakService().getCurrentStreak();
    if (response.isSuccess && response.data != null) {
      currentStreak = response.data!;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _tasks.map((t) => t.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  void logout() {
    _authToken = null;
    _tasks = [];
    currentStreak = 0;
    username = null;
    notifyListeners();
  }

  List<Task> _defaultTasks() => [
        Task(
          id: 1,
          userId: 1,
          title: "Complete Power6 Layout",
          notes: "Verify all modules show something on screen",
          priority: 1,
          completed: false,
          scheduledFor: DateTime.now(),
          completedAt: null,
          streakBound: true,
        ),
        Task(
          id: 2,
          userId: 1,
          title: "Celebrate Progress",
          notes: "You've scaffolded the entire frontend!",
          priority: 2,
          completed: true,
          scheduledFor: DateTime.now(),
          completedAt: DateTime.now(),
          streakBound: false,
        ),
      ];
}
