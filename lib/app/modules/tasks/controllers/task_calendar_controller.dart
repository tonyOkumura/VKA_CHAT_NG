import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vka_chat_ng/app/data/models/task_model.dart';
import 'tasks_controller.dart'; // Для доступа к задачам

class TaskCalendarController extends GetxController {
  // Получаем доступ к основному контроллеру задач
  final TasksController _tasksController = Get.find<TasksController>();

  // Состояние календаря
  final Rx<DateTime> focusedDay = DateTime.now().obs;
  final Rxn<DateTime> selectedDay = Rxn<DateTime>(null);

  // --- Данные для календаря ---
  // Убираем late final и инициализируем сразу
  final RxMap<DateTime, List<TaskModel>> tasksByDueDate =
      <DateTime, List<TaskModel>>{}.obs;

  // --- Список задач для выбранного дня ---
  final RxList<TaskModel> selectedDayTasks = <TaskModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    selectedDay.value = _normalizeDate(DateTime.now());
    _loadTasksForSelectedDay();
    ever(_tasksController.taskList, (_) => _updateTasksByDueDate());
    _updateTasksByDueDate();
  }

  // Нормализация даты (убираем время, оставляем только год, месяц, день)
  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  // Метод для обновления карты tasksByDueDate
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

    // --- ИЗМЕНЕНИЕ: Очищаем и добавляем в существующую карту ---
    tasksByDueDate.clear();
    tasksByDueDate.addAll(newMap);
    // --- КОНЕЦ ИЗМЕНЕНИЯ ---

    // Обновляем задачи и для текущего выбранного дня, если он есть
    _loadTasksForSelectedDay();
    print(
      "CalendarController: tasksByDueDate updated. Count: ${tasksByDueDate.length}",
    );
  }

  // Загрузка задач для выбранного дня
  void _loadTasksForSelectedDay() {
    if (selectedDay.value != null) {
      final normalizedSelectedDay = _normalizeDate(selectedDay.value!);
      selectedDayTasks.assignAll(tasksByDueDate[normalizedSelectedDay] ?? []);
      print(
        "CalendarController: Loaded ${selectedDayTasks.length} tasks for ${selectedDay.value}",
      );
    } else {
      selectedDayTasks.clear();
      print("CalendarController: Cleared tasks, no day selected.");
    }
  }

  // Получение списка "событий" (задач) для дня (для eventLoader)
  List<TaskModel> getEventsForDay(DateTime day) {
    final normalizedDay = _normalizeDate(day);
    // Используем .value, чтобы получить текущее значение RxMap
    return tasksByDueDate.value[normalizedDay] ?? [];
  }

  // Обработка выбора дня
  void onDaySelected(DateTime newSelectedDay, DateTime newFocusedDay) {
    final normalizedSelectedDay = _normalizeDate(newSelectedDay);
    // Сравниваем нормализованные даты
    if (!isSameDay(
      _normalizeDate(selectedDay.value ?? DateTime(0)),
      normalizedSelectedDay,
    )) {
      print("CalendarController: Day selected: $normalizedSelectedDay");
      selectedDay.value = normalizedSelectedDay;
      focusedDay.value = _normalizeDate(newFocusedDay);
      _loadTasksForSelectedDay();
    }
  }

  // Обработка смены страницы (месяца)
  void onPageChanged(DateTime newFocusedDay) {
    focusedDay.value = _normalizeDate(newFocusedDay);
  }
}
