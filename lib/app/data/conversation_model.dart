class Conversation {
  final String id;
  final String participantName;
  final String lastMessage;
  final DateTime lastMessageTime;

  Conversation({
    required this.id,
    required this.participantName,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['conversation_id'],
      participantName: json['participant_name'],
      lastMessage: json['last_message'] ?? '',
      lastMessageTime:
          DateTime.parse(
            json['last_message_time'] ?? DateTime.now().toString(),
          ).toLocal(),
    );
  }

  Conversation copyWith({String? lastMessage, DateTime? lastMessageTime}) {
    return Conversation(
      id: this.id,
      participantName: this.participantName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }
}
