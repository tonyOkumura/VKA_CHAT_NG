import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/task_details_controller.dart';
// Импорты для виджетов, если понадобятся (например, для отображения исполнителей)
import '../../../data/models/task_model.dart'; // TaskModel

class TaskDetailsView extends GetView<TaskDetailsController> {
  const TaskDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Заголовок будет меняться при загрузке
        title: Obx(() => Text(controller.task.value?.title ?? 'Детали задачи')),
        centerTitle: true,
        actions: [
          // TODO: Добавить кнопки редактирования/удаления, если нужно
          // IconButton(icon: Icon(Icons.edit), onPressed: () => _navigateToEdit()),
          // IconButton(icon: Icon(Icons.delete), onPressed: () => _confirmDelete()),
        ],
      ),
      body: Obx(() {
        // --- Состояние загрузки ---
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        // --- Состояние ошибки ---
        else if (controller.errorMessage.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 10),
                  Text(
                    'Ошибка: ${controller.errorMessage.value}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed:
                        controller.fetchTaskDetails, // Повторить загрузку
                    child: const Text('Попробовать снова'),
                  ),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Назад'),
                  ).marginOnly(top: 10),
                ],
              ),
            ),
          );
        }
        // --- Задача не найдена (после загрузки) ---
        else if (controller.task.value == null) {
          return const Center(child: Text('Детали задачи не найдены.'));
        }
        // --- Отображение деталей задачи ---
        else {
          final task = controller.task.value!;
          return _buildTaskDetailsContent(context, task);
        }
      }),
      // TODO: Можно добавить поле для ввода комментария и кнопку отправки
      // bottomNavigationBar: _buildCommentInput(),
    );
  }

  // Виджет для отображения основного контента деталей
  Widget _buildTaskDetailsContent(BuildContext context, TaskModel task) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final theme = Theme.of(context);

    return ListView(
      // Используем ListView для прокрутки
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- Название ---
        Text(task.title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 16),

        // --- Описание ---
        if (task.description != null && task.description!.isNotEmpty) ...[
          Text('Описание:', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(task.description!, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
        ],

        // --- Блок Статус и Приоритет ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoChip(
              icon: _getStatusIcon(task.status),
              label: 'Статус',
              value: task.status, // TODO: Локализовать
              context: context,
            ),
            _buildInfoChip(
              icon: Icons.priority_high,
              label: 'Приоритет',
              value:
                  controller.priorityOptions[task.priority] ??
                  task.priority.toString(), // Используем маппинг из контроллера
              iconColor: _getPriorityColor(task.priority),
              context: context,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- Срок выполнения ---
        if (task.dueDate != null) ...[
          _buildInfoRow(
            icon: Icons.event_busy_outlined,
            label: 'Срок выполнения:',
            value: dateFormat.format(task.dueDate!.toLocal()),
            theme: theme,
          ),
          const SizedBox(height: 8),
        ],

        // --- Даты создания/обновления ---
        _buildInfoRow(
          icon: Icons.create_outlined,
          label: 'Создана:',
          value:
              '${task.creatorUsername ?? task.creatorId} (${dateFormat.format(task.createdAt.toLocal())})',
          theme: theme,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          icon: Icons.update_outlined,
          label: 'Обновлена:',
          value: dateFormat.format(task.updatedAt.toLocal()),
          theme: theme,
        ),
        const SizedBox(height: 16),

        // --- Отображение ОДНОГО исполнителя ---
        _buildInfoRow(
          icon: Icons.person_outline,
          label: 'Исполнитель:',
          // Показываем имя или "Не назначен"
          value: task.assigneeUsername ?? 'Не назначен',
          theme: theme,
        ),
        const SizedBox(height: 16),

        // --- Разделитель ---
        const Divider(height: 32),

        // --- TODO: Секция Комментарии ---
        _buildSectionHeader(context, 'Комментарии', Icons.comment_outlined),
        const Center(child: Text('Комментарии будут здесь')), // Заглушка
        // ListView.builder(...) или Column(...) с комментариями
        const SizedBox(height: 16),

        // --- TODO: Секция Вложения ---
        _buildSectionHeader(context, 'Вложения', Icons.attachment_outlined),
        const Center(child: Text('Вложения будут здесь')), // Заглушка
        // GridView.builder(...) или Column(...) с вложениями
        const SizedBox(height: 16),

        // --- TODO: Секция Логи ---
        _buildSectionHeader(
          context,
          'История изменений',
          Icons.history_outlined,
        ),
        const Center(child: Text('Логи будут здесь')), // Заглушка
        // ListView.builder(...) с логами
        const SizedBox(height: 16),
      ],
    );
  }

  // Вспомогательный виджет для заголовков секций
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }

  // Вспомогательный виджет для строки информации
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Вспомогательный виджет для плашки статуса/приоритета
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(
        icon,
        size: 18,
        color: iconColor ?? theme.colorScheme.primary,
      ),
      label: RichText(
        text: TextSpan(
          style: theme.textTheme.labelLarge,
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  // --- Вспомогательные функции для иконок/цветов (можно взять из TaskListItem) ---
  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Icons.radio_button_unchecked;
      case 'in_progress':
        return Icons.sync_outlined;
      case 'done':
        return Icons.check_circle_outline;
      case 'closed':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  // --- TODO: Методы для навигации на редактирование или подтверждения удаления ---
  // void _navigateToEdit() { ... }
  // void _confirmDelete() { ... }
}
