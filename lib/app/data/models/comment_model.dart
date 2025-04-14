import 'package:intl/intl.dart'; // Для парсинга и форматирования дат

class CommentModel {
  final String id;
  final String taskId;
  final String commenterId;
  final String? commenterUsername; // Может быть null, если пользователь удален?
  final String comment;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.taskId,
    required this.commenterId,
    this.commenterUsername,
    required this.comment,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      commenterId: json['commenter_id'] as String,
      commenterUsername: json['commenter_username'] as String?,
      comment: json['comment'] as String,
      createdAt:
          DateTime.parse(
            json['created_at'] as String,
          ).toLocal(), // Преобразуем в локальное время
    );
  }

  // Вспомогательный геттер для форматированной даты
  String get formattedCreatedAt {
    try {
      // Пример форматирования: "15 авг. 2024 г., 10:30"
      // Используем DateFormat из пакета intl
      final DateFormat formatter = DateFormat('dd MMM yyyy г., HH:mm', 'ru');
      return formatter.format(createdAt);
    } catch (e) {
      print("Error formatting comment date: $e");
      return createdAt.toIso8601String(); // Возвращаем ISO строку при ошибке
    }
  }
}
