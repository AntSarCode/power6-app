class Task {
  final int id;
  final int userId;
  final String title;
  final String notes;
  final int priority;
  final bool completed;
  final DateTime scheduledFor;
  final DateTime? completedAt;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.notes,
    required this.priority,
    required this.completed,
    required this.scheduledFor,
    this.completedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      notes: json['notes'] ?? '',
      priority: json['priority'],
      completed: json['completed'],
      scheduledFor: DateTime.parse(json['scheduled_for']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'notes': notes,
      'priority': priority,
      'completed': completed,
      'scheduled_for': scheduledFor.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
