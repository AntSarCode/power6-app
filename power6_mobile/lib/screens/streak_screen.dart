import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/streak_service.dart';
import '../utils/access.dart';
import '../widgets/tier_guard.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  late Future<_StreakData> _streakFuture;

  @override
  void initState() {
    super.initState();
    _streakFuture = _loadStreak();
  }

  Future<_StreakData> _loadStreak() async {
    final appState = context.read<AppState>();
    final streakService = context.read<StreakService>();
    final token = appState.accessToken ?? '';

    if (token.isEmpty) {
      // Treat as a handled error state with a clear message
      throw Exception('You are not signed in.');
    }

    try {
      // Ensure remote state is fresh; service should use centralized ApiService base.
      await streakService.refreshStreak();
      await appState.loadStreak();

      final hasCompletedToday = appState.todayCompleted;
      final streakCount = appState.currentStreak;

      return _StreakData(
        streakCount: streakCount,
        hasCompletedToday: hasCompletedToday,
      );
    } catch (e) {
      // Bubble up a friendly message; FutureBuilder will render an error panel.
      throw Exception('Unable to load streak.');
    }
  }

  Future<void> _refresh() async {
    setState(() => _streakFuture = _loadStreak());
    await _streakFuture; // Let RefreshIndicator know when to stop
  }

  @override
  Widget build(BuildContext context) {
    return TierGuard(
      requiredTier: UserTier.plus,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🔥 Daily Streak'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() => _streakFuture = _loadStreak()),
            )
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<_StreakData>(
            future: _streakFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                final msg = snapshot.error?.toString().replaceFirst('Exception: ', '') ?? 'Failed to load streak';
                return _ErrorPanel(message: msg, onRetry: _refresh);
              }

              final data = snapshot.data;
              if (data == null) {
                return _EmptyState(
                  message: 'No streak data yet. Complete your 6 tasks to start a streak!',
                  onRetry: _refresh,
                );
              }

              return _StreakView(
                streakCount: data.streakCount,
                hasCompletedToday: data.hasCompletedToday,
                onRefresh: _refresh,
              );
            },
          ),
        ),
      ),
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

class _StreakView extends StatelessWidget {
  final int streakCount;
  final bool hasCompletedToday;
  final Future<void> Function() onRefresh;
  const _StreakView({
    required this.streakCount,
    required this.hasCompletedToday,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                  onPressed: onRefresh,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _EmptyState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 80),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Refresh')),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 80),
          Text('Error: $message', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _StreakData {
  final int streakCount;
  final bool hasCompletedToday;
  const _StreakData({required this.streakCount, required this.hasCompletedToday});
}