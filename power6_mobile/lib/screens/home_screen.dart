import 'dart:ui';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Power6 Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Unified dark gradient background (same theme as login/signup)
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
            top: -130,
            right: -70,
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

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Hero Panel
                  _GlassPanel(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.local_fire_department_rounded, size: 28, color: Colors.tealAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Welcome, $user',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(children: [
                            StreakBadge(streakCount: streak, isActive: streak > 0),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "You're on a $streak-day streak. Keep it going!",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          // Daily progress bar toward 6 tasks
                          _DailyProgressBar(completed: tasks.where((t) => t.completed).length, total: 6),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // About Section
                  _GlassPanel(
                    child: _AboutSection(version: _appVersion),
                  ),

                  const SizedBox(height: 16),

                  // Tasks section
                  Text('Today\'s Tasks',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (tasks.isEmpty)
                    _GlassPanel(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.tips_and_updates_outlined, color: Colors.tealAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No tasks yet. Add up to six and we\'ll help you prioritize. Unfinished tasks roll over to tomorrow.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _GlassPanel(
                            child: TaskCard(
                              title: task.title,
                              description: task.notes,
                              isCompleted: task.completed,
                              onTap: () => appState.toggleTaskCompletion(index),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyProgressBar extends StatelessWidget {
  final int completed;
  final int total;
  const _DailyProgressBar({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = (completed / total).clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: pct,
            backgroundColor: const Color.fromRGBO(255, 255, 255, 0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(Color.fromRGBO(15, 179, 160, 0.85)),
          ),
        ),
        const SizedBox(height: 6),
        Text('$completed of $total tasks', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60)),
      ],
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

class _AboutSection extends StatelessWidget {
  final String version;
  const _AboutSection({required this.version});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.tealAccent),
              const SizedBox(width: 8),
              Text('About Power6 (v$version)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Power6 is designed around behavioral science to make consistency feel natural:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54, fontStyle: FontStyle.italic),
          ),
        ],
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
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: Color.fromRGBO(100, 255, 218, 0.9)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70))),
        ],
      ),
    );
  }
}
