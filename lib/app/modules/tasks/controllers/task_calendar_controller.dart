import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vka_chat_ng/app/data/models/task_model.dart';
import 'tasks_controller.dart'; // Для доступа к задачам
import 'package:collection/collection.dart'; // Для groupBy
import 'package:vka_chat_ng/app/data/models/contact_model.dart'; // <-- Добавляем импорт

// --- НОВОЕ: Enum для группировки ---
enum CalendarTaskGroupBy {
  none, // Без группировки
  priority, // По приоритету
  status, // По статусу
}
// ---------------------------------

class TaskCalendarController extends GetxController {
  // Получаем доступ к основному контроллеру задач
  final TasksController _tasksController = Get.find<TasksController>();

  // --- НОВОЕ: Переменная для хранения Worker'а слушателя ---
  Worker? _taskListWorker;
  // ------------------------------------------------------

  // Состояние календаря
  final Rx<DateTime> focusedDay = DateTime.now().obs;
  final Rxn<DateTime> selectedDay = Rxn<DateTime>(null);

  // --- Данные для календаря ---
  final RxMap<DateTime, List<TaskModel>> tasksByDueDate =
      <DateTime, List<TaskModel>>{}.obs;

  // --- Фильтры для календаря ---
  final RxList<int> calendarPriorityFilter = <int>[].obs;
  final RxnString calendarCreatorFilter = RxnString();
  final RxnString calendarAssigneeFilter = RxnString();
  // -----------------------------

  // --- Группировка для списка задач ---
  final Rx<CalendarTaskGroupBy> calendarGroupBy = CalendarTaskGroupBy.none.obs;
  // ------------------------------------

  // --- Список задач для выбранного дня (отфильтрованный и сгруппированный) ---
  final RxList<TaskModel> _selectedDayTasksRaw =
      <TaskModel>[].obs; // Неотфильтрованные задачи на день
  final RxMap<String, List<TaskModel>> groupedSelectedDayTasks =
      <String, List<TaskModel>>{}.obs;
  // -----------------------------------------------------------------------

  // --- Геттер для проверки активности фильтров ---
  bool get isAnyCalendarFilterActive =>
      calendarPriorityFilter.isNotEmpty ||
      calendarCreatorFilter.value != null ||
      calendarAssigneeFilter.value != null;
  // ---------------------------------------------

  @override
  void onInit() {
    super.onInit();
    // Устанавливаем выбранный день на сегодня при инициализации
    selectedDay.value = _normalizeDate(DateTime.now());
    _updateTasksByDueDate(); // Загружаем и группируем все задачи по датам
    _applyFiltersAndGrouping(); // Применяем фильтры/группировку к выбранному дню
    // Следим за изменениями в основном списке задач
    _taskListWorker = ever(_tasksController.taskList, (_) {
      _updateTasksByDueDate();
      _applyFiltersAndGrouping();
    });
    // Следим за изменениями фильтров/группировки в TasksController, если нужно
    // ever(_tasksController.priorityFilter, (_) => _applyFiltersAndGrouping()); // Пример
  }

  // Нормализация даты (убираем время, оставляем только год, месяц, день в UTC)
  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  // Метод для обновления карты tasksByDueDate из основного списка
  void _updateTasksByDueDate() {
    print("CalendarController: Updating tasksByDueDate map...");
    final newMap = <DateTime, List<TaskModel>>{};
    for (final task in _tasksController.taskList) {
      if (task.dueDate != null) {
        final normalizedDate = _normalizeDate(task.dueDate!);
        if (newMap.containsKey(normalizedDate)) {
          newMap[normalizedDate]!.add(task);
        } else {
          newMap[normalizedDate] = [task];
        }
      }
    }
    tasksByDueDate.assignAll(
      newMap,
    ); // Используем assignAll для обновления RxMap
    print(
      "CalendarController: tasksByDueDate updated. Count: ${tasksByDueDate.length}",
    );
    // Загружаем сырые данные для текущего выбранного дня
    _loadRawTasksForSelectedDay();
  }

