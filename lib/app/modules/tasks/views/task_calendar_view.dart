import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vka_chat_ng/app/data/models/task_model.dart';
import 'package:vka_chat_ng/app/routes/app_pages.dart';
import '../controllers/task_calendar_controller.dart';
import 'tasks_view.dart'; // Импортируем для TaskCard и других виджетов, если нужны

class TaskCalendarView extends GetView<TaskCalendarController> {
  const TaskCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLargeScreen =
        MediaQuery.of(context).size.width > 600; // Определяем размер экрана

    return Scaffold(
      appBar: AppBar(title: const Text('Календарь задач'), centerTitle: true),
      // --- Используем Row для разделения экрана ---
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Выравнивание по верху
        children: [
          // --- ЛЕВАЯ ЧАСТЬ: Календарь ---
          SizedBox(
            // Ограничиваем ширину календаря
            width:
                isLargeScreen
                    ? 350
                    : MediaQuery.of(context).size.width, // Адаптивная ширина
            child: Card(
              // Обернем в Card для фона и тени
              margin: const EdgeInsets.all(12.0),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: 8.0,
                ), // Отступ снизу внутри Card
                child: Obx(
                  // Обновляем календарь при изменении данных
                  () => TableCalendar<TaskModel>(
                    locale: 'ru_RU',
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: controller.focusedDay.value,
                    calendarFormat: CalendarFormat.month,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Месяц',
                    },
                    selectedDayPredicate: (day) {
                      return isSameDay(controller.selectedDay.value, day);
                    },
                    onDaySelected: controller.onDaySelected,
                    onPageChanged: controller.onPageChanged,
                    eventLoader: controller.getEventsForDay,

                    // --- Стилизация ---
                    calendarStyle: CalendarStyle(
                      markerDecoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      markersAlignment: Alignment.bottomCenter,
                      markerSize: 5.0,
                      todayDecoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withOpacity(
                          0.5,
                        ),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: TextStyle(
                        color: theme.colorScheme.onPrimary,
                      ),
                      weekendTextStyle: TextStyle(
                        color: theme.colorScheme.error.withOpacity(0.7),
                      ),
                      outsideDaysVisible: false,
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle:
                          theme.textTheme.titleMedium ?? const TextStyle(),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isNotEmpty) {
                          return Positioned(
                            right: 1,
                            bottom: 1,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary.withOpacity(
                                  0.8,
                                ), // Чуть прозрачнее
                              ),
                              child: Center(
                                child: Text(
                                  '${events.length}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- Вертикальный разделитель (опционально) ---
          if (isLargeScreen) const VerticalDivider(width: 1, thickness: 1),

          // --- ПРАВАЯ ЧАСТЬ: Список задач ---
          if (isLargeScreen) // Показываем справа только на больших экранах
            Expanded(
              child: Column(
                // Используем Column для заголовка и списка
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Заголовок для списка задач ---
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 20.0,
                      left: 16.0,
                      right: 16.0,
                      bottom: 8.0,
                    ),
                    child: Obx(
                      () => Text(
                        controller.selectedDay.value == null
                            ? 'Выберите день'
                            : 'Задачи на ${DateFormat('dd MMMM yyyy', 'ru').format(controller.selectedDay.value!)}:',
                        style: theme.textTheme.titleLarge, // Крупнее заголовок
                      ),
                    ),
                  ),
                  // --- Список ---
                  Expanded(
                    child: Obx(() {
                      if (controller.selectedDayTasks.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              controller.selectedDay.value == null
                                  ? 'Нажмите на дату в календаре слева для просмотра задач.'
                                  : 'На выбранный день задач нет.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        itemCount: controller.selectedDayTasks.length,
                        itemBuilder: (context, index) {
                          final task = controller.selectedDayTasks[index];
                          return TaskCard(
                            // Используем существующий TaskCard
                            task: task,
                            onTap:
                                () => Get.toNamed(
                                  Routes.TASK_DETAILS,
                                  arguments: task.id,
                                ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
