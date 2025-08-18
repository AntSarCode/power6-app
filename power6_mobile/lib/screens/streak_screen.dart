import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/streak_service.dart';
import '../utils/access.dart';
import '../widgets/tier_guard.dart';

class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TierGuard(
      requiredTier: UserTier.plus,
      child: _StreakContent(),
      fallback: Scaffold(
        appBar: AppBar(title: const Text('🔥 Daily Streak')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'This feature is available to Plus users only.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final streakService = Provider.of<StreakService>(context, listen: false);
    final hasCompletedToday = appState.todayCompleted;
    final streakCount = appState.currentStreak;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 Daily Streak'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
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
          ),
        ),
      ),
    );
  }
}
