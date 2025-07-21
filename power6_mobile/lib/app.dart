import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/task_input_screen.dart';
import 'screens/task_review_screen.dart';
import 'screens/streak_screen.dart';
import 'screens/timeline_screen.dart';

class Power6App extends StatelessWidget {
  const Power6App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Power6',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/input': (context) => const TaskInputScreen(),
        '/review': (context) => const TaskReviewScreen(),
        '/streak': (context) => const StreakScreen(),
        '/timeline': (context) => const TimelineScreen(),
      },
    );
  }
}
