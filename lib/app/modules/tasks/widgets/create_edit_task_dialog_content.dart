import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/tasks_controller.dart';

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
    final inputDecoration = InputDecoration(
      // Базовое оформление для полей
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      filled: true,
      fillColor: theme.colorScheme.onSurface.withOpacity(0.04), // Легкий фон
      isDense: true, // Компактный вид
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ), // Увеличенные отступы
    );

    // Теперь используем переданный controller
    return ConstrainedBox(
      // Ограничиваем ширину диалога
      constraints: const BoxConstraints(maxWidth: 500),
      child: Obx(
        () => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ), // Увеличим отступы диалога
          child: Form(
            key: controller.dialogFormKey, // Используем controller из параметра
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Название ---
                TextFormField(
                  controller: controller.titleDialogController,
                  decoration: inputDecoration.copyWith(
                    labelText: 'Название задачи',
                    prefixIcon: const Icon(Icons.title_outlined, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Название не может быть пустым';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- Описание ---
                TextFormField(
                  controller: controller.descriptionDialogController,
                  decoration: inputDecoration.copyWith(
                    labelText: 'Описание (опционально)',
                    prefixIcon: const Icon(
                      Icons.description_outlined,
                      size: 20,
                    ),
                    alignLabelWithHint: true, // Для многострочных полей
                  ),
                  maxLines: 3,
                  minLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 20), // Разделитель
                // --- Строка: Статус и Приоритет ---
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start, // Выравнивание по верху для валидации
                  children: [
                    // --- Статус ---
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: controller.dialogSelectedStatus.value,
                        decoration: inputDecoration.copyWith(
                          labelText: 'Статус',
                          prefixIcon: const Icon(Icons.flag_outlined, size: 20),
                        ),
                        items:
                            controller.statusOptions.map((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                // TODO: Локализовать статусы и здесь
                                child: Text(
                                  status,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                        onChanged:
                            controller.isDialogLoading.value
                                ? null
                                : (value) {
                                  if (value != null)
                                    controller.dialogSelectedStatus.value =
                                        value;
                                },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // --- Приоритет ---
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: controller.dialogSelectedPriority.value,
                        decoration: inputDecoration.copyWith(
                          labelText: 'Приоритет',
                          prefixIcon: const Icon(
                            Icons.priority_high_outlined,
                            size: 20,
                          ),
                        ),
                        items:
                            controller.priorityOptions.entries.map((entry) {
                              return DropdownMenuItem<int>(
                                value: entry.key,
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                        onChanged:
                            controller.isDialogLoading.value
                                ? null
                                : (value) {
                                  if (value != null)
                                    controller.dialogSelectedPriority.value =
                                        value;
                                },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Строка: Дата и Исполнитель ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Срок выполнения ---
                    Expanded(
                      child: TextFormField(
                        // Используем readOnly для отображения, onTap для выбора
                        readOnly: true,
                        // Кей для перерисовки при изменении значения
                        key: ValueKey(
                          'due_date_${controller.dialogSelectedDueDate.value}',
                        ),
                        initialValue:
                            controller.dialogSelectedDueDate.value == null
                                ? ''
                                : DateFormat('dd.MM.yyyy').format(
                                  controller.dialogSelectedDueDate.value!,
                                ),
                        decoration: inputDecoration.copyWith(
                          labelText: 'Срок выполнения',
                          prefixIcon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                          ),
                          hintText: 'Не задан',
                          suffixIcon:
                              controller.dialogSelectedDueDate.value != null
                                  ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    tooltip: 'Очистить дату',
                                    onPressed:
                                        controller.isDialogLoading.value
                                            ? null
                                            : () {
                                              controller
                                                  .dialogSelectedDueDate
                                                  .value = null;
                                            },
                                  )
                                  : null,
                        ),
                        onTap:
                            controller.isDialogLoading.value
                                ? null
                                : () => controller.pickDialogDueDate(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // --- Исполнитель ---
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        key: ValueKey(
                          'assignee_${controller.dialogSelectedAssignee.value?.id}',
                        ),
                        initialValue:
                            controller.dialogSelectedAssignee.value?.username ??
                            '',
                        decoration: inputDecoration.copyWith(
                          labelText: 'Исполнитель',
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            size: 20,
                          ),
                          hintText: 'Не назначен',
                          suffixIcon:
                              controller.dialogSelectedAssignee.value != null
                                  ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    tooltip: 'Убрать исполнителя',
                                    onPressed:
                                        controller.isDialogLoading.value
                                            ? null
                                            : () {
                                              controller
                                                  .dialogSelectedAssignee
                                                  .value = null;
                                              controller
                                                  .dialogSelectedAssigneeId
                                                  .value = null;
                                            },
                                  )
                                  : null,
                        ),
                        onTap:
                            controller.isDialogLoading.value
                                ? null
                                : controller.pickDialogAssignees,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // --- Отображение ошибки сохранения ---
                if (controller.dialogErrorMessage.value != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Ошибка: ${controller.dialogErrorMessage.value}',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
