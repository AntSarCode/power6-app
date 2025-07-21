import 'package:flutter/material.dart';

class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Streak Overview'),
      ),
      body: const Center(
        child: Text('Track your streaks here.'),
      ),
    );
  }
}