  // Загрузка НЕОТФИЛЬТРОВАННЫХ задач для выбранного дня
  void _loadRawTasksForSelectedDay() {
    if (selectedDay.value != null) {
      final normalizedSelectedDay = _normalizeDate(selectedDay.value!);
      _selectedDayTasksRaw.assignAll(
        tasksByDueDate[normalizedSelectedDay] ?? [],
      );
      print(
        "CalendarController: Loaded ${_selectedDayTasksRaw.length} raw tasks for ${selectedDay.value}",
      );
    } else {
      _selectedDayTasksRaw.clear();
      print("CalendarController: Cleared raw tasks, no day selected.");
    }
  }

  // --- НОВЫЙ МЕТОД: Применение фильтров и группировки к _selectedDayTasksRaw ---
  void _applyFiltersAndGrouping() {
    List<TaskModel> filteredTasks =
        _selectedDayTasksRaw.where((task) {
          bool passesFilter = true;
          // Фильтр по приоритету
          if (calendarPriorityFilter.isNotEmpty &&
              !calendarPriorityFilter.contains(task.priority)) {
            passesFilter = false;
          }
          // Фильтр по создателю
          if (passesFilter &&
              calendarCreatorFilter.value != null &&
              task.creatorId != calendarCreatorFilter.value) {
            passesFilter = false;
          }
          // Фильтр по исполнителю
          if (passesFilter &&
              calendarAssigneeFilter.value != null &&
              task.assigneeId != calendarAssigneeFilter.value) {
            passesFilter = false;
          }
          return passesFilter;
        }).toList();

    // Сортировка (можно использовать ту же логику, что и в TasksController, если нужно)
    // filteredTasks.sort((a, b) => _compareTasks(a, b)); // Пример

    // Группировка
    final Map<String, List<TaskModel>> groupedMap = {};
    if (calendarGroupBy.value == CalendarTaskGroupBy.none) {
      if (filteredTasks.isNotEmpty) {
        groupedMap['Задачи'] = filteredTasks; // Одна группа по умолчанию
      }
    } else if (calendarGroupBy.value == CalendarTaskGroupBy.priority) {
      groupedMap.addAll(
        groupBy(filteredTasks, (TaskModel task) {
          // Используем маппинг из TasksController для имени приоритета
          return 'Приоритет: ${_tasksController.priorityOptions[task.priority] ?? task.priority.toString()}';
        }),
      );
      // Опционально: сортируем группы по ключу (например, по приоритету 1, 2, 3)
      // groupedMap = Map.fromEntries(groupedMap.entries.toList()..sort(...));
    } else if (calendarGroupBy.value == CalendarTaskGroupBy.status) {
      groupedMap.addAll(
        groupBy(filteredTasks, (TaskModel task) {
          // Можно создать хелпер для локализации статуса
          return 'Статус: ${_localizeStatus(task.status)}';
        }),
      );
      // Опционально: сортируем группы по статусу (open, in_progress, ...)
    }

    groupedSelectedDayTasks.assignAll(groupedMap);
    print(
      "CalendarController: Applied filters & grouping. Result groups: ${groupedSelectedDayTasks.keys.length}",
    );
  }
  // ----------------------------------------------------------------------

  // --- Вспомогательные методы для получения данных из TasksController ---
  Map<int, String> get priorityOptions => _tasksController.priorityOptions;
  List<Contact> get availableCreators => _tasksController.availableCreators;
  List<Contact> get availableAssignees {
    // Получаем всех контактов как возможных исполнителей
    if (!_tasksController.initialized) return [];
    return _tasksController.allContacts;
  }

  String? getContactUsernameById(String userId) =>
      _tasksController.getContactUsernameById(userId);
  // ------------------------------------------------------------------

  // Получение списка "событий" (задач) для дня (для eventLoader)
  List<TaskModel> getEventsForDay(DateTime day) {
    final normalizedDay = _normalizeDate(day);
    // Получаем все задачи на этот день
    final tasksForDay = tasksByDueDate[normalizedDay] ?? [];

    // Применяем текущие фильтры календаря
    final filteredTasks =
        tasksForDay.where((task) {
          bool passesFilter = true;
          // Фильтр по приоритету
          if (calendarPriorityFilter.isNotEmpty &&
              !calendarPriorityFilter.contains(task.priority)) {
            passesFilter = false;
          }
          // Фильтр по создателю
          if (passesFilter &&
              calendarCreatorFilter.value != null &&
              task.creatorId != calendarCreatorFilter.value) {
            passesFilter = false;
          }
          // Фильтр по исполнителю
          if (passesFilter &&
              calendarAssigneeFilter.value != null &&
              task.assigneeId != calendarAssigneeFilter.value) {
            passesFilter = false;
          }
          return passesFilter;
        }).toList();

    return filteredTasks; // Возвращаем отфильтрованный список
  }

