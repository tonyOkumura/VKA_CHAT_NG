class Message {
  final String id;
  final String conversation_id;
  final String sender_id;

  final String content;
  final String created_at;
  final bool? is_unread; // Сделали nullable
  final List<ReadByUser>? read_by_users; // Сделали nullable

  Message({
    required this.id,
    required this.conversation_id,
    required this.sender_id,

    required this.content,
    required this.created_at,
    this.is_unread, // Убрали required
    this.read_by_users, // Убрали required
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversation_id: json['conversation_id'],
      sender_id: json['sender_id'],

      content: json['content'],
      created_at: json['created_at'],
      is_unread: json['is_unread'], // Будет null, если поля нет
      read_by_users:
          json['read_by_users'] != null
              ? (json['read_by_users'] as List)
                  .map((user) => ReadByUser.fromJson(user))
                  .toList()
              : null, // Проверяем наличие поля
    );
  }

  Message copyWith({
    String? id,
    String? conversation_id,
    String? sender_id,

    String? content,
    String? created_at,
    bool? is_unread,
    List<ReadByUser>? read_by_users,
  }) {
    return Message(
      id: id ?? this.id,
      conversation_id: conversation_id ?? this.conversation_id,
      sender_id: sender_id ?? this.sender_id,

      content: content ?? this.content,
      created_at: created_at ?? this.created_at,
      is_unread: is_unread ?? this.is_unread,
      read_by_users: read_by_users ?? this.read_by_users,
    );
  }
}

class ReadByUser {
  final String contact_id;
  final String username;
  final String email;
  final String read_at;

  ReadByUser({
    required this.contact_id,
    required this.username,
    required this.email,
    required this.read_at,
  });

  factory ReadByUser.fromJson(Map<String, dynamic> json) {
    return ReadByUser(
      contact_id: json['contact_id'],
      username: json['username'],
      email: json['email'],
      read_at: json['read_at'],
    );
  }
}
