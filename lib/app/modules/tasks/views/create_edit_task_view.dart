import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/create_edit_task_controller.dart';

class CreateEditTaskView extends GetView<CreateEditTaskController> {
  const CreateEditTaskView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Заголовок зависит от режима (создание/редактирование)
        title: Obx(
          () => Text(
            controller.isEditing ? 'Редактировать задачу' : 'Новая задача',
          ),
        ),
        centerTitle: true,
        actions: [
          // Кнопка сохранения
          Obx(
            () => IconButton(
              icon:
                  controller.isLoading.value
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.save),
              tooltip: 'Сохранить задачу',
              // Деактивируем кнопку во время загрузки
              onPressed:
                  controller.isLoading.value ? null : controller.saveTask,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Позволяет прокручивать форму на маленьких экранах
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.formKey, // Привязываем ключ формы
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Поле Название ---
              TextFormField(
                controller: controller.titleController,
                decoration: const InputDecoration(
                  labelText: 'Название задачи',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Название не может быть пустым';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- Поле Описание ---
              TextFormField(
                controller: controller.descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание (опционально)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint:
                      true, // Выравниваем label при многострочности
                ),
                maxLines: 3, // Несколько строк для описания
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),

              // --- Выбор Статуса ---
              Obx(
                () => DropdownButtonFormField<String>(
                  value: controller.selectedStatus.value,
                  decoration: const InputDecoration(
                    labelText: 'Статус',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items:
                      controller.statusOptions.map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status), // TODO: Локализовать статусы
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedStatus.value = value;
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // --- Выбор Приоритета ---
              Obx(
                () => DropdownButtonFormField<int>(
                  value: controller.selectedPriority.value,
                  decoration: const InputDecoration(
                    labelText: 'Приоритет',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.priority_high),
                  ),
                  items:
                      controller.priorityOptions.entries.map((entry) {
                        return DropdownMenuItem<int>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedPriority.value = value;
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // --- Выбор Срока выполнения ---
              Obx(
                () => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.date_range_outlined),
                  title: Text(
                    controller.selectedDueDate.value == null
                        ? 'Срок выполнения (опционально)'
                        : 'Срок: ${DateFormat('dd.MM.yyyy').format(controller.selectedDueDate.value!)}',
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.clear,
                      color:
                          controller.selectedDueDate.value != null
                              ? Colors.grey
                              : Colors.transparent,
                    ),
                    tooltip: 'Очистить дату',
                    onPressed:
                        controller.selectedDueDate.value != null
                            ? () => controller.selectedDueDate.value = null
                            : null,
                  ),
                  onTap: () => controller.pickDueDate(context),
                ),
              ),
              const SizedBox(height: 16),

              // --- Выбор Исполнителей (Заглушка) ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.people_outline),
                title: const Text('Исполнители'),
                subtitle: Obx(
                  () => Text(
                    controller.selectedAssigneeIds.isEmpty
                        ? 'Не назначены'
                        // TODO: Показывать имена вместо ID, когда будут модели контактов
                        : 'Выбрано: ${controller.selectedAssigneeIds.length}',
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: controller.pickAssignees, // TODO: Реализовать выбор
              ),
              const SizedBox(height: 20),

              // --- Отображение ошибки сохранения ---
              Obx(() {
                if (controller.errorMessage.value != null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      'Ошибка: ${controller.errorMessage.value}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink(); // Ничего не показывать, если ошибки нет
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}
