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
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.40)),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.35),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 16,
            color: isActive ? cs.secondary : cs.outline,
          ),
          const SizedBox(width: 6),
          Text(
            '$streakCount Day Streak',
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
