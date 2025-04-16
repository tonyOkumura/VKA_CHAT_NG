class User {
  final String id;
  final String username;
  final String email;
  final bool is_online;
  final DateTime created_at;
  final DateTime updated_at;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.is_online,
    required this.created_at,
    required this.updated_at,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'],
      username: json['username'],
      email: json['email'],
      is_online: json['is_online'] ?? false,
      created_at: DateTime.parse(json['created_at']),
      updated_at: DateTime.parse(json['updated_at']),
    );
  }
}
