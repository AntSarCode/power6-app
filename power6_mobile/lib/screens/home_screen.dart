import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/streak_badge.dart';
import '../widgets/task_card.dart';
import '../state/app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String _appVersion = "1.0"; // label current edition

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final tasks = appState.tasks;
    final user = appState.user?.username ?? "User";
    final streak = appState.currentStreak;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Power6 Dashboard')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Welcome, $user',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  StreakBadge(streakCount: streak, isActive: streak > 0,),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You\'re on a $streak-day streak. Keep it going! ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // === About Section ===
              _AboutSection(version: _appVersion),

              const SizedBox(height: 16),

              // Tasks
              Text('Today\'s Tasks', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              if (tasks.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Text(
                    'No tasks yet. Add up to six and we\'ll help you prioritize. Unfinished tasks roll over to tomorrow.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Column(
                      children: [
                        TaskCard(
                          title: task.title,
                          description: task.notes,
                          isCompleted: task.completed,
                          onTap: () => appState.toggleTaskCompletion(index),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final String version;
  const _AboutSection({required this.version});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Text('About Power6 (v$version)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Power6 is designed around behavioral science to make consistency feel natural:',
            ),
            const SizedBox(height: 8),
            const _Bullet('Six-task focus limits cognitive load and reduces planning friction.'),
            const _Bullet('Priority ordering channels effort toward the most meaningful work first.'),
            const _Bullet('Automatic rollover preserves momentum—unfinished items are carried into the next day without guilt.'),
            const _Bullet('Streak counting rewards consistency and builds identity as a finisher.'),
            const _Bullet('Badges create milestone dopamine hits that reinforce long-term habits.'),
            const SizedBox(height: 8),
            Text(
              'Edition: v$version',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.circle, size: 6),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}