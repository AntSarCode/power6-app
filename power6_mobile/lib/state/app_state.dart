import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';
import '../models/user.dart';
import '../services/task_service.dart';
import '../services/streak_service.dart';

class AppState extends ChangeNotifier {
  final String _storageKey = 'tasks';
  List<Task> _tasks = [];
  String? _authToken;
  User? _user;
  int currentStreak = 0;

  AppState() {
    _loadTasks();
    loadStreak();
  }

  List<Task> get tasks => _tasks;
  String? get accessToken => _authToken;
  User? get user => _user;
  int get completedCount => _tasks.where((task) => task.completed).length;
  bool get todayCompleted => completedCount >= 6;

  void setAuthToken(String token, {User? user}) {
    _authToken = token;
    _user = user;
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
      }
    } catch (_) {}
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
    _user = null;
    notifyListeners();
  }

  List<Task> _defaultTasks() => [];
}
