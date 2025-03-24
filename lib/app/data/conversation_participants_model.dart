class ConversationParticipants {
  final String conversation_id;
  final String user_id;
  final int unread_count;
  final DateTime joined_at;

  ConversationParticipants({
    required this.conversation_id,
    required this.user_id,
    required this.unread_count,
    required this.joined_at,
  });

  factory ConversationParticipants.fromJson(Map<String, dynamic> json) {
    return ConversationParticipants(
      conversation_id: json['conversation_id'],
      user_id: json['user_id'],
      unread_count: json['unread_count'],
      joined_at: DateTime.parse(json['joined_at']).toLocal(),
    );
  }
}
