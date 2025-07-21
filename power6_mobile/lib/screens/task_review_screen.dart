import 'package:flutter/material.dart';

class TaskReviewScreen extends StatelessWidget {
  const TaskReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Tasks'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.checklist, size: 64, color: Colors.green),
            SizedBox(height: 20),
            Text('Here you will review your daily tasks.',
                style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
