// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/streak_service.dart';
import 'package:power6_mobile/services/task_service.dart';
import '../state/app_state.dart';

class TaskReviewScreen extends StatefulWidget {
  const TaskReviewScreen({super.key});

  @override
  State<TaskReviewScreen> createState() => _TaskReviewScreenState();
}

class _TaskReviewScreenState extends State<TaskReviewScreen> {
  Future<List<Task>> _todayTasks = Future.value(<Task>[]);
  String? _softError;

  // ADDED: cache for latest tasks to compute threshold flips
  List<Task> _latestTasks = <Task>[];
  final StreakService _streakService = StreakService();
  final TaskService _taskService = TaskService();
  final int _streakThreshold = 6;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _softError = null);
    final token = context.read<AppState>().accessToken ?? '';

    if (token.isEmpty) {
      setState(() {
        _todayTasks = Future.value(<Task>[]);
        _latestTasks = <Task>[];
        _softError = 'You are not signed in.';
      });
      return;
    }

    final response = await _taskService.fetchTodayTasks();
    if (!mounted) return;

    if (response.isSuccess && response.data != null) {
      final items = response.data ?? <Task>[];
      final today = DateTime.now();
      final filtered = items.where((t) {
        final sf = t.scheduledFor;
        final isToday = sf != null && _isSameDay(sf, today);
        return !t.completed || isToday;
      }).toList();
      setState(() {
        _todayTasks = Future.value(filtered);
        _latestTasks = filtered;
      });
    } else {
      final err = (response.error ?? '').toLowerCase();
      if (err.contains('no tasks') || err.contains('not found') || err.contains('404')) {
        setState(() {
          _todayTasks = Future.value(<Task>[]);
          _latestTasks = <Task>[];
        });
      } else {
        setState(() {
          _softError = response.error ?? 'Failed to fetch tasks';
          _todayTasks = Future.value(<Task>[]);
          _latestTasks = <Task>[];
        });
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  int _eligibleCompletedCount(List<Task> items) {
    if (items.isEmpty) return 0;
    final now = DateTime.now();
    int count = 0;
    for (final t in items) {
      final completed = t.completed == true;
      final eligible = (t.streakBound == true);
      final ca = t.completedAt;
      if (completed && eligible && ca != null && _isSameDay(ca, now)) {
        count++;
      }
    }
    return count;
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final token = context.read<AppState>().accessToken ?? '';
    if (token.isEmpty) return;

    final prevEligible = _eligibleCompletedCount(_latestTasks);
    final wasMet = prevEligible >= _streakThreshold;

    int delta = 0;
    if (task.streakBound == true) {
      delta = task.completed ? -1 : 1;
    }
    final afterEligible = prevEligible + delta;
    final isMet = afterEligible >= _streakThreshold;

    await _taskService.updateTaskStatus(task.id.toString(), !task.completed);
    await _loadTasks();

    if (!wasMet && isMet && mounted) {
      try {
        final refresh = await _streakService.refreshStreak();
        if (refresh.isSuccess) {
          final current = await _streakService.getCurrentStreak();
          if (current.isSuccess && current.data != null) {
            await context.read<AppState>().loadStreak();
          }
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI code remains unchanged
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Review Tasks'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadTasks(),
          ),
        ],
      ),
      body: FutureBuilder<List<Task>>(
        future: _todayTasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.hasData ? snapshot.data! : _latestTasks;
          if (items.isEmpty) {
            return Center(
              child: Text(_softError ?? 'No tasks for today'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 96, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final task = items[index];
              return ListTile(
                title: Text('${task.title}'),                trailing: Checkbox(
                  value: task.completed,
                  onChanged: (_) => _toggleTaskCompletion(task),
                ),
                onTap: () => _toggleTaskCompletion(task),
              );
            },
          );
        },
      ),
    );
  }
}
