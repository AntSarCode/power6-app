// lib/models/user.dart
// Robust, null-safe model aligned with backend fields

class User {
  final int id;
  final String username;
  final bool isAdmin; // maps backend `is_admin`
  final String email;
  final String? tier;
  final DateTime? createdAt; // backend `created_at` (nullable)
  final DateTime? updatedAt; // backend `updated_at` (nullable)
  final int streak;

  const User({
    required this.id,
    required this.username,
    required this.isAdmin,
    required this.email,
    this.tier,
    this.createdAt,
    this.updatedAt,
    required this.streak,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      return DateTime.parse(s);
    }
    return null;
  }

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is String) {
      final parsed = int.tryParse(v);
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static bool _toBool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    return fallback;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _toInt(json['id']),
      username: (json['username'] ?? '').toString(),
      // prefer backend `is_admin`, fall back to `isSuperuser`/`is_superuser`
      isAdmin: _toBool(
        json['is_admin'] ?? json['isSuperuser'] ?? json['is_superuser'],
      ),
      email: (json['email'] ?? '').toString(),
      tier: json['tier'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      streak: _toInt(json['streak']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'is_admin': isAdmin,
        'email': email,
        'tier': tier,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'streak': streak,
      };
}
