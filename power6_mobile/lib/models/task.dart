class Task {
  final int id;
  final int userId;
  final String title;
  final String? notes;
  final bool completed;
  final int priority; // 0=low,1=med,2=high
  final DateTime? scheduledFor; // null if backend omits
  final DateTime? completedAt;
  final bool streakBound;

  const Task({
    required this.id,
    required this.userId,
    required this.title,
    this.notes,
    required this.completed,
    required this.priority,
    this.scheduledFor,
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
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      completedAt: completedAt ?? this.completedAt,
      streakBound: streakBound ?? this.streakBound,
    );
  }

  static int _asInt(dynamic v, {int? fallback}) {
    if (v is int) return v;
    if (v is String) {
      final parsed = int.tryParse(v);
      if (parsed != null) return parsed;
    }
    if (fallback != null) return fallback;
    throw const FormatException('Expected int');
  }

  static bool _asBool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
    }
    return fallback;
  }

  static DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) {
      return DateTime.tryParse(v);
    }
    return null;
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      title: (json['title'] ?? '') as String,
      notes: json['notes'] as String?,
      completed: _asBool(json['completed'], fallback: false),
      priority: _asInt(json['priority'], fallback: 1),
      scheduledFor: _asDateTime(json['scheduled_for']),
      completedAt: _asDateTime(json['completed_at']),
      streakBound: _asBool(json['streak_bound'], fallback: false),
    );
  }

  Map<String, dynamic> toJson({bool forCreate = false}) {
    final map = <String, dynamic>{
      'id': id,
      'user_id': userId,
      'title': title,
      'notes': notes,
      'priority': priority,
      'scheduled_for': scheduledFor?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'streak_bound': streakBound,
    };
    if (!forCreate) {
      map['completed'] = completed;
    }
    return map;
  }
}
