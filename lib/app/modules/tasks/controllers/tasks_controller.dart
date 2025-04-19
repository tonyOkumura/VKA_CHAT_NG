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
import 'dart:collection'; // Для LinkedHashMap
import 'package:vka_chat_ng/app/services/socket_service.dart';

// --- НОВОЕ: Enum для полей сортировки ---
enum TaskSortField {
  priority, // По приоритету (сначала высокий)
  createdAt, // По дате создания (сначала новые)
  dueDate, // По сроку выполнения (сначала ближайшие)
  title, // По названию (А-Я)
}

// --- НОВОЕ: Enum для направления сортировки ---
enum SortDirection {
  ascending, // По возрастанию (А-Я, 0-9, старые-новые, низкий-высокий)
  descending, // По убыванию (Я-А, 9-0, новые-старые, высокий-низкий)
}
// ------------------------------------------

class TasksController extends GetxController {
  final TaskApiService _apiService = Get.find<TaskApiService>();
  late final ContactsController _contactsController;
  final _storage = const FlutterSecureStorage(); // <-- Экземпляр Secure Storage
  late String currentUserId; // <-- ID текущего пользователя
  // --- НОВОЕ: Добавляем SocketService ---
  late final SocketService _socketService;
  // -----------------------------------

  // --- Основное состояние ---
  final RxList<TaskModel> taskList =
      <TaskModel>[].obs; // Полный список с сервера
  // --- ИЗМЕНЕНО: Используем LinkedHashMap, чтобы сохранить порядок статусов ---
  final RxMap<String, RxList<TaskModel>> tasksByStatus = RxMap.of(
    LinkedHashMap<String, RxList<TaskModel>>.from({
      'open': <TaskModel>[].obs,
      'in_progress': <TaskModel>[].obs,
      'done': <TaskModel>[].obs,
      'closed': <TaskModel>[].obs,
    }),
  );
  // -----------------------------------------------------------------------
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString(null);
  // --- Фильтры ---
  final RxnString searchTerm = RxnString(null);
  final RxBool assignedToMeFilter = false.obs; // <-- Фильтр "Назначенные мне"
  // --- НОВЫЕ ФИЛЬТРЫ ---
  final RxList<int> priorityFilter =
      <int>[].obs; // Список выбранных приоритетов
  final RxnString creatorFilter = RxnString(); // ID выбранного создателя
  // --------------------

  // --- НОВАЯ СОРТИРОВКА ---
  final Rx<TaskSortField> sortField =
      TaskSortField.priority.obs; // По умолчанию по приоритету
  final Rx<SortDirection> sortDirection =
      SortDirection.ascending.obs; // По умолчанию по возрастанию (1, 2, 3)
  // ----------------------

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
  // --- ИЗМЕНЕНО: Используем ключи из tasksByStatus ---
  List<String> get statusOptions => tasksByStatus.keys.toList();
  // -------------------------------------------------
  final Map<int, String> priorityOptions = {
    1: 'Высокий',
    2: 'Средний',
    3: 'Низкий',
  };
  // --- НОВОЕ: Список контактов для фильтра по создателю ---
  List<Contact> get availableCreators {
    // Убедимся, что _contactsController инициализирован
    if (!Get.isRegistered<ContactsController>() ||
        !_contactsController.initialized) {
      return [];
    }
    final creatorIds = taskList.map((t) => t.creatorId).toSet();
    return _contactsController.contacts
        .where((c) => creatorIds.contains(c.id))
        .toList();
  }
  // -------------------------------------------------

  // --- НОВОЕ: Геттер для получения всех контактов ---
  List<Contact> get allContacts {
    if (!Get.isRegistered<ContactsController>() ||
        !_contactsController.initialized) {
      return [];
    }
    return _contactsController.contacts;
  }
  // -----------------------------------------------

  bool get isDialogEditing => dialogEditingTaskId.value != null;

  final RxBool isUpdatingStatus = false.obs; // Индикатор загрузки для статуса
  final RxSet<String> updatingTaskIds =
      <String>{}.obs; // Хранить ID задач в процессе обновления

