import 'dart:ui';
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
    try {
      final appState = context.read<AppState>();
      final streakService = context.read<StreakService>();
      final token = appState.accessToken ?? '';

      if (token.isEmpty) {
        throw Exception('You are not signed in.');
      }

      await streakService.refreshStreak();
      await appState.loadStreak();

      final hasCompletedToday = appState.todayCompleted;
      final streakCount = appState.currentStreak;

      return _StreakData(
        streakCount: streakCount,
        hasCompletedToday: hasCompletedToday,
      );
    } catch (e) {
      debugPrint('Streak load error: $e');
      throw Exception('Unable to load streak data.');
    }
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
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() => _streakFuture = _loadStreak()),
            )
          ],
        ),
        body: Stack(
          children: [
            // Unified dark gradient background (match other screens)
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
                      children: [
                        const SizedBox(height: 100),
                        Center(child: _ErrorPanel(message: msg, onRetry: _refresh)),
                      ],
                    );
                  }

                  final data = snapshot.data;
                  if (data == null) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 100),
                        Center(
                          child: _GlassPanel(
                            child: _EmptyState(
                              message: 'No streak data yet. Complete your 6 tasks to start a streak!',
                              onRetry: _refresh,
                            ),
                          ),
                        ),
                      ],
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
          ],
        ),
      ),
      fallback: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(title: const Text('🔥 Daily Streak'), backgroundColor: Colors.transparent, elevation: 0),
        body: Stack(
          children: [
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
  final Future<void> Function() onRefresh;
  const _StreakView({
    required this.streakCount,
    required this.hasCompletedToday,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Determine milestone tier for glow accent
    Color accent = const Color.fromRGBO(100, 255, 218, 0.9);
    if (streakCount >= 100) {
      accent = const Color.fromRGBO(255, 215, 0, 0.9); // gold
    } else if (streakCount >= 30) {
      accent = const Color.fromRGBO(173, 216, 230, 0.9); // light blue (diamond vibe)
    } else if (streakCount >= 7) {
      accent = const Color.fromRGBO(255, 140, 0, 0.9); // orange (ember)
    }

    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _GlassPanel(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Flame + ring meter
                    SizedBox(
                      height: 140,
                      width: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 140,
                            width: 140,
                            child: CircularProgressIndicator(
                              strokeWidth: 10,
                              value: hasCompletedToday ? 1.0 : 0.5,
                              backgroundColor: const Color.fromRGBO(255, 255, 255, 0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                            ),
                          ),
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 64,
                            color: hasCompletedToday ? accent : Colors.white54,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Current Streak',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$streakCount days',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accent),
                      ),
                      child: Text(
                        hasCompletedToday ? '✅ Today counted toward your streak' : '⚠️ Finish your six today to keep it going',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Milestones
            _GlassPanel(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.military_tech_outlined, color: Colors.tealAccent),
                        SizedBox(width: 8),
                        Text('Milestones', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _MilestoneRow(streakCount: streakCount),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Actions
            _GlassPanel(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Streak'),
                        onPressed: onRefresh,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final int streakCount;
  const _MilestoneRow({required this.streakCount});

  @override
  Widget build(BuildContext context) {
    final milestones = const [7, 30, 100];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: milestones.map((m) {
        final achieved = streakCount >= m;
        return Column(
          children: [
            Icon(
              achieved ? Icons.emoji_events : Icons.emoji_events_outlined,
              color: achieved
                  ? (m == 100
                      ? const Color.fromRGBO(255, 215, 0, 0.9)
                      : m == 30
                          ? const Color.fromRGBO(173, 216, 230, 0.9)
                          : const Color.fromRGBO(255, 140, 0, 0.9))
                  : Colors.white38,
            ),
            const SizedBox(height: 6),
            Text('$m days', style: const TextStyle(color: Colors.white70)),
          ],
        );
      }).toList(),
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_outlined, color: Colors.tealAccent),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
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
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(height: 8),
            Text('Error: $message', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
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

class _StreakData {
  final int streakCount;
  final bool hasCompletedToday;
  const _StreakData({required this.streakCount, required this.hasCompletedToday});
}
