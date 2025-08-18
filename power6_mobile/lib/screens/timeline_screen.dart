import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../widgets/task_card.dart';
import '../utils/access.dart';
import '../widgets/tier_guard.dart';
import '../state/app_state.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  late Future<List<Task>> _taskHistory;
  String? _softError;

  @override
  void initState() {
    super.initState();
    // Initialize to avoid LateInitializationError on first build
    _taskHistory = Future.value(<Task>[]);
    _loadTaskHistory();
  }

  Future<void> _loadTaskHistory() async {
    setState(() => _softError = null);

    final token = context.read<AppState>().accessToken ?? '';
    if (token.isEmpty) {
      setState(() {
        _taskHistory = Future.value(<Task>[]);
        _softError = 'You are not signed in.';
      });
      return;
    }

    // Uses TaskService, which now routes through centralized ApiService base — no localhost.
    final response = await TaskService.fetchTodayTasks(token); // TODO: swap to real history endpoint when available

    if (!mounted) return;

    if (response.isSuccess && response.data != null) {
      setState(() => _taskHistory = Future.value(response.data));
    } else {
      setState(() {
        _taskHistory = Future.value(<Task>[]);
        _softError = response.error ?? 'Unable to fetch tasks';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TierGuard(
      requiredTier: UserTier.pro,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Task Timeline'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: _loadTaskHistory,
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) => RefreshIndicator(
            onRefresh: _loadTaskHistory,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: FutureBuilder<List<Task>>(
                    future: _taskHistory,
                    initialData: const <Task>[],
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return _ErrorPanel(message: snapshot.error?.toString() ?? 'Failed to load timeline', onRetry: _loadTaskHistory);
                      }

                      final items = snapshot.data ?? <Task>[];
                      if (items.isEmpty) {
                        return _EmptyState(message: _softError ?? 'No task history available.', onRetry: _loadTaskHistory);
                      }

                      final tasksByDate = _groupTasksByDate(items);

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
        ),
      ),
      fallback: Scaffold(
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
      ),
    );
  }

  Map<String, List<Task>> _groupTasksByDate(List<Task> tasks) {
    final Map<String, List<Task>> grouped = {};
    for (var task in tasks) {
      final dateKey = task.scheduledFor.toString().split(' ')[0];
      grouped.putIfAbsent(dateKey, () => <Task>[]).add(task);
    }
    return grouped;
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
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
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
