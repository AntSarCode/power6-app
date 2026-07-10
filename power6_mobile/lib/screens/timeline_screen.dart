import 'dart:collection';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../utils/access.dart';
import '../widgets/tier_guard.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';
import '../config/api_constants.dart';
import '../services/task_insights_service.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  String _formatYmd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  late Future<List<Task>> _taskHistory;
  late Future<Map<String, dynamic>?> _analyticsFuture;
  String? _softError;
  final ApiService _api = ApiService(ApiConstants.baseUrl, null);
  final TaskInsightsService _insights = TaskInsightsService();

  @override
  void initState() {
    super.initState();
    _taskHistory = Future.value(<Task>[]);
    _analyticsFuture = Future.value(null);
    _loadTaskHistory();
    _loadAnalytics();
  }

  @override
  void dispose() {
    _api.dispose();
    _insights.dispose();
    super.dispose();
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
      final res = await _api.getTaskHistory(token: token);

      if (!mounted) return;

      if (res.isSuccess && res.data != null) {
        final map = res.data!;
        final dynamic listDyn = (map['items'] ?? map['data'] ?? map['results']);

        final List<Task> tasks = (listDyn as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>()
            .map((j) => Task.fromJson(j))
            .toList()
          ..sort((a, b) {
            final at = a.completedAtUtc ?? a.createdAtUtc;
            final bt = b.completedAtUtc ?? b.createdAtUtc;
            return bt.compareTo(at); // newest completed first
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

  Future<void> _loadAnalytics() async {
    final token = context.read<AppState>().accessToken;
    if (token == null || token.isEmpty) {
      setState(() => _analyticsFuture = Future.value(null));
      return;
    }

    final res = await _insights.fetchAnalytics(token: token);
    if (!mounted) return;
    setState(() => _analyticsFuture = Future.value(res.isSuccess ? res.data : null));
  }

  Future<void> _exportCsv() async {
    final token = context.read<AppState>().accessToken;
    if (token == null || token.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final res = await _insights.exportCsv(token: token);
    if (!mounted) return;
    if (!res.isSuccess) {
      messenger.showSnackBar(SnackBar(content: Text(res.error ?? 'Export failed.')));
      return;
    }
    final csv = res.data?['raw']?.toString() ?? '';
    if (csv.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('No CSV data returned.')));
      return;
    }
    await Clipboard.setData(ClipboardData(text: csv));
    messenger.showSnackBar(
      const SnackBar(content: Text('CSV export copied to clipboard.')),
    );
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
              onPressed: () {
                _loadTaskHistory();
                _loadAnalytics();
              },
            ),
          ],
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
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _AnalyticsPanel(
                                  analyticsFuture: _analyticsFuture,
                                  onExportCsv: _exportCsv,
                                ),
                                const SizedBox(height: 12),
                                if (items.isEmpty)
                                  _EmptyState(
                                    message: _softError ?? 'No task history available.',
                                    onRetry: _loadTaskHistory,
                                  )
                                else
                                  ..._groupTasksByDate(items).entries.map((entry) {
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
                                  }),
                              ],
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
      final ago = DateTime.now().difference(completed);
      return Text('Completed ${_pretty(ago)} ago');
    } else {
      final diff = DateTime.now().difference(created);
      return Text('Open for ${_pretty(diff)}');
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
    final byDay = SplayTreeMap<String, List<Task>>((a, b) => b.compareTo(a));
    String ymd(DateTime d) => _formatYmd(d);

    for (final t in tasks) {
      final when = (t.completedAtUtc ?? t.createdAtUtc).toLocal();
      final key = ymd(when);
      byDay.putIfAbsent(key, () => <Task>[]).add(t);
    }
    return byDay;
  }
}

class _AnalyticsPanel extends StatelessWidget {
  final Future<Map<String, dynamic>?> analyticsFuture;
  final VoidCallback onExportCsv;

  const _AnalyticsPanel({
    required this.analyticsFuture,
    required this.onExportCsv,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: analyticsFuture,
          builder: (context, snapshot) {
            final data = snapshot.data;
            final completed = data?['completed_tasks']?.toString() ?? '--';
            final rate = data?['completion_rate']?.toString() ?? '--';
            final bestDay = data?['best_day'] is Map
                ? ((data?['best_day'] as Map)['day']?.toString() ?? '--')
                : '--';
            final bestCount = data?['best_day'] is Map
                ? ((data?['best_day'] as Map)['completed']?.toString() ?? '0')
                : '0';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.insights_outlined, color: Colors.tealAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pro insights',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onExportCsv,
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: const Text('CSV'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _InsightChip(label: 'Completed', value: completed),
                    _InsightChip(label: 'Completion rate', value: '$rate%'),
                    _InsightChip(label: 'Best day', value: '$bestDay ($bestCount)'),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  final String label;
  final String value;

  const _InsightChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
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
