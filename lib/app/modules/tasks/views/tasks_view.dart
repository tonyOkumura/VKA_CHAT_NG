import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Для форматирования дат
import 'package:vka_chat_ng/app/modules/tasks/widgets/create_edit_task_dialog_content.dart';
import 'package:vka_chat_ng/app/widgets/main_layout.dart';
import '../controllers/tasks_controller.dart';
import '../../../data/models/task_model.dart'; // Импорт модели задачи
import 'package:vka_chat_ng/app/routes/app_pages.dart'; // <-- Добавь импорт роутов
import 'dart:async'; // <-- Импорт для Timer (debounce)

class TasksView extends GetView<TasksController> {
  TasksView({super.key});

  // Локальный контроллер для поиска
  final _searchController = TextEditingController();
  // Таймер для debounce поиска
  Timer? _debounce;

  // --- Метод для debounce ---
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Вызываем searchTasks, который теперь только фильтрует
      controller.searchTasks(query.isNotEmpty ? query : null);
    });
  }

  // --- Метод для очистки поиска и фильтра ---
  void _clearSearchAndFilter() {
    _searchController.clear(); // Очищаем поле
    // Вызываем controller.clearFilters, который сбросит все фильтры
    controller.clearFilters();
  }

  @override
  void dispose() {
    // Не забываем освобождать ресурсы
    _searchController.dispose();
    _debounce?.cancel();
    // super.dispose(); // GetView не требует вызова super.dispose
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Инициализируем поле поиска текущим значением из контроллера (если нужно)
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //    _searchController.text = controller.searchTerm.value ?? '';
    // });

    return MainLayout(
      selectedIndex: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Задачи'),
          centerTitle: true,
          actions: [
            // --- Кнопка сброса теперь проверяет все фильтры ---
            Obx(
              () => AnimatedOpacity(
                opacity:
                    (controller.statusFilter.value != null ||
                            controller.searchTerm.value != null ||
                            controller
                                .assignedToMeFilter
                                .value) // <-- Проверяем новый фильтр
                        ? 1.0
                        : 0.0,
                duration: const Duration(milliseconds: 200),
                child:
                    (controller.statusFilter.value != null ||
                            controller.searchTerm.value != null ||
                            controller
                                .assignedToMeFilter
                                .value) // <-- Проверяем новый фильтр
                        ? IconButton(
                          icon: const Icon(Icons.filter_alt_off_outlined),
                          onPressed: _clearSearchAndFilter,
                          tooltip: 'Сбросить фильтры',
                        )
                        : const SizedBox.shrink(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.fetchTasks(), // Загрузка с сервера
              tooltip: 'Обновить задачи',
            ),
          ],
          // Добавляем поле поиска и фильтр под AppBar
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50.0),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                12.0,
                4.0,
                12.0,
                8.0,
              ), // Немного отступ снизу
              child: Row(
                children: [
                  // --- Поле поиска ---
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Поиск...', // Короче текст
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: Obx(
                          () =>
                              controller.searchTerm.value != null &&
                                      controller.searchTerm.value!.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      controller.searchTasks(null);
                                    },
                                  )
                                  : const SizedBox.shrink(),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 10.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant.withOpacity(
                          0.5,
                        ),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // --- Фильтр "Назначенные мне" ---
                  Obx(
                    () => ActionChip(
                      avatar: Icon(
                        controller.assignedToMeFilter.value
                            ? Icons.person
                            : Icons.person_outline,
                        size: 18,
                        color:
                            controller.assignedToMeFilter.value
                                ? theme.colorScheme.onSecondaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                      ),
                      label: const Text('Мне'),
                      onPressed:
                          controller
                              .toggleAssignedToMeFilter, // Переключаем фильтр
                      backgroundColor:
                          controller.assignedToMeFilter.value
                              ? theme.colorScheme.secondaryContainer
                              : null,
                      labelStyle: TextStyle(
                        color:
                            controller.assignedToMeFilter.value
                                ? theme.colorScheme.onSecondaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Показать только назначенные мне задачи',
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact, // Делаем компактнее
                      side: BorderSide(
                        color: theme.dividerColor.withOpacity(0.2),
                      ), // Небольшая рамка
                    ),
                  ),
                  const SizedBox(width: 4),
                  // --- Фильтр по статусу ---
                  Obx(
                    () => DropdownButton<String>(
                      value: controller.statusFilter.value,
                      hint: const Tooltip(
                        message: 'Фильтр по статусу',
                        child: Icon(Icons.filter_list),
                      ),
                      icon:
                          const SizedBox.shrink(), // Скрываем стандартную иконку
                      underline:
                          const SizedBox.shrink(), // Скрываем подчеркивание
                      isDense: true,
                      items: [
                        // Опция "Все статусы"
                        const DropdownMenuItem<String>(
                          value: null, // null значение для "все"
                          child: Text('Все статусы'),
                        ),
                        // Остальные статусы из контроллера
                        ...controller.statusOptions.map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status), // TODO: Локализация
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        controller.applyStatusFilter(value); // Применяем фильтр
                      },
                      selectedItemBuilder: (BuildContext context) {
                        // Показываем только иконку, если выбран фильтр
                        return [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Icon(Icons.filter_list),
                          ),
                          ...controller.statusOptions.map((status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Tooltip(
                                message: 'Фильтр: $status',
                                child: const Icon(Icons.filter_list_alt),
                              ),
                            );
                          }).toList(),
                        ];
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Obx(() {
          // --- Индикатор загрузки поверх списка ---
          return Stack(
            // Используем Stack для наложения индикатора
            children: [
              if (controller.isLoading.value &&
                  controller.filteredTaskList.isNotEmpty)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),

              // --- Основной контент (загрузка, ошибка, пустой список, список) ---
              if (controller.isLoading.value &&
                  controller.filteredTaskList.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (controller.errorMessage.value != null)
                Center(
                  // ... виджет ошибки ...
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Ошибка: ${controller.errorMessage.value}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => controller.fetchTasks(),
                          child: const Text('Попробовать снова'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (controller.filteredTaskList.isEmpty)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        // Разная иконка в зависимости от того, применены ли фильтры
                        (controller.statusFilter.value != null ||
                                controller.searchTerm.value != null ||
                                controller.assignedToMeFilter.value)
                            ? Icons.filter_alt_off_outlined
                            : Icons.inbox_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        // Разный текст
                        (controller.statusFilter.value != null ||
                                controller.searchTerm.value != null ||
                                controller.assignedToMeFilter.value)
                            ? 'Задачи не найдены'
                            : 'Задач пока нет',
                      ),
                      const SizedBox(height: 10),
                      // Кнопка сброса фильтров, если они применены и список пуст
                      if (controller.statusFilter.value != null ||
                          controller.searchTerm.value != null ||
                          controller.assignedToMeFilter.value)
                        ElevatedButton(
                          onPressed: _clearSearchAndFilter,
                          child: const Text('Сбросить фильтры'),
                        )
                      else
                        ElevatedButton(
                          onPressed: () => _showCreateTaskDialog(context),
                          child: const Text('Создать задачу'),
                        ),
                    ],
                  ),
                )
              else
                RefreshIndicator(
                  onRefresh: () => controller.fetchTasks(showLoading: false),
                  child: ListView.builder(
                    itemCount: controller.filteredTaskList.length,
                    itemBuilder: (context, index) {
                      final task = controller.filteredTaskList[index];
                      return TaskListItem(task: task);
                    },
                  ),
                ),
            ],
          );
        }),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCreateTaskDialog(context),
          tooltip: 'Создать задачу',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // Метод для открытия диалога создания
  void _showCreateTaskDialog(BuildContext context) {
    controller.initDialogForCreate();
    Get.dialog(
      AlertDialog(
        title: const Text('Новая задача'),
        content: CreateEditTaskDialogContent(controller: controller),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Отмена')),
          Obx(
            () => ElevatedButton(
              onPressed:
                  controller.isDialogLoading.value
                      ? null
                      : controller.saveTaskFromDialog,
              child:
                  controller.isDialogLoading.value
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Создать'),
            ),
          ),
        ],
      ),
    ).then((_) {
      // Опционально: сбросить состояние диалога после закрытия, если нужно
      // controller.initDialogForCreate(); // Или другой метод очистки
    });
  }
}

