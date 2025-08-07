import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/streak_service.dart';

class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key});

  bool hasPlusAccess(String tier) {
    return tier == 'plus' || tier == 'pro' || tier == 'elite' || tier == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final streakService = Provider.of<StreakService>(context, listen: false);
    final hasCompletedToday = appState.todayCompleted;
    final streakCount = appState.currentStreak;
    final tier = appState.user?.tier ?? 'free';

    if (!hasPlusAccess(tier)) {
      return const Scaffold(
        body: Center(
          child: Text(
            'This feature is available to Plus users only.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 Daily Streak'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.local_fire_department,
              size: 80,
              color: hasCompletedToday ? Colors.deepOrange : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Current Streak: $streakCount days',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text(
              hasCompletedToday
                  ? '✅ You\'ve completed your 6 tasks today!'
                  : '⚠️ You haven\'t completed 6 tasks today yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: hasCompletedToday ? Colors.green : Colors.redAccent,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Streak'),
              onPressed: () async {
                await streakService.refreshStreak();
                appState.loadStreak();
              },
            ),
          ],
        ),
      ),
    );
  }
}
