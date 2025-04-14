import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vka_chat_ng/app/data/models/task_model.dart';
import 'package:vka_chat_ng/app/routes/app_pages.dart';
import '../controllers/task_calendar_controller.dart';
import '../controllers/tasks_controller.dart';
import 'tasks_view.dart'; // Импортируем для TaskCard и других виджетов, если нужны

class TaskCalendarView extends GetView<TaskCalendarController> {
  const TaskCalendarView({super.key});

  // --- НОВОЕ: Метод для показа BottomSheet ---
  void _showCalendarFilterGroupSheet(BuildContext context) {
    final theme = Theme.of(context);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Заголовок и кнопка сброса ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Фильтры и Группировка',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Кнопка Сброса (показывается если есть фильтры/группировка)
                  Obx(
                    () =>
                        (controller.isAnyCalendarFilterActive ||
                                controller.calendarGroupBy.value !=
                                    CalendarTaskGroupBy.none)
                            ? TextButton.icon(
                              icon: const Icon(Icons.clear_all, size: 18),
                              label: const Text('Сбросить'),
                              onPressed:
                                  controller.clearCalendarFiltersAndGrouping,
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                              ),
                            )
                            : const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Секция Фильтров ---
              Text('Фильтры:', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),

              // -- Фильтр по Приоритету --
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Приоритет:',
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
                ),
              ),
              Obx(
                () => Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children:
                      controller.priorityOptions.entries.map((entry) {
                        final int priorityValue = entry.key;
                        final String priorityName = entry.value;
                        final bool isSelected = controller
                            .calendarPriorityFilter
                            .contains(priorityValue);
                        return FilterChip(
                          label: Text(priorityName),
                          selected: isSelected,
                          onSelected: (selected) {
                            final currentSelection =
                                controller.calendarPriorityFilter.toList();
                            if (selected) {
                              currentSelection.add(priorityValue);
                            } else {
                              currentSelection.remove(priorityValue);
                            }
                            controller.setCalendarPriorityFilter(
                              currentSelection,
                            );
                          },
                          // Стилизация как в TasksView
                          selectedColor: theme.colorScheme.tertiaryContainer,
                          checkmarkColor: theme.colorScheme.onTertiaryContainer,
                          labelStyle: TextStyle(
                            color:
                                isSelected
                                    ? theme.colorScheme.onTertiaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: theme.dividerColor.withOpacity(0.3),
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // -- Фильтр по Создателю --
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Создатель:',
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
                ),
              ),
              _buildCreatorDropdown(context, theme),
              const SizedBox(height: 16),

              // -- Фильтр по Исполнителю --
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Исполнитель:',
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
                ),
              ),
              _buildAssigneeDropdown(context, theme),
              const SizedBox(height: 16),

              // -------------------------
              const Divider(),

              // --- Секция Группировки ---
              Text('Группировать по:', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Obx(
                () => Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children:
                      CalendarTaskGroupBy.values.map((groupBy) {
                        final bool isSelected =
                            controller.calendarGroupBy.value == groupBy;
                        return ChoiceChip(
                          label: Text(_getGroupByName(groupBy)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              controller.setCalendarGroupBy(groupBy);
                            }
                          },
                          selectedColor: theme.colorScheme.secondaryContainer,
                          labelStyle: TextStyle(
                            color:
                                isSelected
                                    ? theme.colorScheme.onSecondaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: theme.dividerColor.withOpacity(0.3),
                          ),
                        );
                      }).toList(),
                ),
              ),
              // --------------------------
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  // --- НОВОЕ: Хелпер для имени группировки ---
  String _getGroupByName(CalendarTaskGroupBy groupBy) {
    switch (groupBy) {
      case CalendarTaskGroupBy.none:
        return 'Без группировки';
      case CalendarTaskGroupBy.priority:
        return 'Приоритету';
      case CalendarTaskGroupBy.status:
        return 'Статусу';
      default:
        return '';
    }
  }
  // ------------------------------------------

  // --- НОВЫЕ: Вспомогательные методы для построения Dropdown-фильтров ---
  Widget _buildCreatorDropdown(BuildContext context, ThemeData theme) {
    // Используем GetBuilder для обновления списка при необходимости
    return GetBuilder<TaskCalendarController>(
      builder: (_) {
        // controller доступен через GetView
        final creators = controller.availableCreators;
        // Добавляем опцию "Все"
        final items = <DropdownMenuItem<String?>>[
          const DropdownMenuItem<String?>(
            value: null,
            child: Text(
              'Все создатели',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          ...creators.map((contact) {
            return DropdownMenuItem<String?>(
              value: contact.id,
              child: Text(
                contact.username ?? contact.id,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ];

        // Добавляем выбранного, если его нет в списке
        final selectedValue = controller.calendarCreatorFilter.value;
        if (selectedValue != null &&
            !creators.any((c) => c.id == selectedValue)) {
          items.add(
            DropdownMenuItem<String?>(
              value: selectedValue,
              child: Text(
                controller.getContactUsernameById(selectedValue) ??
                    'Неизвестный',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return DropdownButtonFormField<String?>(
          value: controller.calendarCreatorFilter.value,
          items: items,
          onChanged: (String? newValue) {
            controller.setCalendarCreatorFilter(newValue);
          },
          decoration: _dropdownDecoration(theme, hint: 'Выберите создателя'),
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
          isExpanded: true,
        );
      },
    );
  }

  Widget _buildAssigneeDropdown(BuildContext context, ThemeData theme) {
    // Используем GetBuilder для обновления списка при необходимости
    return GetBuilder<TaskCalendarController>(
      builder: (_) {
        // controller доступен через GetView
        final assignees = controller.availableAssignees;
        // Добавляем опцию "Все"
        final items = <DropdownMenuItem<String?>>[
          const DropdownMenuItem<String?>(
            value: null,
            child: Text(
              'Все исполнители',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          ...assignees.map((contact) {
            return DropdownMenuItem<String?>(
              value: contact.id,
              child: Text(
                contact.username ?? contact.id,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ];

        // Добавляем выбранного, если его нет в списке
        final selectedValue = controller.calendarAssigneeFilter.value;
        if (selectedValue != null &&
            !assignees.any((c) => c.id == selectedValue)) {
          items.add(
            DropdownMenuItem<String?>(
              value: selectedValue,
              child: Text(
                controller.getContactUsernameById(selectedValue) ??
                    'Неизвестный',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return DropdownButtonFormField<String?>(
          value: controller.calendarAssigneeFilter.value,
          items: items,
          onChanged: (String? newValue) {
            controller.setCalendarAssigneeFilter(newValue);
          },
          decoration: _dropdownDecoration(theme, hint: 'Выберите исполнителя'),
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
          isExpanded: true,
        );
      },
    );
  }

  // Хелпер для декорации Dropdown
  InputDecoration _dropdownDecoration(ThemeData theme, {String? hint}) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
    );
  }
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLargeScreen =
        MediaQuery.of(context).size.width > 600; // Определяем размер экрана

    return Scaffold(
      appBar: AppBar(
        title: const Text('Календарь задач'),
        centerTitle: true,
        actions: [
          // --- НОВАЯ КНОПКА Фильтры/Группировка ---
          Obx(
            () => IconButton(
              // Используем Stack для добавления значка-индикатора
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.filter_list),
                  // Показываем точку, если активны фильтры или группировка
                  if (controller.isAnyCalendarFilterActive ||
                      controller.calendarGroupBy.value !=
                          CalendarTaskGroupBy.none)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => _showCalendarFilterGroupSheet(context),
              tooltip: 'Фильтры и группировка',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Get.find<TasksController>().fetchTasks(),
            tooltip: 'Обновить задачи',
          ),
        ],
      ),
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
                  () {
                    // --- Читаем фильтры, чтобы Obx среагировал на их изменения ---
                    controller.calendarPriorityFilter.length;
                    controller.calendarCreatorFilter.value;
                    controller.calendarAssigneeFilter.value;
                    // ----------------------------------------------------------
                    return TableCalendar<TaskModel>(
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
                          color: theme.colorScheme.secondaryContainer
                              .withOpacity(0.5),
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
                    );
                  },
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
                      if (controller.groupedSelectedDayTasks.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              controller.selectedDay.value == null
                                  ? 'Нажмите на дату в календаре слева для просмотра задач.'
                                  : controller.isAnyCalendarFilterActive
                                  ? 'Задачи с такими фильтрами не найдены.'
                                  : 'На выбранный день задач нет.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      final groupKeys =
                          controller.groupedSelectedDayTasks.keys.toList();
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        itemCount: groupKeys.length,
                        itemBuilder: (context, groupIndex) {
                          final groupKey = groupKeys[groupIndex];
                          final tasksInGroup =
                              controller.groupedSelectedDayTasks[groupKey]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (groupKey != 'Задачи')
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 12.0,
                                    bottom: 4.0,
                                    left: 4.0,
                                  ),
                                  child: Text(
                                    groupKey,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ),
                              ...tasksInGroup
                                  .map(
                                    (task) => TaskCard(
                                      task: task,
                                      onTap:
                                          () => Get.toNamed(
                                            Routes.TASK_DETAILS,
                                            arguments: task.id,
                                          ),
                                    ),
                                  )
                                  .toList(),
                            ],
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
