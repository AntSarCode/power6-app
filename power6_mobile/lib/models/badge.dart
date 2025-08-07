class Badge {
  final int id;
  final String title;
  final String description;
  final String iconUri;
  final bool achieved;

  Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUri,
    required this.achieved,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      iconUri: json['icon_uri'] ?? '',
      achieved: json['achieved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon_uri': iconUri,
      'achieved': achieved,
    };
  }
}
