import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/data/models/task_model.dart';
import 'package:vka_chat_ng/app/modules/tasks/controllers/tasks_controller.dart';
// TODO: Импортировать модель контакта/пользователя для выбора исполнителей
// import 'package:vka_chat_ng/app/data/models/contact_model.dart';

class CreateEditTaskController extends GetxController {
  // Получаем главный TasksController для вызова createTask/updateTask
  final TasksController _tasksController = Get.find<TasksController>();

  // ID редактируемой задачи (null для создания)
  String? _editingTaskId;

  // Контроллеры для полей формы
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  // Состояние формы
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final RxBool isLoading = false.obs; // Для индикатора загрузки при сохранении
  final RxnString errorMessage = RxnString(); // Для ошибок сохранения

  // --- Реактивные переменные для полей формы ---
  final RxString selectedStatus = 'open'.obs; // Статус по умолчанию
  final RxInt selectedPriority = 3.obs; // Приоритет по умолчанию
  final Rxn<DateTime> selectedDueDate = Rxn<DateTime>(); // Срок выполнения
  // TODO: Добавить RxList<ContactModel> для выбранных исполнителей
  final RxList<String> selectedAssigneeIds = <String>[].obs; // Пока храним ID

  // Доступные опции (можно будет загружать или локализовать)
  final List<String> statusOptions = ['open', 'in_progress', 'done', 'closed'];
  final Map<int, String> priorityOptions = {
    1: 'Высокий',
    2: 'Средний',
    3: 'Низкий',
  };

  // Флаг, указывающий, редактируем мы или создаем
  bool get isEditing => _editingTaskId != null;

  @override
  void onInit() {
    super.onInit();
    // Проверяем, передан ли ID задачи в аргументах (для режима редактирования)
    if (Get.arguments != null && Get.arguments is String) {
      _editingTaskId = Get.arguments as String;
      _loadTaskDataForEditing();
    }
  }

  // Загрузка данных существующей задачи для редактирования
  Future<void> _loadTaskDataForEditing() async {
    if (!isEditing) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      // Ищем задачу в списке основного контроллера (быстрее, чем запрос к API)
      // В идеале, нужно запросить свежие данные через TaskApiService.getTaskById
      final existingTask = _tasksController.taskList.firstWhereOrNull(
        (t) => t.id == _editingTaskId,
      );

      if (existingTask != null) {
        titleController.text = existingTask.title;
        descriptionController.text = existingTask.description ?? '';
        selectedStatus.value = existingTask.status;
        selectedPriority.value = existingTask.priority;
        selectedDueDate.value =
            existingTask.dueDate?.toLocal(); // Используем локальное время
        selectedAssigneeIds.assignAll(existingTask.assignees.map((a) => a.id));
        // TODO: Загрузить полные модели ContactModel для исполнителей, если нужно
      } else {
        // TODO: Обработать случай, если задача не найдена (возможно, показать ошибку и закрыть)
        errorMessage.value = "Задача для редактирования не найдена.";
        print(
          "Task with ID $_editingTaskId not found in local list for editing.",
        );
        // Возможно, стоит сделать запрос к API здесь
        // final taskFromApi = await Get.find<TaskApiService>().getTaskById(_editingTaskId!);
        // ... заполнить поля из taskFromApi
      }
    } catch (e) {
      errorMessage.value = "Ошибка загрузки данных задачи: $e";
      print("Error loading task for editing: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Выбор даты
  Future<void> pickDueDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDueDate.value ?? DateTime.now(),
      firstDate: DateTime.now().subtract(
        const Duration(days: 30),
      ), // Примерный диапазон
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (pickedDate != null) {
      // Можно добавить выбор времени, если нужно
      selectedDueDate.value = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
    }
  }

  // TODO: Метод для выбора исполнителей (откроет новый диалог/страницу)
  void pickAssignees() {
    Get.snackbar('WIP', 'Выбор исполнителей еще не реализован');
    // Здесь будет логика показа диалога со списком контактов
    // и обновление selectedAssigneeIds
  }

  // Сохранение (создание или обновление) задачи
  Future<void> saveTask() async {
    // Валидация формы
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      bool success;
      if (isEditing) {
        // --- Обновление задачи ---
        final updateData = <String, dynamic>{};
        // Собираем только измененные поля (оптимизация) - пока отправляем все
        updateData['title'] = titleController.text;
        updateData['description'] = descriptionController.text;
        updateData['status'] = selectedStatus.value;
        updateData['priority'] = selectedPriority.value;
        updateData['assignee_ids'] = selectedAssigneeIds.toList();
        if (selectedDueDate.value != null) {
          updateData['due_date'] =
              selectedDueDate.value!.toUtc().toIso8601String();
        } else {
          // Если дату убрали, нужно ли отправлять null? Зависит от API
          // updateData['due_date'] = null; // Возможно
        }

        print('Updating task $_editingTaskId with data: $updateData');
        success = await _tasksController.updateTask(
          _editingTaskId!,
          updateData,
        );
      } else {
        // --- Создание новой задачи ---
        print('Creating new task');
        success = await _tasksController.createTask(
          title: titleController.text,
          description:
              descriptionController.text.isNotEmpty
                  ? descriptionController.text
                  : null,
          status: selectedStatus.value,
          priority: selectedPriority.value,
          assigneeIds: selectedAssigneeIds.toList(),
          dueDate: selectedDueDate.value?.toUtc(), // Отправляем в UTC
        );
      }

      if (success) {
        Get.back(); // Возвращаемся к списку задач
        Get.snackbar(
          'Успех',
          isEditing ? 'Задача успешно обновлена' : 'Задача успешно создана',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        // Ошибка должна быть установлена в _tasksController.errorMessage
        errorMessage.value =
            _tasksController.errorMessage.value ??
            'Не удалось сохранить задачу';
      }
    } catch (e) {
      print("Error saving task: $e");
      errorMessage.value = "Произошла ошибка при сохранении: $e";
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
