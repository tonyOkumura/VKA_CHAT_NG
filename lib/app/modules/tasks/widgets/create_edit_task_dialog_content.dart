import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/tasks_controller.dart';
import 'package:vka_chat_ng/app/data/models/contact_model.dart';

class CreateEditTaskDialogContent extends StatelessWidget {
  // --- Принимаем контроллер через конструктор ---
  final TasksController controller;

  const CreateEditTaskDialogContent({
    super.key,
    required this.controller, // Делаем его обязательным
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Получаем тему

    // Теперь используем переданный controller
    return Obx(
      () => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: controller.dialogFormKey, // Используем controller из параметра
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Поле Название ---
              TextFormField(
                controller: controller.titleDialogController,
                decoration: const InputDecoration(
                  labelText: 'Название задачи',
                  prefixIcon: Icon(Icons.title),
                  // Убираем рамку для более компактного вида в диалоге? Или оставляем?
                  // border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Название не может быть пустым';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // --- Поле Описание ---
              TextFormField(
                controller: controller.descriptionDialogController,
                decoration: const InputDecoration(
                  labelText: 'Описание (опционально)',
                  prefixIcon: Icon(Icons.description_outlined),
                  // border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // --- Выбор Статуса ---
              DropdownButtonFormField<String>(
                value: controller.dialogSelectedStatus.value,
                decoration: const InputDecoration(
                  labelText: 'Статус',
                  prefixIcon: Icon(Icons.flag_outlined),
                  // border: OutlineInputBorder(),
                ),
                items:
                    controller.statusOptions.map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                onChanged:
                    controller.isDialogLoading.value
                        ? null
                        : (value) {
                          // Блокируем при загрузке
                          if (value != null)
                            controller.dialogSelectedStatus.value = value;
                        },
              ),
              const SizedBox(height: 12),

              // --- Выбор Приоритета ---
              DropdownButtonFormField<int>(
                value: controller.dialogSelectedPriority.value,
                decoration: const InputDecoration(
                  labelText: 'Приоритет',
                  prefixIcon: Icon(Icons.priority_high),
                  // border: OutlineInputBorder(),
                ),
                items:
                    controller.priorityOptions.entries.map((entry) {
                      return DropdownMenuItem<int>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                onChanged:
                    controller.isDialogLoading.value
                        ? null
                        : (value) {
                          if (value != null)
                            controller.dialogSelectedPriority.value = value;
                        },
              ),
              const SizedBox(height: 12),

              // --- Выбор Срока выполнения ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.date_range_outlined),
                title: Text(
                  controller.dialogSelectedDueDate.value == null
                      ? 'Срок выполнения'
                      : 'Срок: ${DateFormat('dd.MM.yyyy').format(controller.dialogSelectedDueDate.value!)}',
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.clear,
                    color:
                        controller.dialogSelectedDueDate.value != null
                            ? Colors.grey
                            : Colors.transparent,
                  ),
                  tooltip: 'Очистить дату',
                  onPressed:
                      controller.dialogSelectedDueDate.value != null
                          ? () => controller.dialogSelectedDueDate.value = null
                          : null,
                ),
                onTap:
                    controller.isDialogLoading.value
                        ? null
                        : () => controller.pickDialogDueDate(context),
              ),

              // --- Отображение и Выбор Исполнителя ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: const Text('Исполнитель'),
                subtitle:
                    controller.dialogSelectedAssignee.value == null
                        ? const Text('Нажмите для выбора')
                        : Chip(
                          avatar: CircleAvatar(
                            backgroundColor: controller.getUserColor(
                              controller.dialogSelectedAssignee.value!.id,
                            ),
                            foregroundColor: Colors.white,
                            child: Text(
                              controller
                                      .dialogSelectedAssignee
                                      .value!
                                      .username
                                      .isNotEmpty
                                  ? controller
                                      .dialogSelectedAssignee
                                      .value!
                                      .username[0]
                                      .toUpperCase()
                                  : '?',
                            ),
                            radius: 10,
                          ),
                          label: Text(
                            controller.dialogSelectedAssignee.value!.username,
                            style: const TextStyle(fontSize: 12),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          onDeleted:
                              controller.isDialogLoading.value
                                  ? null
                                  : () {
                                    controller.dialogSelectedAssignee.value =
                                        null;
                                    controller.dialogSelectedAssigneeId.value =
                                        null;
                                  },
                          deleteIconColor: theme.colorScheme.onSurfaceVariant,
                        ),
                trailing: const Icon(Icons.chevron_right),
                onTap:
                    controller.isDialogLoading.value
                        ? null
                        : controller
                            .pickDialogAssignees, // Вызываем метод контроллера
              ),
              const SizedBox(height: 10),

              // --- Отображение ошибки сохранения ---
              if (controller.dialogErrorMessage.value != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                  child: Text(
                    'Ошибка: ${controller.dialogErrorMessage.value}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
