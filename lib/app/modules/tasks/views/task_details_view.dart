import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Добавляем импорт
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/task_details_controller.dart';
// Импорты для виджетов, если понадобятся (например, для отображения исполнителей)
import '../../../data/models/task_model.dart'; // TaskModel
import '../../../data/models/file_model.dart'; // FileModel
import '../../../data/models/comment_model.dart';
import '../../../data/models/log_entry_model.dart';
// Импорт SettingsController для доступа к настройке
import '../../settings/controllers/settings_controller.dart';

// Определяем намерение для отправки комментария
class SubmitCommentIntent extends Intent {}

class TaskDetailsView extends GetView<TaskDetailsController> {
  // Убираем const, так как settingsController инициализируется не константой
  TaskDetailsView({super.key});

  // Получаем SettingsController
  final SettingsController settingsController = Get.find<SettingsController>();

  // Убираем _handleCommentKeyPress
  // void _handleCommentKeyPress(RawKeyEvent event) { ... }

  @override
  Widget build(BuildContext context) {
    // Определяем действие для отправки комментария
    // Делаем это здесь, чтобы иметь доступ к 'controller'
    final submitCommentAction = CallbackAction<SubmitCommentIntent>(
      onInvoke: (intent) {
        final bool canSubmit =
            controller.commentInputController.text.trim().isNotEmpty &&
            !controller.isSubmittingComment.value;
        if (canSubmit) {
          controller.submitComment();
        }
        return null;
      },
    );

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
          // Передаем submitCommentAction в _buildTaskDetailsContent
          return _buildTaskDetailsContent(context, task, submitCommentAction);
        }
      }),
    );
  }

  // Виджет для отображения основного контента деталей
  // Принимает submitCommentAction
  Widget _buildTaskDetailsContent(
    BuildContext context,
    TaskModel task,
    Action<SubmitCommentIntent> submitCommentAction,
  ) {
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
          Builder(
            builder: (context) {
              // Используем Builder для доступа к context/theme
              final bool isOverdue = task.dueDate!.isBefore(DateTime.now());
              final Color valueColor =
                  isOverdue
                      ? theme.colorScheme.error
                      : theme.textTheme.bodyMedium!.color!;
              final FontWeight valueWeight =
                  isOverdue ? FontWeight.bold : FontWeight.normal;

              return _buildInfoRow(
                icon: Icons.event_busy_outlined,
                label: 'Срок выполнения:',
                value: dateFormat.format(task.dueDate!.toLocal()),
                theme: theme,
                valueColor: valueColor, // Передаем цвет значения
                valueWeight: valueWeight, // Передаем насыщенность шрифта
              );
            },
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

        // --- Секция Комментарии ---
        _buildSectionHeader(context, 'Комментарии', Icons.comment_outlined),
        // Передаем submitCommentAction в _buildCommentsSection
        _buildCommentsSection(context, theme, submitCommentAction),
        const SizedBox(height: 16),

        // --- TODO: Секция Вложения ---
        _buildSectionHeader(context, 'Вложения', Icons.attachment_outlined),
        _buildAttachmentsSection(context, controller),
        const SizedBox(height: 16),

        // --- Секция Логи ---
        _buildSectionHeader(
          context,
          'История изменений',
          Icons.history_outlined,
        ),
        _buildLogsSection(context, theme), // Используем новый метод
        const SizedBox(height: 16),
      ],
    );
  }

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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    Color? valueColor,
    FontWeight? valueWeight,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: valueWeight,
            ),
          ),
        ),
      ],
    );
  }

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

  // --- НОВЫЙ ВИДЖЕТ: Секция комментариев --- (Принимает submitCommentAction)
  Widget _buildCommentsSection(
    BuildContext context,
    ThemeData theme,
    Action<SubmitCommentIntent> submitCommentAction,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Передаем submitCommentAction в _buildCommentInputField
        _buildCommentInputField(context, theme, submitCommentAction),
        const SizedBox(height: 10),
        Obx(() {
          if (controller.commentsErrorMessage.value != null) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Ошибка: ${controller.commentsErrorMessage.value}',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        Obx(() {
          if (controller.isLoadingComments.value) {
            return const Center(child: CircularProgressIndicator());
          } else if (controller.comments.isEmpty) {
            return const Text('Комментариев пока нет.');
          } else {
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.comments.length,
              itemBuilder: (context, index) {
                final comment = controller.comments[index];
                return _buildCommentItem(comment, theme);
              },
              separatorBuilder: (context, index) => const Divider(height: 1),
            );
          }
        }),
      ],
    );
  }

  // --- Виджет поля ввода комментария --- (Принимает submitCommentAction)
  Widget _buildCommentInputField(
    BuildContext context,
    ThemeData theme,
    Action<SubmitCommentIntent> submitCommentAction,
  ) {
    final colorScheme = theme.colorScheme;

    // Определяем сочетания клавиш на основе настройки
    final Map<ShortcutActivator, Intent> shortcuts = {
      if (settingsController.sendMessageOnEnter.value)
        LogicalKeySet(LogicalKeyboardKey.enter): SubmitCommentIntent(),
      if (!settingsController.sendMessageOnEnter.value)
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.enter):
            SubmitCommentIntent(),
    };

    // Определяем действия
    final Map<Type, Action<Intent>> actions = {
      SubmitCommentIntent: submitCommentAction,
    };

    return Actions(
      actions: actions,
      child: Shortcuts(
        shortcuts: shortcuts,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller.commentInputController,
                // Важно: Связываем FocusNode с TextField, если нужно управлять фокусом
                // focusNode: controller.commentFocusNode, // <- Раскомментировать и добавить в контроллер при необходимости
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Добавить комментарий...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 10.0,
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Obx(() {
              // Используем controller.commentText.value для проверки
              final canSubmit =
                  controller.commentText.value
                      .trim()
                      .isNotEmpty && // <-- Используем реактивную переменную
                  !controller.isSubmittingComment.value;
              return IconButton(
                icon:
                    controller.isSubmittingComment.value
                        ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Icon(
                          Icons.send,
                          color:
                              canSubmit
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withOpacity(0.3),
                        ),
                tooltip: 'Отправить комментарий',
                onPressed:
                    canSubmit
                        ? () => Actions.invoke(context, SubmitCommentIntent())
                        : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  // --- Виджет одного комментария ---
  Widget _buildCommentItem(CommentModel comment, ThemeData theme) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    // Используем commenterUsername, добавив проверку на null/empty
    final authorName =
        comment.commenterUsername?.isNotEmpty ?? false
            ? comment.commenterUsername!
            : 'ID: ${comment.commenterId}'; // Фоллбэк на ID

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Text(
              authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authorName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dateFormat.format(comment.createdAt.toLocal()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(comment.comment, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- НОВЫЙ ВИДЖЕТ: Секция истории изменений ---
  Widget _buildLogsSection(BuildContext context, ThemeData theme) {
    return Obx(() {
      if (controller.isLoadingLogs.value && controller.logs.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        );
      }
      if (controller.logsErrorMessage.value != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.orange, size: 32),
                const SizedBox(height: 8),
                Text(
                  controller.logsErrorMessage.value!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.orange.shade800),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: controller.fetchLogs,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        );
      }
      if (controller.logs.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Text(
              'История изменений пуста.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        );
      }
      // Используем ListView
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.logs.length,
        itemBuilder: (context, index) {
          final log = controller.logs[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              // Используем getReadableLog из модели, передавая карту приоритетов
              log.getReadableLog(controller.priorityOptions),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
            ),
          );
        },
      );
    });
  }

  // --- НОВЫЙ МЕТОД: Секция вложений ---
  Widget _buildAttachmentsSection(
    BuildContext context,
    TaskDetailsController controller,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Вложения', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Obx(() {
              if (controller.isLoadingAttachments.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.attachmentsErrorMessage.value != null) {
                return Center(
                  child: Text(
                    controller.attachmentsErrorMessage.value!,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              if (controller.attachments.isEmpty) {
                return const Center(child: Text('Вложений нет'));
              }
              // Используем ListView.builder для динамического списка
              return ListView.builder(
                shrinkWrap: true, // Важно для вложенных списков
                physics:
                    const NeverScrollableScrollPhysics(), // Отключаем скроллинг ListView
                itemCount: controller.attachments.length,
                itemBuilder: (context, index) {
                  final FileModel attachment = controller.attachments[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.attach_file,
                    ), // Простая иконка файла
                    title: Text(attachment.fileName),
                    // Можно добавить размер файла, если он есть в модели
                    // subtitle: Text('${(attachment.sizeInBytes / 1024).toStringAsFixed(2)} KB'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.download),
                          tooltip: 'Скачать',
                          onPressed:
                              () => controller.downloadAttachment(
                                attachment.id,
                                attachment.fileName,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Удалить',
                          onPressed:
                              () => controller.deleteAttachment(
                                attachment.id,
                                attachment.fileName,
                              ),
                        ),
                      ],
                    ),
                    dense: true,
                  );
                },
              );
            }),
            const SizedBox(height: 15),
            Obx(() {
              // Показываем индикатор загрузки файла
              if (controller.isUploadingAttachment.value) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: LinearProgressIndicator(),
                );
              }
              return const SizedBox.shrink(); // Возвращаем пустой виджет, если не загружаем
            }),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Добавить вложение'),
                onPressed:
                    controller.isUploadingAttachment.value
                        ? null // Блокируем кнопку во время загрузки
                        : () => controller.pickAndUploadAttachment(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TODO: Методы для навигации на редактирование или подтверждения удаления ---
  // void _navigateToEdit() { ... }
  // void _confirmDelete() { ... }
}

// Определяем класс действия для отправки комментария (можно сделать его более общим)
class SubmitCommentAction extends Action<SubmitCommentIntent> {
  final TaskDetailsController controller; // Передаем контроллер
  SubmitCommentAction(this.controller);

  @override
  Object? invoke(SubmitCommentIntent intent) {
    final bool canSubmit =
        controller.commentInputController.text.trim().isNotEmpty &&
        !controller.isSubmittingComment.value;
    if (canSubmit) {
      controller.submitComment();
    }
    return null;
  }
}
