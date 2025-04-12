class Contact {
  final String id;
  final String username;
  final String email;
  final bool isOnline;

  Contact({
    required this.id,
    required this.username,
    required this.email,
    this.isOnline = false,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['contact_id'],
      username: json['username'],
      email: json['email'],
      isOnline: json['is_online'] ?? false,
    );
  }
}
