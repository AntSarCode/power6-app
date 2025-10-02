import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../state/app_state.dart';

class TaskReviewScreen extends StatefulWidget {
  const TaskReviewScreen({super.key});

  @override
  State<TaskReviewScreen> createState() => _TaskReviewScreenState();
}

class _TaskReviewScreenState extends State<TaskReviewScreen> {
  Future<List<Task>> _todayTasks = Future.value(<Task>[]);
  String? _softError;

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
        _softError = 'You are not signed in.';
      });
      return;
    }

    final response = await TaskService.fetchTodayTasks(token);
    if (!mounted) return;

    if (response.isSuccess && response.data != null) {
      final items = response.data ?? <Task>[];
      setState(() => _todayTasks = Future.value(items));
    } else {
      final err = (response.error ?? '').toLowerCase();
      if (err.contains('no tasks') || err.contains('not found') || err.contains('404')) {
        setState(() => _todayTasks = Future.value(<Task>[]));
      } else {
        setState(() {
          _softError = response.error ?? 'Failed to fetch tasks';
          _todayTasks = Future.value(<Task>[]);
        });
      }
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final token = context.read<AppState>().accessToken ?? '';
    if (token.isEmpty) return;
    await TaskService.updateTaskStatus(token, task.id, !task.completed);
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Unified dark gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0F12),
                  Color.fromRGBO(15, 31, 36, 0.95),
                  Color(0xFF0A0F12),
                ],
              ),
            ),
          ),

          // Decorative teal glow
          Positioned(
            left: -110,
            top: -90,
            child: SizedBox(
              width: 280,
              height: 280,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                  child: Container(color: const Color.fromRGBO(15, 179, 160, 0.32)),
                ),
              ),
            ),
          ),

          RefreshIndicator(
            onRefresh: _loadTasks,
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: FutureBuilder<List<Task>>(
                  future: _todayTasks,
                  initialData: const <Task>[],
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
                    }

                    if (snapshot.hasError) {
                      return _ErrorPanel(message: snapshot.error?.toString() ?? 'Could not load tasks', onRetry: _loadTasks);
                    }

                    final tasks = snapshot.data ?? <Task>[];
                    if (tasks.isEmpty) {
                      return _EmptyState(message: _softError ?? 'No tasks for today.', onRetry: _loadTasks);
                    }

                    final completedCount = tasks.where((t) => t.completed).length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _GlassPanel(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Colors.tealAccent),
                                    const SizedBox(width: 8),
                                    Text(
                                      "You've completed $completedCount of ${tasks.length} tasks today.",
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _DailyProgressBar(completed: completedCount, total: tasks.length),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: tasks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return _GlassPanel(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                leading: Checkbox(
                                  value: task.completed,
                                  onChanged: (_) => _toggleTaskCompletion(task),
                                  side: const BorderSide(color: Color.fromRGBO(0, 150, 136, 0.8)),
                                  checkColor: Colors.black,
                                  activeColor: const Color.fromRGBO(100, 255, 218, 0.9),
                                ),
                                title: Text(
                                  task.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    decoration: task.completed ? TextDecoration.lineThrough : TextDecoration.none,
                                  ),
                                ),
                                trailing: Icon(
                                  task.completed ? Icons.check : Icons.radio_button_unchecked,
                                  color: task.completed ? const Color.fromRGBO(100, 255, 218, 0.9) : Colors.white54,
                                ),
                                onTap: () => _toggleTaskCompletion(task),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyProgressBar extends StatelessWidget {
  final int completed;
  final int total;
  const _DailyProgressBar({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = (total == 0) ? 0.0 : (completed / total).clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: pct,
            backgroundColor: const Color.fromRGBO(255, 255, 255, 0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(Color.fromRGBO(15, 179, 160, 0.85)),
          ),
        ),
        const SizedBox(height: 6),
        Text('$completed of $total tasks', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60)),
      ],
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(0, 0, 0, 0.35),
            border: Border.all(color: const Color.fromRGBO(0, 150, 136, 0.25)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _EmptyState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80.0),
      child: Center(
        child: _GlassPanel(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inbox_outlined, color: Colors.tealAccent),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: onRetry, child: const Text('Refresh')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80.0),
      child: Center(
        child: _GlassPanel(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent),
                const SizedBox(height: 8),
                Text('Error: $message', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}