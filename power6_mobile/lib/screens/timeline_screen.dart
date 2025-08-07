import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../widgets/task_card.dart';
import '../state/app_state.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  late Future<List<Task>> _taskHistory;

  bool hasProAccess(String tier) {
    return tier == 'pro' || tier == 'elite' || tier == 'admin';
  }

  @override
  void initState() {
    super.initState();
    _loadTaskHistory();
  }

  void _loadTaskHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final response = await TaskService.fetchTodayTasks(token); // Replace with proper history endpoint when available
    if (response.isSuccess && response.data != null) {
      setState(() {
        _taskHistory = Future.value(response.data);
      });
    } else {
      setState(() {
        _taskHistory = Future.error(response.error ?? 'Unable to fetch tasks');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tier = Provider.of<AppState>(context).user?.tier ?? 'free';

    if (!hasProAccess(tier)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Timeline')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'This feature is available to Pro users only.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Timeline'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: FutureBuilder<List<Task>>(
                future: _taskHistory,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: \${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No task history available.'));
                  }

                  final tasksByDate = _groupTasksByDate(snapshot.data!);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: tasksByDate.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ExpansionTile(
                            title: Text(
                              entry.key,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            children: entry.value
                                .map((task) => TaskCard(
                                      title: task.title,
                                      description: task.notes,
                                      isCompleted: task.completed,
                                      onTap: () {},
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, List<Task>> _groupTasksByDate(List<Task> tasks) {
    final Map<String, List<Task>> grouped = {};
    for (var task in tasks) {
      final dateKey = task.scheduledFor.toString().split(' ')[0];
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(task);
    }
    return grouped;
  }
}
