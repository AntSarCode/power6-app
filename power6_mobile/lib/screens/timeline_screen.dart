import 'dart:ui';
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

    // TODO: Swap to real history endpoint when available
    final response = await TaskService.fetchTodayTasks(token);

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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Task Timeline'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: _loadTaskHistory,
            ),
          ],
        ),
        body: Stack(
          children: [
            // Unified dark gradient background (same as other screens)
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
              top: -120,
              right: -80,
              child: SizedBox(
                width: 300,
                height: 300,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                    child: Container(color: const Color.fromRGBO(15, 179, 160, 0.32)),
                  ),
                ),
              ),
            ),

            LayoutBuilder(
              builder: (context, constraints) => RefreshIndicator(
                onRefresh: _loadTaskHistory,
                child: SafeArea(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: FutureBuilder<List<Task>>(
                          future: _taskHistory,
                          initialData: const <Task>[],
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox(
                                height: 300,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            if (snapshot.hasError) {
                              return _ErrorPanel(
                                message: snapshot.error?.toString() ?? 'Failed to load timeline',
                                onRetry: _loadTaskHistory,
                              );
                            }

                            final items = snapshot.data ?? <Task>[];
                            if (items.isEmpty) {
                              return _EmptyState(
                                message: _softError ?? 'No task history available.',
                                onRetry: _loadTaskHistory,
                              );
                            }

                            final tasksByDate = _groupTasksByDate(items);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: tasksByDate.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: _GlassPanel(
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        dividerColor: const Color.fromRGBO(255, 255, 255, 0.08),
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                      ),
                                      child: ExpansionTile(
                                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        childrenPadding: const EdgeInsets.only(bottom: 8),
                                        title: Text(
                                          entry.key,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                        trailing: const Icon(Icons.expand_more, color: Colors.white70),
                                        iconColor: Colors.white,
                                        collapsedIconColor: Colors.white70,
                                        textColor: Colors.white,
                                        collapsedTextColor: Colors.white,
                                        children: entry.value
                                            .map((task) => Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                                  child: TaskCard(
                                                    title: task.title,
                                                    description: task.notes,
                                                    isCompleted: task.completed,
                                                    onTap: () {},
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  ),
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
          ],
        ),
      ),
      fallback: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Task Timeline'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
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
            Center(
              child: _GlassPanel(
                child: const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'This feature is available to Pro users only.',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Task>> _groupTasksByDate(List<Task> tasks) {
    final Map<String, List<Task>> grouped = {};
    for (var task in tasks) {
      final date = task.scheduledFor;
      final dateKey = DateTime(date.year, date.month, date.day).toIso8601String().split('T').first;
      grouped.putIfAbsent(dateKey, () => <Task>[]).add(task);
    }
    return grouped;
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
                const Icon(Icons.history_toggle_off, color: Colors.tealAccent),
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