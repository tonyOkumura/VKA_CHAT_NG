import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vka_chat_ng/app/constants.dart';
import 'package:vka_chat_ng/app/data/models/task_model.dart';
import 'package:vka_chat_ng/app/data/services/task_api_service.dart';
import 'package:vka_chat_ng/app/data/models/contact_model.dart';
import 'package:vka_chat_ng/app/modules/contacts/controllers/contacts_controller.dart';

import 'package:vka_chat_ng/app/modules/tasks/widgets/single_assignee_selection_dialog.dart';
import 'package:dio/dio.dart'; // <-- Импорт для DioError

class TasksController extends GetxController {
  final TaskApiService _apiService = Get.find<TaskApiService>();
  late final ContactsController _contactsController;
  final _storage = const FlutterSecureStorage(); // <-- Экземпляр Secure Storage
  late String currentUserId; // <-- ID текущего пользователя

  // --- Основное состояние ---
  final RxList<TaskModel> taskList =
      <TaskModel>[].obs; // Полный список с сервера
  // --- НОВОЕ: Задачи, сгруппированные по статусу для Kanban ---
  final RxMap<String, RxList<TaskModel>> tasksByStatus =
      <String, RxList<TaskModel>>{}.obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString(null);
  // --- Фильтры ---
  final RxnString searchTerm = RxnString(null);
  final RxBool assignedToMeFilter = false.obs; // <-- Фильтр "Назначенные мне"

  // --- Временное состояние для диалога создания/редактирования ---
  final GlobalKey<FormState> dialogFormKey = GlobalKey<FormState>();
  final RxBool isDialogLoading = false.obs;
  final RxnString dialogErrorMessage = RxnString();
  final RxnString dialogEditingTaskId =
      RxnString(); // ID задачи для редактирования
  final titleDialogController = TextEditingController();
  final descriptionDialogController = TextEditingController();
  final RxString dialogSelectedStatus = 'open'.obs;
  final RxInt dialogSelectedPriority = 3.obs;
  final Rxn<DateTime> dialogSelectedDueDate = Rxn<DateTime>();
  final RxnString dialogSelectedAssigneeId = RxnString();
  final Rxn<Contact> dialogSelectedAssignee = Rxn<Contact>();

  // Доступные опции для диалога (можно вынести)
  final List<String> statusOptions = ['open', 'in_progress', 'done', 'closed'];
  final Map<int, String> priorityOptions = {
    1: 'Высокий',
    2: 'Средний',
    3: 'Низкий',
  };
  bool get isDialogEditing => dialogEditingTaskId.value != null;

  final RxBool isUpdatingStatus = false.obs; // Индикатор загрузки для статуса
  final RxSet<String> updatingTaskIds =
      <String>{}.obs; // Хранить ID задач в процессе обновления

  @override
  void onInit() async {
    // Делаем onInit асинхронным
    super.onInit();
    // --- Получаем ID текущего пользователя ---
    currentUserId = await _storage.read(key: AppKeys.userId) ?? '';
    if (currentUserId.isEmpty) {
      print("CRITICAL: Could not get current user ID in TasksController.");
      // Возможно, нужно обработать эту ошибку (например, выход из системы)
      errorMessage.value = "Не удалось определить текущего пользователя.";
      return; // Прерываем инициализацию, если ID нет
    }
    print("TasksController: Current User ID = $currentUserId");
    // ------------------------------------

    // Инициализируем _contactsController
    if (Get.isRegistered<ContactsController>()) {
      _contactsController = Get.find<ContactsController>();
      print("TasksController: Found existing ContactsController.");
      if (_contactsController.contacts.isEmpty &&
          !_contactsController.isLoading.value) {
        print("TasksController: Contacts list is empty, fetching...");
        // Не блокируем инициализацию задач из-за контактов
        _contactsController.fetchContacts().catchError((e) {
          print("Error fetching contacts during init: $e");
          // Можно показать snackbar или просто залогировать
        });
      }
    } else {
      print("TasksController: ContactsController not found, creating one.");
      _contactsController = Get.put(ContactsController());
      _contactsController.fetchContacts().catchError((e) {
        print("Error fetching contacts during init (controller created): $e");
      });
    }

    // Инициализируем карту статусов пустыми списками
    for (var status in statusOptions) {
      tasksByStatus[status] = <TaskModel>[].obs;
    }

    fetchTasks(); // Загружаем задачи
  }

  // --- Инициализация диалога ---
  void initDialogForCreate() {
    dialogEditingTaskId.value = null;
    dialogErrorMessage.value = null;
    isDialogLoading.value = false;
    titleDialogController.clear();
    descriptionDialogController.clear();
    dialogSelectedStatus.value = 'open';
    dialogSelectedPriority.value = 3;
    dialogSelectedDueDate.value = null;
    dialogSelectedAssigneeId.value = null;
    dialogSelectedAssignee.value = null;
  }

