import 'package:flutter/material.dart';

class StreakBadge extends StatelessWidget {
  final int streakCount;
  final bool isActive;

  const StreakBadge({
    Key? key,
    required this.streakCount,
    required this.isActive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? Colors.orange.shade100 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: isActive ? Colors.orange : Colors.grey),
          const SizedBox(width: 8),
          Text('$streakCount Day Streak'),
        ],
      ),
    );
  }
}
