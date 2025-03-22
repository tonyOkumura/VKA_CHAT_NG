class Conversation {
  final String id;
  final String name;
  final bool is_group_chat;
  final String adminId;
  final DateTime createdAt;

  Conversation({
    required this.id,
    required this.name,
    required this.is_group_chat,
    required this.adminId,
    required this.createdAt,
  });
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['conversation_id'],
      name: json['name'],
      is_group_chat: json['is_group_chat'],
      adminId: json['admin_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  Conversation copyWith({
    String? id,
    String? name,
    bool? is_group_chat,
    String? adminId,
    DateTime? createdAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      name: name ?? this.name,
      is_group_chat: is_group_chat ?? this.is_group_chat,
      adminId: adminId ?? this.adminId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
