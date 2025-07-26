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
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        color: isCompleted ? Colors.green.shade100 : Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              if (description != null && description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
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
