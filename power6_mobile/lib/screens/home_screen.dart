import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_constants.dart';
import '../models/task.dart';
import '../services/analytics_service.dart';
import '../services/api_service.dart';
import '../services/task_service.dart';
import '../state/app_state.dart';
import '../ui/launch_ui.dart';
import '../widgets/feedback/modal.dart';
import '../widgets/task_card.dart';
import '../widgets/top_right_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _graphicsBase = 'assets/graphics';
  final TaskService _taskService = TaskService();
  final AnalyticsService _analytics = AnalyticsService();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = context.read<AppState>();
      _analytics.track(
        'dashboard_viewed',
        token: app.accessToken,
        properties: <String, dynamic>{
          'completed_today': app.todayCompletedCount,
          'today_task_count': app.todayTaskCount,
        },
      );
    });
  }

  @override
  void dispose() {
    _analytics.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback(
    BuildContext context,
    FeedbackReportPayload payload,
  ) async {
    final appState = context.read<AppState>();
    final token = appState.accessToken ?? '';

    final response = await ApiService(ApiConstants.baseUrl).post(
      ApiConstants.feedback,
      token: token,
      body: payload.toJson(),
    );

    if (!response.isSuccess) {
      throw Exception(response.error ?? 'Failed to submit feedback.');
    }
  }

  Future<void> _quickAddTask() async {
    final controller = TextEditingController();
    final app = context.read<AppState>();
    final remaining = (6 - app.todayCreatedCount).clamp(0, 6);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(remaining > 0 ? 'Add one of your six' : 'Daily limit reached'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: remaining > 0
                ? 'What matters next?'
                : 'You can add more tomorrow.',
          ),
          onSubmitted: (_) => Navigator.of(context).pop(controller.text.trim()),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: remaining == 0
                ? null
                : () => Navigator.of(context).pop(controller.text.trim()),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty) return;

    await _runTaskMutation(() async {
      final token = app.accessToken ?? '';
      final response = await _taskService.createTask(
        title: title,
        priority: 1,
        streakBound: true,
        token: token,
      );
      if (!response.isSuccess) {
        throw Exception(response.error ?? 'Unable to add task.');
      }
      await app.syncTasks();
      await app.loadStreak();
      _analytics.track(
        'task_created',
        token: app.accessToken,
        properties: <String, dynamic>{
          'count': 1,
          'today_task_count': app.todayTaskCount,
        },
      );
    }, success: 'Task added.');
  }

  Future<void> _completeNextTask(Task task) async {
    final app = context.read<AppState>();
    final index = app.tasks.indexWhere((candidate) => candidate.id == task.id);
    if (index == -1) return;
    var success = 'Nice. Next task completed.';
    await _runTaskMutation(() async {
      await app.toggleTaskCompletion(index, force: true);
      if (app.todayEarnedStreak) {
        success = 'All six are complete. I finished my Power6 today.';
      } else if (app.currentStreak >= 3) {
        success = 'Task complete. Your streak is building.';
      }
      _analytics.track(
        'task_completed',
        token: app.accessToken,
        properties: <String, dynamic>{
          'completed_today': app.todayCompletedCount,
          'today_task_count': app.todayTaskCount,
        },
      );
    }, success: () => success);
  }

  Future<void> _editTask(Task task) async {
    final controller = TextEditingController(text: task.title);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'Task title'),
          onSubmitted: (_) => Navigator.of(context).pop(controller.text.trim()),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty || title == task.title) return;

    await _runTaskMutation(() async {
      final app = context.read<AppState>();
      final response = await ApiService(ApiConstants.baseUrl).patch(
        ApiConstants.taskById(task.id.toString()),
        token: app.accessToken ?? '',
        body: <String, dynamic>{'title': title},
      );
      if (!response.isSuccess) {
        throw Exception(response.error ?? 'Unable to edit task.');
      }
      await app.syncTasks();
    }, success: 'Task updated.');
  }

  Future<void> _deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('"${task.title}" will be removed from today.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _runTaskMutation(() async {
      final app = context.read<AppState>();
      final response = await ApiService(ApiConstants.baseUrl).delete(
        ApiConstants.taskById(task.id.toString()),
        token: app.accessToken ?? '',
      );
      if (!response.isSuccess) {
        throw Exception(response.error ?? 'Unable to delete task.');
      }
      await app.syncTasks();
      await app.loadStreak();
    }, success: 'Task deleted.');
  }

  Future<void> _runTaskMutation(
    Future<void> Function() action, {
    required Object success,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      final message =
          success is String ? success : (success as String Function()).call();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final tasks = appState.todayTasks;
    final activeTasks = appState.todayActiveTasks;
    final user = appState.user?.username ?? 'there';
    final streak = appState.currentStreak;
    final completedToday = appState.todayCompletedCount;
    final totalToday =
        appState.todayTaskCount == 0 ? 6 : appState.todayTaskCount;
    final remainingSlots = (6 - appState.todayCreatedCount).clamp(0, 6);
    final nextTask = activeTasks.isEmpty ? null : activeTasks.first;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 56,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Image.asset(
              '$_graphicsBase/power6_logo.png',
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          title: const SizedBox.shrink(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Center(
                child: Power6TopRightMenu(
                  onSubmitFeedback: (payload) =>
                      _submitFeedback(context, payload),
                ),
              ),
            ),
          ],
        ),
        body: LaunchBackground(
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await appState.syncTasks();
                await appState.loadStreak();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: <Widget>[
                  Text(
                    'Choose the six things that matter today.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hi $user. Plan lightly, finish deliberately, and let Power6 carry the momentum.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  GlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: ActionMetric(
                                icon: Icons.check_circle_outline,
                                label: 'Today',
                                value: '$completedToday / $totalToday',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ActionMetric(
                                icon: Icons.add_task_outlined,
                                label: 'Open slots',
                                value: '$remainingSlots left',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ActionMetric(
                                icon: Icons.local_fire_department_rounded,
                                label: 'Streak',
                                value: '$streak days',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            minHeight: 9,
                            value: totalToday == 0
                                ? 0
                                : (completedToday / totalToday)
                                    .clamp(0, 1)
                                    .toDouble(),
                            backgroundColor: cs.surface.withAlpha(31),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(cs.secondary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            FilledButton.icon(
                              onPressed: _busy || remainingSlots == 0
                                  ? null
                                  : _quickAddTask,
                              icon: const Icon(Icons.add),
                              label: const Text('Quick add'),
                            ),
                            OutlinedButton.icon(
                              onPressed: nextTask == null || _busy
                                  ? null
                                  : () => _completeNextTask(nextTask),
                              icon: const Icon(Icons.done),
                              label: const Text('Complete next'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  Navigator.of(context).pushNamed('/upgrade'),
                              icon:
                                  const Icon(Icons.workspace_premium_outlined),
                              label: const Text('Upgrade'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassPanel(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(Icons.flag_outlined, color: cs.secondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                nextTask == null
                                    ? 'You are clear for now.'
                                    : 'Next up',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                nextTask == null
                                    ? 'Add up to six priority tasks, or review anything still open from earlier.'
                                    : nextTask.title,
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SixSlotPlanner(tasks: tasks, onQuickAdd: _quickAddTask),
                  const SizedBox(height: 18),
                  Text(
                    "Today's Tasks",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (tasks.isEmpty)
                    GlassPanel(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(Icons.tips_and_updates_outlined,
                              color: cs.secondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Start with one task. Power6 is intentionally capped at six so your day stays focused.',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...tasks.map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GlassPanel(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: <Widget>[
                              TaskCard(
                                title: task.title,
                                description: task.notes,
                                isCompleted: task.completed,
                                onTap: null,
                              ),
                              const Divider(height: 1),
                              OverflowBar(
                                alignment: MainAxisAlignment.end,
                                spacing: 8,
                                children: <Widget>[
                                  TextButton.icon(
                                    onPressed:
                                        _busy ? null : () => _editTask(task),
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    label: const Text('Edit'),
                                  ),
                                  TextButton.icon(
                                    onPressed:
                                        _busy ? null : () => _deleteTask(task),
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18),
                                    label: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SixSlotPlanner extends StatelessWidget {
  final List<Task> tasks;
  final VoidCallback onQuickAdd;

  const _SixSlotPlanner({required this.tasks, required this.onQuickAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.view_week_outlined, color: cs.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Six-slot plan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: tasks.length >= 6 ? null : onQuickAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < 6; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == 5 ? 0 : 8),
              child:
                  _SlotRow(index: i, task: i < tasks.length ? tasks[i] : null),
            ),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final int index;
  final Task? task;

  const _SlotRow({required this.index, required this.task});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filled = task != null;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: filled ? cs.surface.withAlpha(28) : cs.surface.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled
              ? cs.secondary.withAlpha(90)
              : cs.outlineVariant.withAlpha(70),
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 26,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: filled ? cs.secondary : cs.onSurfaceVariant,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              task?.title ?? 'Open focus slot',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: filled ? cs.onSurface : cs.onSurfaceVariant,
                decoration:
                    task?.completed == true ? TextDecoration.lineThrough : null,
                fontWeight: filled ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (task?.streakBound == true)
            Icon(Icons.local_fire_department_rounded,
                color: cs.secondary, size: 18),
        ],
      ),
    );
  }
}
