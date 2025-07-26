import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/task_input_screen.dart';
import '../screens/task_review_screen.dart';
import '../screens/streak_screen.dart';
import '../screens/timeline_screen.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TaskInputScreen(),
    TaskReviewScreen(),
    TimelineScreen(),
    StreakScreen(),
    HomeScreen(), // Dashboard
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: 'Input'),
          BottomNavigationBarItem(icon: Icon(Icons.reviews), label: 'Review'),
          BottomNavigationBarItem(icon: Icon(Icons.timeline), label: 'Timeline'),
          BottomNavigationBarItem(icon: Icon(Icons.local_fire_department), label: 'Streak'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        ],
      ),
    );
  }
}

