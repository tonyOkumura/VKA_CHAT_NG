class MessageRead {
  final String messageId;
  final String userId;
  final DateTime readAt;

  MessageRead({
    required this.messageId,
    required this.userId,
    required this.readAt,
  });

  factory MessageRead.fromJson(Map<String, dynamic> json) {
    return MessageRead(
      messageId: json['message_id'],
      userId: json['user_id'],
      readAt: DateTime.parse(json['read_at']),
    );
  }
}
