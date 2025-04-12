// Используем относительный путь для импорта модели AssigneeModel
import 'assignee_model.dart';

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String status;
  final int priority;
  final String creatorId;
  final String? creatorUsername;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AssigneeModel> assignees;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    required this.creatorId,
    this.creatorUsername,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    required this.assignees,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    // Предотвращаем ошибку, если 'assignees' == null
    var assigneesList = <AssigneeModel>[];
    if (json['assignees'] != null && json['assignees'] is List) {
      assigneesList =
          (json['assignees'] as List<dynamic>)
              .map((e) => AssigneeModel.fromJson(e as Map<String, dynamic>))
              .toList();
    }

    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      // Убедимся, что priority - это int
      priority:
          (json['priority'] as num?)?.toInt() ?? 3, // Значение по умолчанию 3
      creatorId: json['creator_id'] as String,
      creatorUsername: json['creator_username'] as String?,
      // Используем tryParse для большей безопасности
      dueDate:
          json['due_date'] != null && json['due_date'] is String
              ? DateTime.tryParse(json['due_date'] as String)
              : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      assignees: assigneesList,
    );
  }
}
