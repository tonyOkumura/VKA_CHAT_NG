class MessageReads {
  final String message_id;
  final String user_id;
  DateTime read_at;

  MessageReads({
    required this.message_id,
    required this.user_id,
    required this.read_at,
  });

  factory MessageReads.fromJson(Map<String, dynamic> json) {
    return MessageReads(
      message_id: json['message_id'],
      user_id: json['user_id'],
      read_at: DateTime.parse(json['read_at']).toLocal(),
    );
  }
}
