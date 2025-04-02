class ChatParticipant {
  final String user_id;
  final String username;
  final String email;
  final bool is_online;

  ChatParticipant({
    required this.user_id,
    required this.username,
    required this.email,
    required this.is_online,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      user_id: json['user_id'],
      username: json['username'],
      email: json['email'],
      is_online: json['is_online'] ?? false,
    );
  }
}
