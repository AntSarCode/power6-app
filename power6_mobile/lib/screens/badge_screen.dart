import 'dart:ui';
import 'package:flutter/material.dart';

const _badgeAssetBase = 'lib/assets/badges';

class BadgeScreen extends StatelessWidget {
  const BadgeScreen({super.key});

  Widget _badgeImage(String fileName, {bool locked = false}) {
    return ColorFiltered(
      colorFilter: locked
          ? const ColorFilter.mode(Colors.black45, BlendMode.saturation)
          : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
      child: Image.asset(
        '$_badgeAssetBase/$fileName',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.emoji_events_outlined,
          color: Colors.white30,
          size: 32,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, Object>> badges = [
      {'name': 'starter', 'file': 'starter.png', 'unlocked': true},
      {'name': 'disciplined', 'file': 'disciplined.png', 'unlocked': false},
      {'name': 'night owl', 'file': 'night_owl.png', 'unlocked': false},
      {'name': 'early bird', 'file': 'early_bird.png', 'unlocked': true},
      {'name': 'goal getter', 'file': 'goal_getter.png', 'unlocked': false},
      {'name': 'over achiever', 'file': 'over_achiever.png', 'unlocked': false},
    ];

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
                  child: Container(color: const Color.fromRGBO(15, 179, 160, 0.32)),
                ),
              ),
            ),
          ),
          SafeArea(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: badges.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final badge = badges[index];
                final unlocked = badge['unlocked'] as bool;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(0, 0, 0, 0.35),
                        border: Border.all(
                          color: unlocked
                              ? const Color.fromRGBO(100, 255, 218, 0.4)
                              : const Color.fromRGBO(255, 255, 255, 0.08),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: _badgeImage(badge['file'] as String, locked: !unlocked),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Text(
                              badge['name'] as String,
                              style: TextStyle(
                                color: unlocked ? Colors.white : Colors.white38,
                                fontWeight:
                                    unlocked ? FontWeight.w600 : FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
