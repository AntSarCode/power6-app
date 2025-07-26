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
    final user = appState.username ?? "User";
    final streak = appState.currentStreak;
    final hasCompletedToday = appState.todayCompleted;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Power6 Dashboard"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "👋 Welcome back, $user!",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            StreakBadge(streakCount: streak, isActive: hasCompletedToday),
            const SizedBox(height: 20),
            Text(
              'Today\'s Progress: ${appState.completedCount}/6 tasks completed',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: tasks.isEmpty
                  ? const Center(child: Text('No tasks found.'))
                  : ListView.builder(
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
            ),
          ],
        ),
      ),
    );
  }
}
