import 'package:intl/intl.dart';

class LogEntryModel {
  final String logId;
  final String taskId;
  final String action; // Например, 'update_status', 'update_assignee_id'
  final String? oldValue;
  final String? newValue;
  final String changedBy; // UUID пользователя
  final String? changedByUsername;
  final DateTime changedAt;

  LogEntryModel({
    required this.logId,
    required this.taskId,
    required this.action,
    this.oldValue,
    this.newValue,
    required this.changedBy,
    this.changedByUsername,
    required this.changedAt,
  });

  factory LogEntryModel.fromJson(Map<String, dynamic> json) {
    // Добавляем проверки на null перед кастом к String
    final logId = json['log_id'] as String? ?? 'unknown_log_id';
    final taskId = json['task_id'] as String? ?? 'unknown_task_id';
    final action = json['action'] as String? ?? 'unknown_action';
    final changedBy = json['changed_by'] as String? ?? 'unknown_user_id';
    final changedAtStr = json['changed_at'] as String?;
    DateTime changedAt;
    if (changedAtStr != null) {
      try {
        changedAt = DateTime.parse(changedAtStr).toLocal();
      } catch (e) {
        print("Error parsing log date '$changedAtStr': $e");
        changedAt = DateTime.now(); // Используем текущее время как fallback
      }
    } else {
      print("Warning: Log entry $logId received null for changed_at.");
      changedAt = DateTime.now(); // Используем текущее время как fallback
    }

    return LogEntryModel(
      logId: logId,
      taskId: taskId,
      action: action,
      oldValue: json['old_value']?.toString(),
      newValue: json['new_value']?.toString(),
      changedBy: changedBy,
      changedByUsername: json['changed_by_username'] as String?,
      changedAt: changedAt,
    );
  }

  // Вспомогательный геттер для форматированной даты
  String get formattedChangedAt {
    try {
      final DateFormat formatter = DateFormat('dd.MM.yy HH:mm', 'ru');
      return formatter.format(changedAt);
    } catch (e) {
      print("Error formatting log date: $e");
      return changedAt.toIso8601String();
    }
  }

  // TODO: Можно добавить метод для форматирования лога в человекочитаемую строку
  String getReadableLog(Map<int, String> priorityMap) {
    final user = changedByUsername ?? 'ID: $changedBy';
    final time = formattedChangedAt;
    String fieldName = action; // По умолчанию
    String fromValue = oldValue ?? '';
    String toValue = newValue ?? '';

    // Улучшаем читаемость для известных действий
    switch (action) {
      case 'update_status':
        fieldName = 'Статус';
        fromValue = _localizeStatus(oldValue);
        toValue = _localizeStatus(newValue);
        break;
      case 'update_priority':
        fieldName = 'Приоритет';
        fromValue = _localizePriority(oldValue, priorityMap);
        toValue = _localizePriority(newValue, priorityMap);
        break;
      case 'update_assignee_id':
        fieldName = 'Исполнитель';
        // Здесь нужны ID пользователей, чтобы показать имена
        // Это потребует передачи списка контактов или функции поиска
        // Пока оставим ID
        fromValue =
            oldValue == 'null' || oldValue == null
                ? 'не назначен'
                : 'ID: $oldValue';
        toValue =
            newValue == 'null' || newValue == null
                ? 'не назначен'
                : 'ID: $newValue';
        break;
      case 'update_title':
        fieldName = 'Название';
        break;
      case 'update_description':
        fieldName = 'Описание';
        fromValue =
            (oldValue == null || oldValue!.isEmpty) ? 'пусто' : '"$oldValue"';
        toValue =
            (newValue == null || newValue!.isEmpty) ? 'пусто' : '"$newValue"';
        break;
      case 'update_due_date':
        fieldName = 'Срок';
        final dateFormat = DateFormat('dd.MM.yyyy', 'ru');
        try {
          fromValue =
              oldValue == null
                  ? 'не указан'
                  : dateFormat.format(DateTime.parse(oldValue!));
        } catch (_) {
          fromValue = oldValue ?? 'не указан';
        }
        try {
          toValue =
              newValue == null
                  ? 'не указан'
                  : dateFormat.format(DateTime.parse(newValue!));
        } catch (_) {
          toValue = newValue ?? 'не указан';
        }
        break;
      // TODO: Добавить другие возможные 'action' из вашего API
    }

    if (action.startsWith('create')) {
      // Предполагая, что есть лог создания
      return '$user создал(а) задачу $time';
    }

    // Формируем строку
    if (oldValue == null || oldValue == 'null') {
      // Если старого значения не было (например, назначение исполнителя)
      return '$user установил(а) $fieldName: $toValue $time';
    } else if (newValue == null || newValue == 'null') {
      // Если новое значение пустое (например, снятие исполнителя)
      return '$user убрал(а) $fieldName (было: $fromValue) $time';
    } else {
      return '$user изменил(а) $fieldName с "$fromValue" на "$toValue" $time';
    }
  }

  // Вспомогательные функции для локализации (можно вынести)
  String _localizeStatus(String? status) {
    switch (status) {
      case 'open':
        return 'Открытая';
      case 'in_progress':
        return 'В работе';
      case 'done':
        return 'Готово';
      case 'closed':
        return 'Закрытая';
      default:
        return status ?? '';
    }
  }

  String _localizePriority(String? priorityStr, Map<int, String> priorityMap) {
    if (priorityStr == null) return '';
    try {
      final int priorityInt = int.parse(priorityStr);
      return priorityMap[priorityInt] ?? priorityStr;
    } catch (e) {
      return priorityStr;
    }
  }
}
