import 'package:flutter/material.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Timeline'),
      ),
      body: const Center(
        child: Text('Your task history will appear here.'),
      ),
    );
  }
}
