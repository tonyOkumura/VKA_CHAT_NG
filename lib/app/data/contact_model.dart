class Contact {
  final String id;
  final String username;
  final String email;

  Contact({required this.id, required this.username, required this.email});

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['contact_id'],
      username: json['username'],
      email: json['email'],
    );
  }
}
