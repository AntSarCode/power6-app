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
  late Future<List<Task>> _todayTasks;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final response = await TaskService.fetchTodayTasks(token);
    if (response.isSuccess && response.data != null) {
      setState(() {
        _todayTasks = Future.value(response.data);
      });
    } else {
      setState(() {
        _todayTasks = Future.error(response.error ?? 'Failed to fetch tasks');
      });
    }
  }

  void _toggleTaskCompletion(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    await TaskService.updateTaskStatus(token, task.id, !task.completed);
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Tasks'),
      ),
      body: FutureBuilder<List<Task>>(
        future: _todayTasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tasks for today.'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'You\'ve completed \${snapshot.data!.where((t) => t.completed).length} of \${snapshot.data!.length} tasks today.',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final task = snapshot.data![index];
                    return ListTile(
                      leading: Checkbox(
                        value: task.completed,
                        onChanged: (_) => _toggleTaskCompletion(task),
                      ),
                      title: Text(task.title,
                          style: TextStyle(
                            decoration: task.completed
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          )),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
