class User {
  final int id;
  final String username;
  final bool isSuperuser;
  final String email;
  final String tier;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.isSuperuser,
    required this.email,
    required this.tier,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      isSuperuser: json['is_superuser'] ?? false,
      email: json['email'],
      tier: json['tier'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'is_superuser': isSuperuser,
      'email': email,
      'tier': tier,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
