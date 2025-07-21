import 'package:flutter/material.dart';
import '../widgets/streak_badge.dart';
import '../widgets/task_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Power6 Dashboard"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "👋 Welcome back, User!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const StreakBadge(streakCount: 6, isActive: true),
            const SizedBox(height: 20),
            const TaskCard(
              title: "Complete Power6 Layout",
              description: "Verify all modules show something on screen",
              isCompleted: false,
            ),
            const SizedBox(height: 12),
            const TaskCard(
              title: "Celebrate Progress",
              description: "You've scaffolded the entire frontend!",
              isCompleted: true,
            ),
          ],
        ),
      ),
    );
  }
}
