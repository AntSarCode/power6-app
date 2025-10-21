import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/task_card.dart';
import '../state/app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String _appVersion = "1.0"; // label current edition
  static const String _graphicsBase = 'assets/graphics';
  static const String _logoAsset = '$_graphicsBase/power6_logo.png';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final tasks = appState.tasks;
    final user = appState.user?.username ?? "User";
    final streak = appState.currentStreak;
    final cs = Theme.of(context).colorScheme;

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
                  child: Container(color: cs.secondary.withOpacity(0.32)),
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
                              Icon(Icons.local_fire_department_rounded, size: 28, color: cs.secondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Welcome, $user',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: cs.surface.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: cs.outlineVariant.withOpacity(0.40)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.local_fire_department_rounded, size: 16, color: cs.secondary),
                                    const SizedBox(width: 6),
                                    Text('Streak: $streak', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // App logo for brand continuity (no forced white filter)
                              Image.asset(
                                _logoAsset,
                                height: 28,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ],
                          ),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
                  const SizedBox(height: 8),
                  if (tasks.isEmpty)
                    _GlassPanel(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.tips_and_updates_outlined, color: cs.secondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No tasks yet. Add up to six and we\'ll help you prioritize. Unfinished tasks roll over to tomorrow.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withOpacity(0.80)),
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
    final cs = Theme.of(context).colorScheme;
    final pct = (completed / total).clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: pct,
            backgroundColor: cs.surface.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(cs.secondary),
          ),
        ),
        const SizedBox(height: 6),
        Text('$completed of $total tasks',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant.withOpacity(0.70))),
      ],
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.12),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: cs.secondary),
              const SizedBox(width: 8),
              Text('About Power6 (v$version)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Power6 is designed around behavioral science to make consistency feel natural:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withOpacity(0.80)),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant.withOpacity(0.60), fontStyle: FontStyle.italic),
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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: cs.secondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withOpacity(0.80)),
            ),
          ),
        ],
      ),
    );
  }
}
