class TaskModel {
  // Убираем @override
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
  final String? assigneeId; // UUID исполнителя или null
  final String? assigneeUsername; // Имя исполнителя или null

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
    this.assigneeId,
    this.assigneeUsername,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      priority: (json['priority'] as num?)?.toInt() ?? 3,
      creatorId: json['creator_id'] as String,
      creatorUsername: json['creator_username'] as String?,
      dueDate:
          json['due_date'] != null && json['due_date'] is String
              ? DateTime.tryParse(json['due_date'] as String)
              : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      assigneeId: json['assignee_id'] as String?, // Получаем ID
      assigneeUsername: json['assignee_username'] as String?, // Получаем имя
    );
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    int? priority,
    String? creatorId,
    String? creatorUsername,
    DateTime? dueDate,
    DateTime? updatedAt,
    Object? assigneeId = const Object(),
    Object? assigneeUsername = const Object(),
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      creatorId: creatorId ?? this.creatorId,
      creatorUsername: creatorUsername ?? this.creatorUsername,
      dueDate: dueDate ?? this.dueDate,
      createdAt: this.createdAt, // createdAt не меняется при copyWith
      updatedAt: updatedAt ?? DateTime.now(), // Обновляем время изменения
      // Использование Object() как sentinel value для nullable полей
      assigneeId: assigneeId is String? ? assigneeId : this.assigneeId,
      assigneeUsername:
          assigneeUsername is String?
              ? assigneeUsername
              : this.assigneeUsername,
    );
  }
}
