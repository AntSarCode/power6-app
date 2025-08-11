import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskReviewScreen extends StatefulWidget {
  const TaskReviewScreen({super.key});

  @override
  State<TaskReviewScreen> createState() => _TaskReviewScreenState();
}

class _TaskReviewScreenState extends State<TaskReviewScreen> {
  // Initialize with an empty list so the UI never shows a late-init or error by default
  Future<List<Task>> _todayTasks = Future.value(<Task>[]);

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    // If we don't have a token yet, show an empty state instead of an error
    if (token.isEmpty) {
      setState(() => _todayTasks = Future.value(<Task>[]));
      return;
    }

    final response = await TaskService.fetchTodayTasks(token);

    if (response.isSuccess) {
      final items = response.data ?? <Task>[]; // Treat null as empty
      setState(() => _todayTasks = Future.value(items));
    } else {
      final err = (response.error ?? '').toLowerCase();
      // If the backend reports "no tasks" or 404, treat it as an empty state, not an error
      if (err.contains('no tasks') || err.contains('not found') || err.contains('404')) {
        setState(() => _todayTasks = Future.value(<Task>[]));
      } else {
        setState(() => _todayTasks = Future.error(response.error ?? 'Failed to fetch tasks'));
      }
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    if (token.isEmpty) return;
    await TaskService.updateTaskStatus(token, task.id, !task.completed);
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Tasks'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: FutureBuilder<List<Task>>(
                future: _todayTasks,
                initialData: const <Task>[], // Avoids flashing empty/late states
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    // Show a concise error only for real failures
                    return Center(child: Text('Could not load tasks. Please try again.'));
                  }

                  final tasks = snapshot.data ?? <Task>[];
                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('No tasks for today.'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadTasks,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    );
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
    );
  }
}