  void initDialogForEdit(TaskModel task) {
    dialogEditingTaskId.value = task.id;
    dialogErrorMessage.value = null;
    isDialogLoading.value = false;
    titleDialogController.text = task.title;
    descriptionDialogController.text = task.description ?? '';
    dialogSelectedStatus.value = task.status;
    dialogSelectedPriority.value = task.priority;

    // --- ИЗМЕНЕНИЕ: Загружаем и нормализуем к UTC полуночи ---
    // Предполагаем, что task.dueDate приходит как DateTime UTC (может быть с временем)
    if (task.dueDate != null) {
      // Берем год/месяц/день из пришедшей UTC даты и создаем новую UTC дату (полночь)
      dialogSelectedDueDate.value = DateTime.utc(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
    } else {
      dialogSelectedDueDate.value = null;
    }
    print(
      "Dialog Due Date initialized for edit (UTC): ${dialogSelectedDueDate.value}",
    );
    // ---------------------------------------------------

    dialogSelectedAssigneeId.value = task.assigneeId;
    if (task.assigneeId != null) {
      dialogSelectedAssignee.value = _contactsController.contacts
          .firstWhereOrNull((contact) => contact.id == task.assigneeId);
      if (dialogSelectedAssignee.value == null) {
        print(
          "Warning: Assignee contact not found locally for ID ${task.assigneeId}",
        );
        dialogSelectedAssignee.value = Contact(
          id: task.assigneeId!,
          username: task.assigneeUsername ?? 'ID: ${task.assigneeId}',
          email: '',
        );
      }
    } else {
      dialogSelectedAssignee.value = null;
    }
  }

  // --- Получение и Фильтрация ---

  // Основной метод загрузки с сервера
  Future<void> fetchTasks({bool showLoading = true}) async {
    if (showLoading) isLoading.value = true;
    errorMessage.value = null;
    try {
      // Загружаем *все* задачи пользователя с сервера
      final tasks = await _apiService.getTasks();
      taskList.assignAll(tasks); // Сохраняем полный список
      _applyFilters(); // Применяем текущие фильтры к загруженным данным
    } catch (e) {
      print("Error in TasksController fetchTasks: $e");
      errorMessage.value = "Ошибка загрузки задач: ${e.toString()}";
      taskList.clear(); // Очищаем списки при ошибке
      tasksByStatus.forEach((key, list) => list.clear());
    } finally {
      if (showLoading) isLoading.value = false;
    }
  }

  // Обновленный метод фильтрации: Группирует задачи по статусам
  void _applyFilters() {
    final String? search = searchTerm.value?.toLowerCase();
    final bool assignedToMe = assignedToMeFilter.value;

    // Создаем временную карту для новых отфильтрованных списков
    final Map<String, List<TaskModel>> tempTasksByStatus = {};
    for (var status in statusOptions) {
      tempTasksByStatus[status] = [];
    }

    // Итерируем по полному списку задач
    for (var task in taskList) {
      bool passesFilter = true;

      // 1. Фильтр "Назначенные мне"
      if (assignedToMe && task.assigneeId != currentUserId) {
        passesFilter = false;
      }

      // 2. Фильтр по поиску
      if (passesFilter && search != null && search.isNotEmpty) {
        final titleMatch = task.title.toLowerCase().contains(search);
        final descriptionMatch =
            task.description?.toLowerCase().contains(search) ?? false;
        final assigneeMatch =
            task.assigneeUsername?.toLowerCase().contains(search) ?? false;
        if (!(titleMatch || descriptionMatch || assigneeMatch)) {
          passesFilter = false;
        }
      }

      // Если задача прошла фильтры, добавляем ее в соответствующий список статуса
      if (passesFilter) {
        if (tempTasksByStatus.containsKey(task.status)) {
          tempTasksByStatus[task.status]!.add(task);
        } else {
          // Обработка случая, если статус задачи не соответствует стандартным колонкам
          print(
            "Warning: Task ${task.id} has unknown status '${task.status}'. Not adding to board.",
          );
        }
      }
    }

    // Обновляем реактивные списки в tasksByStatus
    tasksByStatus.forEach((status, reactiveList) {
      reactiveList.assignAll(tempTasksByStatus[status]!);
    });

    print(
      "Filters applied. Task counts: ${tasksByStatus.map((k, v) => MapEntry(k, v.length))}",
    );
  }

  // --- Методы для изменения фильтров ---

  void searchTasks(String? term) {
    searchTerm.value = term;
    _applyFilters();
  }

  // Новый метод для фильтра "Назначенные мне"
  void toggleAssignedToMeFilter() {
    assignedToMeFilter.toggle(); // Переключаем значение
    _applyFilters(); // Применяем фильтры
  }

  void clearFilters() {
    bool needsRefilter = false;
    if (searchTerm.value != null) {
      searchTerm.value = null;
      needsRefilter = true;
    }
    if (assignedToMeFilter.value) {
      // <-- Сбрасываем новый фильтр
      assignedToMeFilter.value = false;
      needsRefilter = true;
    }
    if (needsRefilter) {
      _applyFilters(); // Применяем фильтры только если что-то сбросили
    }
  }

  // --- Методы API для создания/обновления/удаления ---
  // Создание задачи (вызывается из saveTaskFromDialog)
  Future<bool> createTask({
    required String title,
    String? description,
    String status = 'open',
    int priority = 3,
    String? assigneeId,
    DateTime? dueDate,
  }) async {
    dialogErrorMessage.value = null;
    try {
      final newTaskData = <String, dynamic>{
        'title': title,
        'status': status,
        'priority': priority,
      };
      if (description != null) newTaskData['description'] = description;
      if (assigneeId != null) newTaskData['assignee_id'] = assigneeId;
      if (dueDate != null)
        newTaskData['due_date'] =
            dueDate.toUtc().toIso8601String(); // Отправляем UTC

      final createdTask = await _apiService.createTask(newTaskData);
      taskList.add(createdTask);
      _applyFilters(); // Обновляем список после создания
      return true; // Успех
    } catch (e) {
      print("Error in TasksController createTask: $e");
      dialogErrorMessage.value = "Ошибка создания задачи: ${e.toString()}";
      return false; // Неудача
    }
  }

  Future<bool> updateTask(
    String taskId,
    Map<String, dynamic> updateData,
  ) async {
    dialogErrorMessage.value = null;
    try {
      final updatedTask = await _apiService.updateTask(taskId, updateData);
      final index = taskList.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        taskList[index] = updatedTask;
        _applyFilters();
      } else {
        print(
          "Warning: Updated task $taskId not found in local list. Forcing refetch.",
        );
        await fetchTasks(showLoading: false);
      }
      return true;
    } catch (e) {
      print("Error in TasksController updateTask: $e");
      dialogErrorMessage.value = "Ошибка обновления задачи: ${e.toString()}";
      return false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _apiService.deleteTask(taskId);
      // Удаляем из обоих списков
      taskList.removeWhere((task) => task.id == taskId);
      _applyFilters(); // Обновляем колонки доски
      return true;
    } catch (e) {
      print("Error in TasksController deleteTask: $e");
      errorMessage.value = "Ошибка удаления задачи: ${e.toString()}";
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // --- МЕТОДЫ API И ЛОГИКА ОБНОВЛЕНИЯ ---

  // --- УДАЛЯЕМ или комментируем handleDragDropUpdate ---
  /*
  Future<void> handleDragDropUpdate(String taskId, String oldStatus, String newStatus) async {
    // ...
  }
  */

  // --- НОВЫЙ МЕТОД: Запрос на обновление статуса без оптимистичного UI ---
  Future<void> requestStatusUpdate(String taskId, String newStatus) async {
    print(
      "--- requestStatusUpdate START --- Task ID: $taskId, New Status: $newStatus",
    );
    // Показываем индикатор для конкретной задачи (или глобальный)
    updatingTaskIds.add(taskId);
    // isUpdatingStatus.value = true; // Если нужен глобальный индикатор

    try {
      final updateData = {'status': newStatus};
      print(
        "  Attempting API call: _apiService.updateTask with data: $updateData",
      );
      await _apiService.updateTask(taskId, updateData);
      print("  API call successful for task $taskId status to $newStatus");

      // --- ВАЖНО: Перезагружаем все задачи ПОСЛЕ успеха ---
      print("  API success, fetching all tasks to refresh board...");
      await fetchTasks(
        showLoading: false,
      ); // showLoading: false, т.к. у нас свой индикатор
      print("  Tasks fetched and board refreshed.");
    } catch (e, stackTrace) {
      print("!!! API call FAILED for task $taskId !!! Error: $e");
      print("StackTrace: $stackTrace");
      errorMessage.value = "Ошибка обновления статуса: ${e.toString()}";

      // Показываем ошибку пользователю
      String snackbarMessage = 'Не удалось обновить статус задачи.';
      if (e is DioError && e.response?.statusCode == 403) {
        snackbarMessage = 'Нет прав на изменение статуса этой задачи.';
      }
      Get.snackbar(
        'Ошибка',
        snackbarMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      // UI не менялся, откат не нужен.
    } finally {
      // Убираем индикатор для задачи (или глобальный)
      updatingTaskIds.remove(taskId);
      // isUpdatingStatus.value = false; // Если нужен глобальный индикатор
      print("--- requestStatusUpdate END --- Task ID: $taskId");
    }
  }

  // --- Методы для диалога ---

  // Выбор даты в диалоге
  Future<void> pickDialogDueDate(BuildContext context) async {
    // Для initialDate лучше использовать UTC текущего выбранного значения или сегодняшнюю дату
    final DateTime initialPickerDate =
        dialogSelectedDueDate.value?.toUtc() ?? DateTime.now().toUtc();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialPickerDate, // Передаем UTC
      firstDate: DateTime.utc(
        DateTime.now().year - 1,
        1,
        1,
      ), // Диапазон тоже в UTC
      lastDate: DateTime.utc(DateTime.now().year + 5, 12, 31),
    );

    if (pickedDate != null) {
      // pickedDate - это локальная дата (полночь) выбранного дня.
      // Создаем DateTime в UTC для этой же даты.
      dialogSelectedDueDate.value = DateTime.utc(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
      print("Dialog Due Date set to (UTC): ${dialogSelectedDueDate.value}");
    }
  }

  // --- Метод для выбора исполнителей в диалоге ---
  void pickDialogAssignees() async {
    if (!_contactsController.initialized ||
        _contactsController.isLoading.value) {
      Get.snackbar('Загрузка', 'Список контактов еще не готов...');
      return;
    }
    if (_contactsController.contacts.isEmpty) {
      Get.snackbar('Нет контактов', 'Не найдено контактов для назначения.');
      return;
    }

    final Contact? selectedContact = await Get.dialog<Contact>(
      SingleAssigneeSelectionDialog(
        initialSelectedContact: dialogSelectedAssignee.value,
        availableContacts: _contactsController.contacts,
      ),
    );

    dialogSelectedAssignee.value = selectedContact;
    dialogSelectedAssigneeId.value = selectedContact?.id;

    print(
      "[TasksController] Selected assignee: ${selectedContact?.username ?? 'None'} (ID: ${selectedContact?.id})",
    );
  }

  // Сохранение из диалога
  Future<void> saveTaskFromDialog() async {
    if (!dialogFormKey.currentState!.validate()) {
      return;
    }

    isDialogLoading.value = true;
    dialogErrorMessage.value = null;

    try {
      bool success;
      if (isDialogEditing) {
        final updateData = <String, dynamic>{
          'title': titleDialogController.text,
          'description':
              descriptionDialogController.text.isNotEmpty
                  ? descriptionDialogController.text
                  : null,
          'status': dialogSelectedStatus.value,
          'priority': dialogSelectedPriority.value,
          'assignee_id': dialogSelectedAssigneeId.value,
          'due_date': dialogSelectedDueDate.value?.toIso8601String(),
        };
        success = await updateTask(dialogEditingTaskId.value!, updateData);
      } else {
        success = await createTask(
          title: titleDialogController.text,
          description:
              descriptionDialogController.text.isNotEmpty
                  ? descriptionDialogController.text
                  : null,
          status: dialogSelectedStatus.value,
          priority: dialogSelectedPriority.value,
          assigneeId: dialogSelectedAssigneeId.value,
          dueDate: dialogSelectedDueDate.value,
        );
      }

      if (success) {
        Get.back();
        Get.snackbar(
          'Успех',
          isDialogEditing ? 'Задача обновлена' : 'Задача создана',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print("Error in saveTaskFromDialog: $e");
      dialogErrorMessage.value = "Произошла ошибка: ${e.toString()}";
    } finally {
      isDialogLoading.value = false;
    }
  }

  // Метод для получения цвета пользователя (теперь без ChatsController)
  Color getUserColor(String userId) {
    // Генерируем цвет на основе ID пользователя
    final hash = userId.hashCode;
    final hue = (hash % 360).abs();
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.7, 0.5).toColor();
  }

  @override
  void onClose() {
    taskList.close();
    tasksByStatus.close();
    isLoading.close();
    errorMessage.close();
    searchTerm.close();
    assignedToMeFilter.close();
    isDialogLoading.close();
    dialogErrorMessage.close();
    dialogEditingTaskId.close();
    titleDialogController.dispose();
    descriptionDialogController.dispose();
    dialogSelectedStatus.close();
    dialogSelectedPriority.close();
    dialogSelectedDueDate.close();
    dialogSelectedAssigneeId.close();
    dialogSelectedAssignee.close();
    updatingTaskIds.close();
    isUpdatingStatus.close();
    super.onClose();
  }
}
