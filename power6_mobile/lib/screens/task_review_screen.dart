// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../services/api_service.dart';
import '../config/api_constants.dart';
import '../state/app_state.dart';

/// Rich, animated review screen (UTC-correct)
class TaskReviewScreen extends StatefulWidget {
  const TaskReviewScreen({super.key});

  @override
  State<TaskReviewScreen> createState() => _TaskReviewScreenState();
}

class _TaskReviewScreenState extends State<TaskReviewScreen>
    with SingleTickerProviderStateMixin {
  late final ApiService _api;
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  // session timer
  late final DateTime _reviewSessionStartedUtc;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = ApiService(ApiConstants.baseUrl, null);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    _reviewSessionStartedUtc = DateTime.now().toUtc();
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    _api.dispose();
    super.dispose();
  }

  Duration get _elapsed =>
      DateTime.now().toUtc().difference(_reviewSessionStartedUtc);

  Future<void> _forceRefresh() async {
    try {
      await context.read<AppState>().syncTasks();
      if (mounted) setState(() {});
    } catch (_) {}
  }

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

    final reviewedAtIso = DateTime.now().toUtc().toIso8601String();

    try {
      for (final t in tasks) {
        if (!t.completed) continue;
        final res = await _api.patch(
          ApiConstants.taskById(t.id.toString()),
          token: token,
          body: {'reviewed_at': reviewedAtIso},
        );
        if (!res.isSuccess) {
          throw Exception(res.error ?? 'Failed to review task ${t.id}');
        }
      }

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

    // --- Build the today set using UTC day_key ---
    final todayKeyUtc = _ymd(DateTime.now().toUtc());
    final todayTasks = app.tasks
        .where((t) {
          final localKey = _ymd(t.createdAtUtc.toLocal());
          return t.dayKey == todayKeyUtc || localKey == _ymd(DateTime.now());
        })
        .toList()
      ..sort((a, b) {
        final compBias = (b.completed ? 1 : 0) - (a.completed ? 1 : 0);
        if (compBias != 0) return compBias;
        final aWhen = a.completedAtUtc ?? a.createdAtUtc;
        final bWhen = b.completedAtUtc ?? b.createdAtUtc;
        return bWhen.compareTo(aWhen);
      });

    final completedToday = todayTasks.where((t) => t.completed).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Task Review'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _saving ? null : _forceRefresh,
          ),
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
      body: Stack(
        children: [
          // gradient background
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
          // soft glow
          Positioned(
            top: -110,
            right: -60,
            child: SizedBox(
              width: 280,
              height: 280,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                  child: Container(
                    color: const Color.fromRGBO(15, 179, 160, 0.32)
                        .withOpacity(0.9), // keep withOpacity
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: _forceRefresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (_error != null)
                    _GlassPanel(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style:
                                    const TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Progress header
                  _GlassPanel(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.fact_check,
                                  color: Colors.tealAccent),
                              const SizedBox(width: 8),
                              Text(
                                "Today's Progress",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              Text(
                                '${completedToday.length} / ${todayTasks.length}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: todayTasks.isEmpty
                                  ? 0
                                  : completedToday.length / todayTasks.length,
                              minHeight: 10,
                              backgroundColor:
                                  Colors.white.withOpacity(0.08), // keep
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_percent(completedToday.length, todayTasks.length)}% complete',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Task list card
                  FadeTransition(
                    opacity: _fadeIn,
                    child: _GlassPanel(
                      child: Column(
                        children: todayTasks
                            .map((t) => _TaskTile(
                                  task: t,
                                  onToggle: (value) => _toggleComplete(t, value),
                                ))
                            .toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Save Review
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _submitReview(completedToday),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_saving
                          ? 'Saving…'
                          : 'Save Review (${completedToday.length})'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleComplete(Task t, bool value) {
    final app = context.read<AppState>();
    final idx = app.tasks.indexWhere((x) => x.id == t.id);
    if (idx == -1) return;

    // Optimistic toggle; AppState should stamp UTC completedAtUtc
    app.toggleTaskCompletion(idx, force: value);
  }

  String _prettyDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  String _percent(int a, int b) {
    if (b == 0) return '0';
    final p = (a / b * 100).clamp(0, 100).toStringAsFixed(0);
    return p;
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  final ValueChanged<bool> onToggle;
  const _TaskTile({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtle = Colors.white.withOpacity(0.65); // keep withOpacity

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      leading: Icon(
        task.completed ? Icons.check_circle : Icons.circle_outlined,
        color: task.completed ? Colors.tealAccent : Colors.white70,
      ),
      title: Text(
        task.title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Row(
        children: [
          if (task.streakBound)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color.fromRGBO(0, 150, 136, 1)
                    .withOpacity(0.25), // keep withOpacity
                border: Border.all(
                  color: const Color.fromRGBO(0, 150, 136, 1)
                      .withOpacity(0.5), // keep withOpacity
                ),
              ),
              child: const Text('Streak', style: TextStyle(fontSize: 11)),
            ),
          Expanded(
            child: Text(
              _subtitle(task),
              style: TextStyle(color: subtle, fontSize: 12),
            ),
          ),
        ],
      ),
      trailing: Switch.adaptive(
        value: task.completed,
        onChanged: onToggle,
      ),
    );
  }

  String _subtitle(Task t) {
    if (t.completed) {
      final when = t.completedAtUtc?.toLocal();
      return when == null
          ? 'Completed'
          : 'Completed at ${when.toString().split('.')[0]}';
    }
    final created = t.createdAtUtc.toLocal();
    return 'Created ${created.toString().split('.')[0]}';
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(0, 0, 0, 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color.fromRGBO(0, 150, 136, 0.25),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
