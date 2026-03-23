import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class PowerBadgeScreen extends StatelessWidget {
  const PowerBadgeScreen({super.key});

  static const _badges = [
    'starter',
    'disciplined',
    'night_owl',
    'early_bird',
    'goal_getter',
    'over_achiever',
    'task_master',
    'veteran',
    'weekend_warrior',
    'community_builder',
    'feedback_fanatic',
    'feedback_guru',
    'challenge_champion',
    'social_butterfly',
    'devout',
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final unlocked = appState.todayEarnedStreak;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Your Badges'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
          Positioned(
            top: -120,
            right: -70,
            child: SizedBox(
              width: 300,
              height: 300,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                  child: Container(color: const Color.fromRGBO(15, 179, 160, 0.22)),
                ),
              ),
            ),
          ),
          SafeArea(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _badges.length,
              itemBuilder: (context, i) => _BadgeTile(
                name: _badges[i],
                achieved: unlocked && i == 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final String name;
  final bool achieved;
  const _BadgeTile({required this.name, this.achieved = false});

  @override
  Widget build(BuildContext context) {
    final asset = 'assets/badges/' + name + '.png';
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: achieved ? const Color.fromRGBO(10, 58, 49, 0.55) : const Color.fromRGBO(0, 0, 0, 0.35),
            border: Border.all(
              color: achieved ? const Color.fromRGBO(100, 255, 218, 0.85) : const Color.fromRGBO(0, 150, 136, 0.25),
              width: achieved ? 1.4 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events_outlined, size: 40, color: Colors.white38),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 6, right: 6),
                child: Column(
                  children: [
                    Text(
                      name.replaceAll('_', ' '),
                      style: TextStyle(fontSize: 12, color: achieved ? Colors.white : Colors.white70),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achieved ? 'Unlocked' : 'Locked',
                      style: TextStyle(fontSize: 10, color: achieved ? const Color.fromRGBO(100, 255, 218, 0.9) : Colors.white38),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
