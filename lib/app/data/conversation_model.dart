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
      id: json['id'],
      participantName: json['participantName'],
      lastMessage: json['lastMessage'],
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
    );
  }
}
