import 'package:flutter/material.dart';

class StreakBadge extends StatelessWidget {
  final int streakCount;
  final bool isActive;

  const StreakBadge({
    Key? key,
    required this.streakCount,
    this.isActive = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isActive ? Colors.orangeAccent : Colors.grey,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: Colors.orange.withOpacity(0.4),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '$streakCount Day Streak',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
