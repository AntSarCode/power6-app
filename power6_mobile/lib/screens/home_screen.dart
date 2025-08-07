import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/streak_badge.dart';
import '../widgets/task_card.dart';
import '../state/app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final tasks = appState.tasks;
    final user = appState.user?.username ?? "User";
    final streak = appState.currentStreak;
    final hasCompletedToday = appState.todayCompleted;

    return AppScaffold(
      title: "Power6 Dashboard",
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "👋 Welcome back, $user!",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  StreakBadge(streakCount: streak, isActive: hasCompletedToday),
                  const SizedBox(height: 20),
                  Text(
                    'Today\'s Progress: ${appState.completedCount}/6 tasks completed',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  if (tasks.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 32.0),
                        child: Text(
                          'No tasks found.',
                          style: TextStyle(color: Colors.white70),
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
                        return Column(
                          children: [
                            TaskCard(
                              title: task.title,
                              description: task.notes,
                              isCompleted: task.completed,
                              onTap: () {
                                appState.toggleTaskCompletion(index);
                              },
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
        ),
      ),
    );
  }
}

class AppScaffold extends StatelessWidget {
  final Widget child;
  final String? title;

  const AppScaffold({super.key, required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title ?? 'Power6')),
      body: SafeArea(child: child),
    );
  }
}
