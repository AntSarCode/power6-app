import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../services/api_service.dart';
import '../config/api_constants.dart';
import '../state/app_state.dart';

class TaskReviewScreen extends StatefulWidget {
  const TaskReviewScreen({super.key});

  @override
  State<TaskReviewScreen> createState() => _TaskReviewScreenState();
}

class _TaskReviewScreenState extends State<TaskReviewScreen> {
  // Fix C: track the review session duration in UTC
  late final DateTime _reviewSessionStartedUtc;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reviewSessionStartedUtc = DateTime.now().toUtc();
  }

  Duration get _elapsed =>
      DateTime.now().toUtc().difference(_reviewSessionStartedUtc);

  Future<void> _submitReview(List<Task> tasks) async {
    final token = context.read<AppState>().accessToken;
    if (token == null || token.isEmpty) {
      setState(() => _error = 'Not authenticated');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final api = ApiService();
    final reviewedAtIso = DateTime.now().toUtc().toIso8601String();

    try {
      // Strategy: PATCH each completed task with a reviewed_at UTC timestamp
      for (final t in tasks) {
        if (!t.completed) continue;
        final path = ApiConstants.taskById(t.id as String); // '/tasks/{id}'
        final res = await api.patch(
          path,
          token: token,
          body: {'reviewed_at': reviewedAtIso},
        );
        if (!res.isSuccess) {
          throw Exception(res.error ?? 'Failed to review task ${t.id}');
        }
      }

      if (!mounted) return;
      // Refresh tasks & streak from backend; local UTC truth is already set
      await context.read<AppState>().syncTasks();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review saved • ${_prettyDuration(_elapsed)}')),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final todayKey = _yyyyMmDd(DateTime.now());
    final todayTasks = app.tasks.where((t) => t.dayKey == todayKey).toList()
      ..sort((a, b) => a.createdAtUtc.compareTo(b.createdAtUtc));
    final completedToday = todayTasks.where((t) => t.completed).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Tasks'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Text(
                _prettyDuration(_elapsed),
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              color: Colors.red.withOpacity(0.1),
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ListTile(
            title: Text('Completed today: ${completedToday.length}'),
            subtitle: Text(
              'Session: ${_prettyDuration(_elapsed)} • Streak: ${app.currentStreak}',
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: ListView.builder(
              itemCount: todayTasks.length,
              itemBuilder: (context, i) {
                final t = todayTasks[i];
                return CheckboxListTile(
                  value: t.completed,
                  title: Text(t.title),
                  subtitle: Text('Created: ${t.createdAtUtc.toLocal()}'),
                  onChanged: (_) {
                    final idx = app.tasks.indexWhere((x) => x.id == t.id);
                    if (idx != -1) {
                      // AppState toggles completed and stamps completedAtUtc in UTC
                      app.toggleTaskCompletion(idx);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: ElevatedButton.icon(
          onPressed: _saving ? null : () => _submitReview(completedToday),
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(
            _saving ? 'Saving…' : 'Save Review (${completedToday.length})',
          ),
        ),
      ),
    );
  }

  String _prettyDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

// Local helper for local-day grouping
String _yyyyMmDd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
