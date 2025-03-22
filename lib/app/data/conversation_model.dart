class Conversation {
  final String id;
  final String conversation_name; // Добавлено
  final bool is_group_chat; // Добавлено
  final String admin_name; // Добавлено
  final String? last_message; // Сделали nullable
  final DateTime? last_message_time; // Сделали nullable
  final int? unread_count; // Добавили nullable поле

  Conversation({
    required this.id,
    required this.conversation_name,
    required this.is_group_chat,
    required this.admin_name,
    this.last_message, // Убрали required
    this.last_message_time, // Убрали required
    this.unread_count, // Убрали required
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['conversation_id'],
      conversation_name: json['conversation_name'],
      is_group_chat: json['is_group_chat'],
      admin_name: json['admin_name'],
      last_message: json['last_message'], // Будет null, если нет
      last_message_time: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time']).toLocal()
          : null, // Проверяем наличие
      unread_count: json['unread_count'], // Будет null, если нет
    );
  }

  Conversation copyWith({
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
  }) {
    return Conversation(
      id: this.id,
      conversation_name: this.conversation_name,
      is_group_chat: this.is_group_chat,
      admin_name: this.admin_name,
      last_message: lastMessage ?? this.last_message,
      last_message_time: lastMessageTime ?? this.last_message_time,
      unread_count: unreadCount ?? this.unread_count,
    );
  }
}