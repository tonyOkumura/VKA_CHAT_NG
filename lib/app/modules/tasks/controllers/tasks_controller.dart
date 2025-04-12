import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // <-- Импорт для Secure Storage
import 'package:vka_chat_ng/app/constants.dart'; // <-- Импорт для AppKeys
import 'package:vka_chat_ng/app/data/models/task_model.dart';
import 'package:vka_chat_ng/app/data/services/task_api_service.dart';
import 'package:vka_chat_ng/app/data/models/contact_model.dart';
import 'package:vka_chat_ng/app/modules/contacts/controllers/contacts_controller.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';
import 'package:vka_chat_ng/app/modules/tasks/widgets/assignee_selection_dialog.dart';
import 'package:vka_chat_ng/app/modules/tasks/widgets/single_assignee_selection_dialog.dart';

class TasksController extends GetxController {
  final TaskApiService _apiService = Get.find<TaskApiService>();
  late final ContactsController _contactsController;
  final _storage = const FlutterSecureStorage(); // <-- Экземпляр Secure Storage
  late String currentUserId; // <-- ID текущего пользователя

  // --- Основное состояние ---
  final RxList<TaskModel> taskList =
      <TaskModel>[].obs; // Полный список с сервера
  final RxList<TaskModel> filteredTaskList =
      <TaskModel>[].obs; // Отфильтрованный список для UI
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString(null);
  // --- Фильтры ---
  final RxnString statusFilter = RxnString(null);
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
        _contactsController.fetchContacts();
      }
    } else {
      print("TasksController: ContactsController not found, creating one.");
      _contactsController = Get.put(ContactsController());
      _contactsController.fetchContacts();
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
    dialogSelectedDueDate.value = task.dueDate?.toLocal();
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
      filteredTaskList.clear();
    } finally {
      if (showLoading) isLoading.value = false;
    }
  }

  // Приватный метод для применения всех клиентских фильтров
  void _applyFilters() {
    final String? status = statusFilter.value;
    final String? search = searchTerm.value?.toLowerCase();
    final bool assignedToMe = assignedToMeFilter.value;

    // Начинаем с полного списка
    List<TaskModel> results = List<TaskModel>.from(taskList);

    // 1. Фильтр по статусу
    if (status != null) {
      results = results.where((task) => task.status == status).toList();
    }

    // 2. Фильтр "Назначенные мне"
    if (assignedToMe) {
      results =
          results.where((task) => task.assigneeId == currentUserId).toList();
    }

    // 3. Фильтр по поиску (название или описание)
    if (search != null && search.isNotEmpty) {
      results =
          results.where((task) {
            final titleMatch = task.title.toLowerCase().contains(search);
            final descriptionMatch =
                task.description?.toLowerCase().contains(search) ?? false;
            final assigneeMatch =
                task.assigneeUsername?.toLowerCase().contains(search) ?? false;
            return titleMatch || descriptionMatch || assigneeMatch;
          }).toList();
    }

    // Обновляем отфильтрованный список
    filteredTaskList.assignAll(results);
  }

  // --- Методы для изменения фильтров ---

  void applyStatusFilter(String? newStatus) {
    if (statusFilter.value != newStatus) {
      statusFilter.value = newStatus;
      _applyFilters(); // Применяем фильтры
    }
  }

  void searchTasks(String? term) {
    // Не вызываем fetchTasks, только фильтруем
    searchTerm.value = term;
    _applyFilters(); // Применяем фильтры
  }

  // Новый метод для фильтра "Назначенные мне"
  void toggleAssignedToMeFilter() {
    assignedToMeFilter.toggle(); // Переключаем значение
    _applyFilters(); // Применяем фильтры
  }

  void clearFilters() {
    bool needsRefilter = false;
    if (statusFilter.value != null) {
      statusFilter.value = null;
      needsRefilter = true;
    }
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

  // --- Методы API для создания/обновления/удаления (без изменений) ---
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

      await _apiService.createTask(newTaskData);
      await fetchTasks(showLoading: false); // Обновляем список после создания
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
      await _apiService.updateTask(taskId, updateData);
      await fetchTasks(showLoading: false);
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
      filteredTaskList.removeWhere(
        (task) => task.id == taskId,
      ); // <-- Обновляем отфильтрованный список
      return true;
    } catch (e) {
      print("Error in TasksController deleteTask: $e");
      errorMessage.value = "Ошибка удаления задачи: ${e.toString()}";
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // --- Методы для диалога ---

  // Выбор даты в диалоге
  Future<void> pickDialogDueDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: dialogSelectedDueDate.value ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (pickedDate != null) {
      dialogSelectedDueDate.value = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
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
        };
        if (dialogSelectedDueDate.value != null) {
          updateData['due_date'] =
              dialogSelectedDueDate.value!.toUtc().toIso8601String();
        } else {
          updateData['due_date'] = null;
        }
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

  // Метод для получения цвета пользователя (копируем или делаем общим)
  Color getUserColor(String userId) {
    // Пытаемся получить цвет из ChatsController, если он есть
    try {
      // Предполагаем, что ChatsController тоже зарегистрирован через GetX
      final chatsController =
          Get.find<ChatsController>(); // Нужен импорт ChatsController
      return chatsController.getUserColor(userId);
    } catch (e) {
      // Если ChatsController не найден или метод не существует, используем запасной вариант
      print(
        "Could not get user color from ChatsController, using fallback: $e",
      );
      // Простой запасной вариант на основе хеша ID
      final List<Color> fallbackColors = [
        Colors.blue,
        Colors.red,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.teal,
      ];
      final colorIndex = userId.hashCode % fallbackColors.length;
      return fallbackColors[colorIndex];
    }
  }

  @override
  void onClose() {
    taskList.close();
    filteredTaskList.close(); // <-- Закрываем новый список
    isLoading.close();
    errorMessage.close();
    statusFilter.close();
    searchTerm.close();
    assignedToMeFilter.close(); // <-- Закрываем новый фильтр
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
    super.onClose();
  }
}
