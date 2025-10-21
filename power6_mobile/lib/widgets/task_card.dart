import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String? description;
  final bool isCompleted;
  final VoidCallback? onTap;

  const TaskCard({
    Key? key,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        // Use themed surface tones instead of white.
        color: isCompleted
            ? cs.surface.withOpacity(0.16)
            : cs.surface.withOpacity(0.10),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              if (description != null && description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description!,
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.70),
                    fontSize: 14,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