// --- Виджет для отображения одной задачи в списке ---
class TaskListItem extends StatelessWidget {
  final TaskModel task;
  const TaskListItem({super.key, required this.task});

  // Вспомогательная функция для получения цвета приоритета
  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.red; // Высокий
      case 2:
        return Colors.orange; // Средний
      case 3:
        return Colors.green; // Низкий
      default:
        return Colors.grey; // Неизвестный
    }
  }

  // Вспомогательная функция для получения иконки статуса
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

  // Метод для открытия диалога редактирования
  void _showEditTaskDialog(BuildContext context, TaskModel task) {
    final TasksController controller = Get.find(); // Получаем контроллер здесь
    controller.initDialogForEdit(task);
    Get.dialog(
      AlertDialog(
        title: const Text('Редактировать задачу'),
        content: CreateEditTaskDialogContent(controller: controller),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Отмена')),
          Obx(
            () => ElevatedButton(
              onPressed:
                  controller.isDialogLoading.value
                      ? null
                      : controller.saveTaskFromDialog,
              child:
                  controller.isDialogLoading.value
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Сохранить'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm'); // Форматтер даты
    final TasksController controller = Get.find(); // Для цвета

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: Tooltip(
          message: 'Приоритет: ${task.priority}',
          child: Icon(Icons.label, color: _getPriorityColor(task.priority)),
        ),
        title: Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
                child: Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            Row(
              children: [
                Icon(
                  _getStatusIcon(task.status),
                  size: 16,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 4),
                Text(task.status), // Можно будет локализовать
                const SizedBox(width: 8), // Отступ
                // --- Отображение ОДНОГО исполнителя ---
                if (task.assigneeId != null && task.assigneeUsername != null)
                  Expanded(
                    // Занимает доступное место до Spacer
                    child: Tooltip(
                      message: 'Исполнитель: ${task.assigneeUsername}',
                      child: Chip(
                        avatar: CircleAvatar(
                          backgroundColor: controller.getUserColor(
                            task.assigneeId!,
                          ),
                          foregroundColor: Colors.white,
                          radius: 7,
                          child: Text(
                            task.assigneeUsername!.isNotEmpty
                                ? task.assigneeUsername![0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        label: Text(
                          task.assigneeUsername!,
                          style: const TextStyle(fontSize: 11),
                          overflow:
                              TextOverflow
                                  .ellipsis, // Обрезаем, если не влезает
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.only(left: 2, right: 4),
                        labelPadding: const EdgeInsets.only(left: 3),
                      ),
                    ),
                  )
                else
                  const Expanded(
                    // Занимает место, чтобы дата прижалась вправо
                    child: Text(
                      ' • Не назначен',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                // ------------------------------------
                if (task.dueDate != null)
                  Tooltip(
                    message: 'Срок выполнения',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_busy_outlined,
                          size: 16,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd.MM.yy').format(task.dueDate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Создал: ${task.creatorUsername ?? task.creatorId} (${dateFormat.format(task.createdAt.toLocal())})', // Показываем локальное время
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (String result) {
            if (result == 'delete') {
              _showDeleteConfirmation(context, task.id);
            } else if (result == 'edit') {
              // --- Открываем диалог редактирования ---
              _showEditTaskDialog(context, task); // Передаем задачу
            }
          },
          itemBuilder:
              (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Редактировать'),
                  ),
                ),
                // TODO: Можно добавить другие действия (изменить статус, назначить и т.д.)
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    title: Text('Удалить', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
          icon: const Icon(Icons.more_vert),
        ),
        onTap: () {
          // --- Переход к детальному просмотру задачи ---
          Get.toNamed(Routes.TASK_DETAILS, arguments: task.id); // Передаем ID
        },
      ),
    );
  }

  // Диалог подтверждения удаления
  void _showDeleteConfirmation(BuildContext context, String taskId) {
    final TasksController controller = Get.find(); // Получаем контроллер
    Get.defaultDialog(
      title: "Удалить задачу?",
      middleText:
          "Вы уверены, что хотите удалить эту задачу? Это действие необратимо.",
      confirm: TextButton(
        style: TextButton.styleFrom(foregroundColor: Colors.red),
        onPressed: () async {
          Get.back(); // Закрываем диалог
          bool success = await controller.deleteTask(
            taskId,
          ); // Вызываем удаление
          if (success) {
            Get.snackbar(
              'Успех',
              'Задача успешно удалена',
              snackPosition: SnackPosition.BOTTOM,
            );
          } else {
            // Ошибка уже должна быть в controller.errorMessage, но можно показать и здесь
            Get.snackbar(
              'Ошибка',
              controller.errorMessage.value ?? 'Не удалось удалить задачу',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        },
        child: const Text("Удалить"),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text("Отмена"),
      ),
    );
  }
}