  // Обработка выбора дня
  void onDaySelected(DateTime newSelectedDay, DateTime newFocusedDay) {
    final normalizedSelectedDay = _normalizeDate(newSelectedDay);
    if (!isSameDay(selectedDay.value, normalizedSelectedDay)) {
      print("CalendarController: Day selected: $normalizedSelectedDay");
      selectedDay.value = normalizedSelectedDay;
      focusedDay.value = _normalizeDate(
        newFocusedDay,
      ); // Фокусируемся на выбранном дне
      _loadRawTasksForSelectedDay(); // Загружаем сырые данные
      _applyFiltersAndGrouping(); // Применяем фильтры/группировку
    }
  }

  // Обработка смены страницы (месяца)
  void onPageChanged(DateTime newFocusedDay) {
    focusedDay.value = _normalizeDate(newFocusedDay);
  }

  // --- Методы для установки фильтров/группировки ---
  void setCalendarPriorityFilter(List<int> priorities) {
    if (calendarPriorityFilter.length != priorities.length ||
        !calendarPriorityFilter.every(priorities.contains)) {
      calendarPriorityFilter.assignAll(priorities);
      _applyFiltersAndGrouping();
    }
  }

  void setCalendarCreatorFilter(String? creatorId) {
    if (calendarCreatorFilter.value != creatorId) {
      calendarCreatorFilter.value = creatorId;
      _applyFiltersAndGrouping();
    }
  }

  void setCalendarAssigneeFilter(String? assigneeId) {
    if (calendarAssigneeFilter.value != assigneeId) {
      calendarAssigneeFilter.value = assigneeId;
      _applyFiltersAndGrouping();
    }
  }

  void setCalendarGroupBy(CalendarTaskGroupBy groupBy) {
    if (calendarGroupBy.value != groupBy) {
      calendarGroupBy.value = groupBy;
      _applyFiltersAndGrouping(); // Перегруппировываем существующие отфильтрованные задачи
    }
  }

  void clearCalendarFiltersAndGrouping() {
    bool changed = false;
    if (calendarPriorityFilter.isNotEmpty) {
      calendarPriorityFilter.clear();
      changed = true;
    }
    if (calendarCreatorFilter.value != null) {
      calendarCreatorFilter.value = null;
      changed = true;
    }
    if (calendarAssigneeFilter.value != null) {
      calendarAssigneeFilter.value = null;
      changed = true;
    }
    if (calendarGroupBy.value != CalendarTaskGroupBy.none) {
      calendarGroupBy.value = CalendarTaskGroupBy.none;
      changed = true;
    }

    if (changed) {
      _applyFiltersAndGrouping();
    }
  }
  // --------------------------------------------------

  // --- Вспомогательная функция локализации статуса (можно взять из TasksView) ---
  String _localizeStatus(String status) {
    switch (status) {
      case 'open':
        return 'Открытые';
      case 'in_progress':
        return 'В работе';
      case 'done':
        return 'Готово';
      case 'closed':
        return 'Закрытые';
      default:
        return status.capitalizeFirst ?? status;
    }
  }

  @override
  void onClose() {
    // Закрываем Rx переменные
    focusedDay.close();
    selectedDay.close();
    tasksByDueDate.close();
    calendarPriorityFilter.close();
    calendarCreatorFilter.close();
    calendarAssigneeFilter.close();
    calendarGroupBy.close();
    _selectedDayTasksRaw.close();
    groupedSelectedDayTasks.close();

    // --- НОВОЕ: Отменяем подписку ---
    _taskListWorker?.dispose();
    // ---------------------------------

    super.onClose();
  }
}
