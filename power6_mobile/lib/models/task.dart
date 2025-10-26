// task.dart (patched to integrate Fix A: unified timestamps, dayKey, UTC handling)

class Task {
  final int id;
  final int userId;
  final String title;
  final String? notes;
  final bool completed;
  final int priority; // 0=low,1=med,2=high
  final DateTime? scheduledFor; // local or utc accepted; serialized as ISO-8601

  /// UTC timestamps per Fix A
  final DateTime createdAtUtc;
  final DateTime? completedAtUtc;
  final DateTime? reviewedAtUtc;

  /// Local-calendar grouping key (e.g., '2025-10-26')
  final String dayKey;

  /// Whether this task should count toward the streak threshold
  final bool streakBound;

  const Task({
    required this.id,
    required this.userId,
    required this.title,
    this.notes,
    required this.completed,
    required this.priority,
    this.scheduledFor,
    required this.createdAtUtc,
    this.completedAtUtc,
    this.reviewedAtUtc,
    required this.dayKey,
    required this.streakBound, required completedAt,
  });

  Task copyWith({
    int? id,
    int? userId,
    String? title,
    String? notes,
    bool? completed,
    int? priority,
    DateTime? scheduledFor,
    DateTime? createdAtUtc,
    DateTime? completedAtUtc,
    DateTime? reviewedAtUtc,
    String? dayKey,
    bool? streakBound, DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      completedAtUtc: completedAtUtc ?? this.completedAtUtc,
      reviewedAtUtc: reviewedAtUtc ?? this.reviewedAtUtc,
      dayKey: dayKey ?? this.dayKey,
      streakBound: streakBound ?? this.streakBound, completedAt: null,
    );
  }

  // ----------------- helpers -----------------
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

  static DateTime _requireDateTime(dynamic v, {String field = 'datetime'}) {
    final dt = _asDateTime(v);
    if (dt == null) throw FormatException('Expected ISO-8601 in "$field"');
    return dt;
  }

  static String _yyyyMmDd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _deriveLocalDayKey(DateTime utc) {
    final local = utc.toLocal();
    return _yyyyMmDd(local);
  }

  // ----------------- JSON -----------------
  factory Task.fromJson(Map<String, dynamic> json) {
    final createdUtc = _requireDateTime(json['created_at'] ?? json['createdAt'] ?? json['created_at_utc'], field: 'created_at').toUtc();
    final completedUtc = _asDateTime(json['completed_at'] ?? json['completedAt'] ?? json['completed_at_utc'])?.toUtc();
    final reviewedUtc = _asDateTime(json['reviewed_at'] ?? json['reviewedAt'] ?? json['reviewed_at_utc'])?.toUtc();

    final dk = (json['day_key'] as String?) ?? _deriveLocalDayKey(createdUtc);

    return Task(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id'] ?? json['userId']),
      title: (json['title'] ?? '') as String,
      notes: json['notes'] as String?,
      completed: _asBool(json['completed'], fallback: false),
      priority: _asInt(json['priority'], fallback: 1),
      scheduledFor: _asDateTime(json['scheduled_for'] ?? json['scheduledFor']),
      createdAtUtc: createdUtc,
      completedAtUtc: completedUtc,
      reviewedAtUtc: reviewedUtc,
      dayKey: dk,
      streakBound: _asBool(json['streak_bound'] ?? json['streakBound'], fallback: false), completedAt: null,
    );
  }

  get completedAt => null;

  Map<String, dynamic> toJson({bool forCreate = false}) {
    final map = <String, dynamic>{
      'id': id,
      'user_id': userId,
      'title': title,
      'notes': notes,
      'priority': priority,
      'scheduled_for': scheduledFor?.toUtc().toIso8601String(),
      'created_at': createdAtUtc.toUtc().toIso8601String(),
      'completed_at': completedAtUtc?.toUtc().toIso8601String(),
      'reviewed_at': reviewedAtUtc?.toUtc().toIso8601String(),
      'day_key': dayKey,
      'streak_bound': streakBound,
    };
    // Preserve previous behavior: only send 'completed' on non-create
    if (!forCreate) {
      map['completed'] = completed;
    }
    return map;
  }
}