import 'dart:ui';
import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/task_input_screen.dart';
import '../screens/task_review_screen.dart';
import '../screens/timeline_screen.dart';
import '../screens/streak_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/power_badge_screen.dart';

/// Wrapper nav used to bypass legacy MainNav/BadgeScreen issues.
/// Includes a dedicated Badges tab so it is visible in the bottom bar.
class PowerMainNav extends StatefulWidget {
  const PowerMainNav({super.key});
  @override
  State<PowerMainNav> createState() => _PowerMainNavState();
}

class _PowerMainNavState extends State<PowerMainNav> {
  int _index = 0;

  // Order must match bottom destinations.
  final _screens = const [
    HomeScreen(),
    TaskInputScreen(),
    TaskReviewScreen(),
    TimelineScreen(),
    StreakScreen(),
    SubscriptionScreen(),
    PowerBadgeScreen(), // <-- NEW: Badges tab
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Power6'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // unified background
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
          SafeArea(child: IndexedStack(index: _index, children: _screens)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.add_box_outlined), selectedIcon: Icon(Icons.add_box), label: 'Input'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Review'),
          NavigationDestination(icon: Icon(Icons.timeline_outlined), selectedIcon: Icon(Icons.timeline), label: 'Timeline'),
          NavigationDestination(icon: Icon(Icons.local_fire_department_outlined), selectedIcon: Icon(Icons.local_fire_department), label: 'Streak'),
          NavigationDestination(icon: Icon(Icons.workspace_premium_outlined), selectedIcon: Icon(Icons.workspace_premium), label: 'Subscribe'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Badges'), // <-- NEW
        ],
      ),
    );
  }
}