  // --- НОВОЕ: Геттер для проверки, активны ли какие-либо фильтры/сортировка ---
  bool get isAnyFilterOrSortActive {
    return searchTerm.value != null ||
        assignedToMeFilter.value ||
        priorityFilter.isNotEmpty ||
        creatorFilter.value != null ||
        sortField.value !=
            TaskSortField.priority || // Если не дефолтная сортировка
        sortDirection.value != SortDirection.ascending;
  }
  // -------------------------------------------------------------------------

  @override
  void onInit() async {
    // --- ОТЛАДКА: Логирование Init ---
    print("TasksController[${this.hashCode}]: onInit START");
    // ----------------------------------
    super.onInit();
    // --- НОВОЕ: Инициализируем SocketService ---
    _socketService = Get.find<SocketService>();
    // ------------------------------------------
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
    await _initializeContactsController(); // Вынесли в отдельный метод

    // Инициализируем карту статусов пустыми списками
    for (var status in statusOptions) {
      tasksByStatus[status] = <TaskModel>[].obs;
    }

    fetchTasks(); // Загружаем задачи
    // --- ОТЛАДКА: Логирование Init ---
    print("TasksController[${this.hashCode}]: onInit END");
    // --- НОВОЕ: Присоединяемся к комнате задач ---
    _socketService.joinTasksRoom();
    // --------------------------------------------
  }

