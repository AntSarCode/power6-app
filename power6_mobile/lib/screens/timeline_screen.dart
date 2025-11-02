import 'dart:collection';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../utils/access.dart';
import '../widgets/tier_guard.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';
import '../config/api_constants.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  String _formatYmd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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

    final token = context.read<AppState>().accessToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _taskHistory = Future.value(<Task>[]);
        _softError = 'You are not signed in.';
      });
      return;
    }

    try {
      final api = ApiService(ApiConstants.baseUrl, null);
      final res = await api.getTaskHistory(token: token);

      if (!mounted) return;

      if (res.isSuccess && res.data != null) {
        final map = res.data!;
        final dynamic listDyn = (map['items'] ?? map['data'] ?? map['results']);

        final List<Task> tasks = (listDyn as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>()
            .map((j) => Task.fromJson(j))
            .toList()
          ..sort((a, b) {
            final aT = a.createdAtUtc;
            final bT = b.createdAtUtc;
            return bT.compareTo(aT); // newest first
          });

        setState(() => _taskHistory = Future.value(tasks));
      } else {
        setState(() {
          _taskHistory = Future.value(<Task>[]);
          _softError = res.error ?? 'Unable to fetch tasks';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _taskHistory = Future.value(<Task>[]);
        _softError = 'Error: $e';
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
                                                  child: ListTile(
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                    leading: Icon(task.completed ? Icons.check_circle : Icons.circle_outlined),
                                                    title: Text(task.title),
                                                    subtitle: _buildSubtitle(task),
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
    );
  }

  Widget _buildSubtitle(Task t) {
    final created = t.createdAtUtc.toLocal();
    final completed = t.completedAtUtc?.toLocal();
    if (completed != null) {
      final diff = completed.difference(created);
      return Text('Completed in ' + _pretty(diff));
    } else {
      final diff = DateTime.now().difference(created);
      return Text('Open for ' + _pretty(diff));
    }
  }

  String _pretty(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  Map<String, List<Task>> _groupTasksByDate(List<Task> tasks) {
    // Use local day from createdAtUtc -> scheduledFor -> now, fallback to task.dayKey if present
    final byDay = SplayTreeMap<String, List<Task>>((a, b) => b.compareTo(a)); // newest day first

    String _yyyyMmDd(DateTime d) => _formatYmd(d);

    for (final t in tasks) {
      final localDt = t.createdAtUtc.toLocal();
      final key = t.dayKey ?? _yyyyMmDd(localDt);
      byDay.putIfAbsent(key, () => <Task>[]).add(t);
    }
    return byDay;
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
