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
      appBar: AppBar(
        title: const Text('Review Tasks'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => RefreshIndicator(
          onRefresh: _loadTasks,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: FutureBuilder<List<Task>>(
                  future: _todayTasks,
                  initialData: const <Task>[],
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
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
                        Text(
                          "You've completed $completedCount of ${tasks.length} tasks today.",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                leading: Checkbox(
                                  value: task.completed,
                                  onChanged: (_) => _toggleTaskCompletion(task),
                                ),
                                title: Text(
                                  task.title,
                                  style: TextStyle(
                                    decoration: task.completed
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 80),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Refresh')),
        ],
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 80),
          Text('Error: $message', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
