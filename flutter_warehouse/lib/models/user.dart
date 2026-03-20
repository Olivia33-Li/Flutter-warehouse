class User {
  final String id;
  final String username;
  final String name;
  final String role;

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['_id'] ?? json['id'] ?? '',
        username: json['username'] ?? '',
        name: json['name'] ?? '',
        role: json['role'] ?? 'viewer',
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'username': username,
        'name': name,
        'role': role,
      };

  User copyWith({String? name}) => User(
        id: id,
        username: username,
        name: name ?? this.name,
        role: role,
      );

  bool get isAdmin => role == 'admin';
  bool get canEdit => role == 'admin' || role == 'editor';
}
