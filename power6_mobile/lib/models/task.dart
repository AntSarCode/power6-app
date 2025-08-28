class Task {
  final int id;
  final int userId;
  final String title;
  final String? notes;
  final bool completed;
  final int priority;
  final DateTime scheduledFor;
  final DateTime? completedAt;
  final bool streakBound;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.notes,
    required this.completed,
    required this.priority,
    required this.scheduledFor,
    this.completedAt,
    required this.streakBound,
  });

  Task copyWith({
    int? id,
    int? userId,
    String? title,
    String? notes,
    bool? completed,
    int? priority,
    DateTime? scheduledFor,
    DateTime? completedAt,
    bool? streakBound,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      completedAt: completedAt ?? this.completedAt,
      streakBound: streakBound ?? this.streakBound,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      notes: json['notes'],
      completed: json['completed'],
      priority: json['priority'],
      scheduledFor: DateTime.parse(json['scheduled_for']),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      streakBound: json['streak_bound'] ?? false,
    );
  }

  Map<String, dynamic> toJson({bool forCreate = false}) {
    final data = {
      'id': id,
      'user_id': userId,
      'title': title,
      'notes': notes,
      'priority': priority,
      'scheduled_for': scheduledFor.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'streak_bound': streakBound,
    };
    if (!forCreate) {
      data['completed'] = completed;
    }
    return data;
  }
}