  // --- НОВОЕ: Метод для инициализации ContactsController ---
  Future<void> _initializeContactsController() async {
    if (Get.isRegistered<ContactsController>()) {
      _contactsController = Get.find<ContactsController>();
      print("TasksController: Found existing ContactsController.");
      // Проверяем, инициализирован ли контроллер и пуст ли список
      if (!_contactsController.initialized &&
          !_contactsController.isLoading.value) {
        print(
          "TasksController: Existing ContactsController not initialized. Fetching...",
        );
        try {
          await _contactsController.fetchContacts();
        } catch (e) {
          print(
            "Error fetching contacts during init (existing controller): $e",
          );
        }
      } else if (_contactsController.initialized &&
          _contactsController.contacts.isEmpty) {
        print("TasksController: Contacts list is empty, fetching again...");
        try {
          await _contactsController.fetchContacts();
        } catch (e) {
          print(
            "Error fetching contacts during init (existing controller, empty list): $e",
          );
        }
      }
    } else {
      print(
        "TasksController: ContactsController not found, creating and fetching...",
      );
      _contactsController = Get.put(ContactsController());
      try {
        await _contactsController.fetchContacts();
      } catch (e) {
        print("Error fetching contacts during init (controller created): $e");
      }
    }
    // Добавим слушатель, чтобы обновить availableCreators при обновлении контактов
    // Используем `once` или `ever` в зависимости от необходимости
    // ever(_contactsController.contacts, (_) => update(['creators_filter'])); // Если используете GetBuilder ID
  }
  // ------------------------------------------------------

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
      // Убедимся, что контакты загружены перед фильтрацией по создателю
      if (!_contactsController.initialized) {
        await _initializeContactsController();
      }
      // --- Проверка перед вызовом API ---
      if (isClosed) return;
      final tasks = await _apiService.getTasks();
      // --- Проверка после API перед обновлением состояния ---
      if (isClosed) return;
      taskList.assignAll(tasks);
      _applyFiltersAndSort(); // Применяем фильтры и сортировку
    } catch (e) {
      print("Error in TasksController fetchTasks: $e");
      // --- Проверка перед обновлением состояния в catch ---
      if (isClosed) return;
      errorMessage.value = "Ошибка загрузки задач: ${e.toString()}";
      taskList.clear();
      tasksByStatus.forEach((key, list) => list.clear());
    } finally {
      // --- Проверка перед обновлением состояния в finally ---
      if (isClosed) return;
      if (showLoading) isLoading.value = false;
    }
  }

  // --- ОБНОВЛЕННЫЙ МЕТОД: Фильтрация и Сортировка ---
  void _applyFiltersAndSort() {
    final String? search = searchTerm.value?.toLowerCase();
    final bool assignedToMe = assignedToMeFilter.value;
    final List<int> priorities = priorityFilter;
    final String? creatorId = creatorFilter.value;

    // Создаем временную карту для новых отфильтрованных списков
    final Map<String, List<TaskModel>> tempTasksByStatus = {};
    for (var status in statusOptions) {
      tempTasksByStatus[status] = [];
    }

    // 1. Фильтрация
    for (var task in taskList) {
      bool passesFilter = true;

      // Фильтр "Назначенные мне"
      if (assignedToMe && task.assigneeId != currentUserId) {
        passesFilter = false;
      }
      // Фильтр по Приоритету
      if (passesFilter &&
          priorities.isNotEmpty &&
          !priorities.contains(task.priority)) {
        passesFilter = false;
      }
      // Фильтр по Создателю
      if (passesFilter && creatorId != null && task.creatorId != creatorId) {
        passesFilter = false;
      }
      // Фильтр по Поиску (текст)
      if (passesFilter && search != null && search.isNotEmpty) {
        final titleMatch = task.title.toLowerCase().contains(search);
        final descriptionMatch =
            task.description?.toLowerCase().contains(search) ?? false;
        final assigneeMatch =
            task.assigneeUsername?.toLowerCase().contains(search) ?? false;
        final creatorMatch =
            task.creatorUsername?.toLowerCase().contains(search) ?? false;
        // Можно добавить поиск по ID
        // final idMatch = task.id.toLowerCase().contains(search);
        if (!(titleMatch ||
            descriptionMatch ||
            assigneeMatch ||
            creatorMatch)) {
          passesFilter = false;
        }
      }

      // Добавляем задачу в соответствующий статус, если она прошла фильтры
      if (passesFilter) {
        if (tempTasksByStatus.containsKey(task.status)) {
          tempTasksByStatus[task.status]!.add(task);
        } else {
          // Обработка случая, если статус задачи не соответствует стандартным колонкам
          print(
            "Warning: Task ${task.id} has unknown status '${task.status}'. Not adding to board.",
          );
          // Можно добавить в какую-то "прочую" колонку, если нужно
        }
      }
    }

    // 2. Сортировка внутри каждой группы статуса
    tempTasksByStatus.forEach((status, list) {
      list.sort((a, b) => _compareTasks(a, b));
    });

    // Обновляем реактивные списки в tasksByStatus
    tasksByStatus.forEach((status, reactiveList) {
      reactiveList.assignAll(tempTasksByStatus[status]!);
    });

    print(
      "Filters and Sort applied. Sort: ${sortField.value} ${sortDirection.value}. Counts: ${tasksByStatus.map((k, v) => MapEntry(k, v.length))}",
    );
    // Обновляем список доступных создателей после фильтрации
    // Это гарантирует, что список актуален, но может быть избыточно часто
    update(['creators_list']); // Обновляем GetBuilder с ID 'creators_list' в UI
  }

  // --- НОВЫЙ МЕТОД: Сравнение задач для сортировки ---
  int _compareTasks(TaskModel a, TaskModel b) {
    int comparison;
    switch (sortField.value) {
      case TaskSortField.priority:
        // Приоритет: Меньшее число = выше приоритет. Для восходящей сортировки нужно сравнить b с a.
        comparison = a.priority.compareTo(b.priority);
        // Если нужно сначала ВЫСОКИЙ (1), то нужно инвертировать или использовать SortDirection.descending по умолчанию
        // Стандартный compareTo (1 vs 2) -> -1. (1 vs 3) -> -1. (2 vs 3) -> -1.
        // ascending (1, 2, 3) - сначала высокий
        // descending (3, 2, 1) - сначала низкий
        break;
      case TaskSortField.createdAt:
        // ascending: старые -> новые
        // descending: новые -> старые
        comparison = a.createdAt.compareTo(b.createdAt);
        break;
      case TaskSortField.dueDate:
        // ascending: без даты -> ближайшие -> далекие
        // descending: далекие -> ближайшие -> без даты
        if (a.dueDate == null && b.dueDate == null) {
          comparison = 0;
        } else if (a.dueDate == null) {
          comparison = 1; // null больше (в конец при ascending)
        } else if (b.dueDate == null) {
          comparison = -1; // не null меньше (в начало при ascending)
        } else {
          comparison = a.dueDate!.compareTo(b.dueDate!);
        }
        break;
      case TaskSortField.title:
        // ascending: А -> Я
        // descending: Я -> А
        comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        break;
    }

    // Применяем направление сортировки
    return sortDirection.value == SortDirection.ascending
        ? comparison
        : -comparison;
  }

  // --- Методы для изменения фильтров и сортировки ---

  void searchTasks(String? term) {
    if (searchTerm.value != term) {
      searchTerm.value = term;
      _applyFiltersAndSort();
    }
  }

  void toggleAssignedToMeFilter() {
    assignedToMeFilter.toggle();
    _applyFiltersAndSort();
  }

  // --- НОВЫЕ МЕТОДЫ УПРАВЛЕНИЯ ФИЛЬТРАМИ/СОРТИРОВКОЙ ---
  void setPriorityFilter(List<int> priorities) {
    // Проверяем, изменился ли список, чтобы избежать лишних перерисовок
    if (priorityFilter.length != priorities.length ||
        !priorityFilter.every((p) => priorities.contains(p))) {
      priorityFilter.assignAll(priorities);
      _applyFiltersAndSort();
    }
  }

  void setCreatorFilter(String? creatorId) {
    if (creatorFilter.value != creatorId) {
      creatorFilter.value = creatorId;
      _applyFiltersAndSort();
    }
  }

  void setSort(TaskSortField field, SortDirection direction) {
    bool changed = false;
    if (sortField.value != field) {
      sortField.value = field;
      changed = true;
    }
    if (sortDirection.value != direction) {
      sortDirection.value = direction;
      changed = true;
    }
    if (changed) {
      _applyFiltersAndSort();
    }
  }
  // ------------------------------------------------------

  void clearFilters() {
    bool needsRefilter = false;

    if (searchTerm.value != null) {
      searchTerm.value = null;
      needsRefilter = true;
    }
    if (assignedToMeFilter.value) {
      assignedToMeFilter.value = false;
      needsRefilter = true;
    }
    // --- СБРОС НОВЫХ ФИЛЬТРОВ И СОРТИРОВКИ ---
    if (priorityFilter.isNotEmpty) {
      priorityFilter.clear();
      needsRefilter = true;
    }
    if (creatorFilter.value != null) {
      creatorFilter.value = null;
      needsRefilter = true;
    }
    // Сбрасываем сортировку к дефолтной (по приоритету, высокий сначала)
    // Убедимся, что дефолтная сортировка по приоритету ставит высокий (1) первым
    if (sortField.value != TaskSortField.priority ||
        sortDirection.value != SortDirection.ascending) {
      sortField.value = TaskSortField.priority;
      sortDirection.value = SortDirection.ascending; // ascending: 1, 2, 3
      needsRefilter = true;
    }
    // ------------------------------------------

    if (needsRefilter) {
      _applyFiltersAndSort(); // Применяем фильтры и сортировку
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
    isDialogLoading.value = true; // Устанавливаем флаг загрузки для диалога
    try {
      final newTaskData = <String, dynamic>{
        'title': title,
        'status': status,
        'priority': priority,
      };
      if (description != null && description.isNotEmpty)
        newTaskData['description'] = description;
      if (assigneeId != null) newTaskData['assignee_id'] = assigneeId;
      if (dueDate != null)
        newTaskData['due_date'] = dueDate.toUtc().toIso8601String();

      final createdTask = await _apiService.createTask(newTaskData);
      taskList.add(createdTask);
      _applyFiltersAndSort(); // Обновляем доску
      return true;
    } catch (e) {
      print("Error in TasksController createTask: $e");
      dialogErrorMessage.value = "Ошибка создания задачи: ${e.toString()}";
      return false;
    } finally {
      isDialogLoading.value = false; // Снимаем флаг загрузки
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
        _applyFiltersAndSort();
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
      _applyFiltersAndSort(); // Обновляем колонки доски
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
    final hash = userId.hashCode;
    // Используем более насыщенные и разнообразные цвета
    final hue = (hash % 360).toDouble();
    // --- ИСПРАВЛЕНО: Ограничиваем значения ---
    final saturation = (0.6 + (hash % 10).abs() / 20.0).clamp(0.6, 1.0);
    final lightness = (0.4 + (hash % 20).abs() / 100.0).clamp(0.4, 0.6);
    // ----------------------------------------
    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }

  // --- НОВОЕ: Метод для получения имени контакта по ID ---
  // Используется для отображения имени создателя в UI фильтров
  String? getContactUsernameById(String userId) {
    // Проверяем, инициализирован ли контроллер контактов
    if (!Get.isRegistered<ContactsController>() ||
        !_contactsController.initialized) {
      // Возвращаем только ID, если контакты не загружены
      // Можно также попробовать запустить загрузку контактов здесь, если это необходимо
      print(
        "Warning: ContactsController not initialized in getContactUsernameById for $userId",
      );
      return 'ID: $userId';
    }
    // Ищем контакт в загруженном списке
    return _contactsController.contacts
            .firstWhereOrNull((c) => c.id == userId)
            ?.username ??
        'ID: $userId'; // Возвращаем ID, если не найден
  }

  // --- НОВЫЕ: Обработчики WebSocket событий --- (
  void handleNewTaskCreated(dynamic data) {
    print("[WebSocket] Received newTaskCreated: $data");
    try {
      final newTask = TaskModel.fromJson(data as Map<String, dynamic>);
      // Проверяем, нет ли уже такой задачи (на случай дублирования)
      if (!taskList.any((t) => t.id == newTask.id)) {
        taskList.add(newTask);
        _applyFiltersAndSort();
      }
    } catch (e) {
      print("Error processing newTaskCreated event: $e");
    }
  }

  void handleTaskUpdated(dynamic data) {
    print("[WebSocket] Received taskUpdated: $data");
    try {
      final updatedTask = TaskModel.fromJson(data as Map<String, dynamic>);
      final index = taskList.indexWhere((t) => t.id == updatedTask.id);
      if (index != -1) {
        taskList[index] = updatedTask;
        _applyFiltersAndSort();
      } else {
        // Если задачи нет в списке, возможно, она только что появилась
        // из-за фильтров или была создана другим пользователем.
        // Можно просто добавить ее.
        taskList.add(updatedTask);
        _applyFiltersAndSort();
        print("  Task ${updatedTask.id} not found, added instead.");
      }
    } catch (e) {
      print("Error processing taskUpdated event: $e");
    }
  }

  void handleTaskDeleted(dynamic data) {
    print("[WebSocket] Received taskDeleted: $data");
    try {
      final taskId = data['taskId'] as String?;
      if (taskId != null) {
        // Проверяем, была ли задача в списке *до* удаления
        final taskExists = taskList.any((task) => task.id == taskId);
        if (taskExists) {
          taskList.removeWhere((task) => task.id == taskId);
          _applyFiltersAndSort(); // Обновляем только если что-то удалили
        }
      }
    } catch (e) {
      print("Error processing taskDeleted event: $e");
    }
  }
  // --- КОНЕЦ Обработчики WebSocket событий --- (

  @override
  void onClose() {
    // --- ОТЛАДКА: Логирование Close ---
    print("TasksController[${this.hashCode}]: onClose START");
    // -----------------------------------
    taskList.close();
    tasksByStatus.close();
    isLoading.close();
    errorMessage.close();
    searchTerm.close();
    assignedToMeFilter.close();
    priorityFilter.close();
    creatorFilter.close();
    sortField.close();
    sortDirection.close();
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
    // --- ОТЛАДКА: Логирование Close ---
    print("TasksController[${this.hashCode}]: onClose END");
    // -----------------------------------
  }
}
