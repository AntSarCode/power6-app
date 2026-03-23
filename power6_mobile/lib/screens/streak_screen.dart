import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
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
    final token = appState.accessToken ?? '';
    if (token.isEmpty) {
      throw Exception('You are not signed in.');
    }

    await appState.refreshAndLoadStreak();
    return _snapshot(appState);
  }

  _StreakData _snapshot(AppState appState) {
    return _StreakData(
      streakCount: appState.currentStreak,
      hasCompletedToday: appState.todayCompleted,
      completedTodayCount: appState.completedCountToday,
      completedTodayTotal: appState.todayCompletedCount,
    );
  }

  Future<void> _refresh() async {
    setState(() => _streakFuture = _loadStreak());
    try {
      await _streakFuture;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return TierGuard(
      requiredTier: UserTier.plus,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('🔥 Daily Streak'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: <Widget>[
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
            ),
          ],
        ),
        body: Stack(
          children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFF0A0F12),
                    Color.fromRGBO(15, 31, 36, 0.95),
                    Color(0xFF0A0F12),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -120,
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
            RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<_StreakData>(
                future: _streakFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    final msg = snapshot.error?.toString().replaceFirst('Exception: ', '') ?? 'Failed to load streak';
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: <Widget>[
                        const SizedBox(height: 100),
                        Center(child: _ErrorPanel(message: msg, onRetry: _refresh)),
                      ],
                    );
                  }

                  final data = snapshot.data ?? _snapshot(context.watch<AppState>());
                  return _StreakView(
                    streakCount: data.streakCount,
                    hasCompletedToday: data.hasCompletedToday,
                    completedTodayCount: data.completedTodayCount,
                    completedTodayTotal: data.completedTodayTotal,
                    onRefresh: _refresh,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      fallback: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(title: const Text('🔥 Daily Streak'), backgroundColor: Colors.transparent, elevation: 0),
        body: Stack(
          children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFF0A0F12),
                    Color.fromRGBO(15, 31, 36, 0.95),
                    Color(0xFF0A0F12),
                  ],
                ),
              ),
            ),
            Center(
              child: _GlassPanel(
                child: const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'This feature is available to Plus users only.',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakView extends StatelessWidget {
  final int streakCount;
  final bool hasCompletedToday;
  final int completedTodayCount;
  final int completedTodayTotal;
  final Future<void> Function() onRefresh;

  const _StreakView({
    required this.streakCount,
    required this.hasCompletedToday,
    required this.completedTodayCount,
    required this.completedTodayTotal,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    Color accent = const Color.fromRGBO(100, 255, 218, 0.9);
    if (streakCount >= 100) {
      accent = const Color.fromRGBO(255, 215, 0, 0.9);
    } else if (streakCount >= 30) {
      accent = const Color.fromRGBO(173, 216, 230, 0.9);
    } else if (streakCount >= 7) {
      accent = const Color.fromRGBO(255, 140, 0, 0.9);
    }

    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _GlassPanel(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: <Widget>[
                    Icon(Icons.local_fire_department_rounded, size: 64, color: accent),
                    const SizedBox(height: 12),
                    Text(
                      '$streakCount day streak',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasCompletedToday
                          ? 'Today already has completion activity recorded.'
                          : 'No completed tasks recorded yet today.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _GlassPanel(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Today's streak progress',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: (completedTodayCount / 6).clamp(0, 1).toDouble(),
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$completedTodayCount of 6 streak-bound tasks complete • $completedTodayTotal total tasks completed today',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh streak'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakData {
  final int streakCount;
  final bool hasCompletedToday;
  final int completedTodayCount;
  final int completedTodayTotal;

  const _StreakData({
    required this.streakCount,
    required this.hasCompletedToday,
    required this.completedTodayCount,
    required this.completedTodayTotal,
  });
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(0, 0, 0, 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color.fromRGBO(0, 150, 136, 0.25)),
          ),
          child: child,
        ),
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
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.local_fire_department_outlined, size: 40, color: Colors.white70),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
