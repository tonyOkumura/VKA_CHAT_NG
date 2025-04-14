import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Для форматирования дат
import 'package:vka_chat_ng/app/modules/tasks/widgets/create_edit_task_dialog_content.dart';
import 'package:vka_chat_ng/app/widgets/main_layout.dart';
import '../controllers/tasks_controller.dart';
import '../../../data/models/task_model.dart'; // TaskModel реализует KanbanBoardGroupItem
import 'package:vka_chat_ng/app/routes/app_pages.dart'; // <-- Добавь импорт роутов
import 'dart:async'; // <-- Импорт для Timer (debounce)
// Для firstWhereOrNull

// ignore: must_be_immutable
class TasksView extends GetView<TasksController> {
  TasksView({super.key});

  // Локальный контроллер для поиска
  final _searchController = TextEditingController();
  // Таймер для debounce поиска
  Timer? _debounce;

  // --- Метод для debounce ---
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Вызываем searchTasks, который теперь только фильтрует
      controller.searchTasks(query.isNotEmpty ? query : null);
    });
  }

  // --- Метод для очистки поиска и фильтра ---
  void _clearSearchAndFilter() {
    _searchController.clear(); // Очищаем поле
    // Вызываем controller.clearFilters, который сбросит все фильтры
    controller.clearFilters();
  }

  // --- НОВОЕ: Метод для показа BottomSheet с фильтрами и сортировкой ---
  void _showFilterSortSheet(BuildContext context) {
    final theme = Theme.of(context);

    // --- Хелперы для названий сортировки ---
    String _getSortFieldDisplayName(TaskSortField field) {
      switch (field) {
        case TaskSortField.priority:
          return 'Приоритету';
        case TaskSortField.createdAt:
          return 'Дате создания';
        case TaskSortField.dueDate:
          return 'Сроку';
        case TaskSortField.title:
          return 'Названию';
        default:
          return '';
      }
    }

    String _getSortDirectionDisplayName(SortDirection direction) {
      switch (direction) {
        case SortDirection.ascending:
          return 'По возрастанию';
        case SortDirection.descending:
          return 'По убыванию';
        default:
          return '';
      }
    }
    // -------------------------------------

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
          // Добавляем прокрутку
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Заголовок BottomSheet ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Фильтры и Сортировка',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- СЕКЦИЯ СОРТИРОВКИ ---
              Text('Сортировать по:', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Obx(
                () => Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children:
                      TaskSortField.values.map((field) {
                        return ChoiceChip(
                          label: Text(_getSortFieldDisplayName(field)),
                          selected: controller.sortField.value == field,
                          onSelected: (selected) {
                            if (selected) {
                              // При выборе нового поля, оставляем текущее направление
                              controller.setSort(
                                field,
                                controller.sortDirection.value,
                              );
                            }
                          },
                          selectedColor: theme.colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color:
                                controller.sortField.value == field
                                    ? theme.colorScheme.onPrimaryContainer
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
              const SizedBox(height: 12),
              Obx(
                () => Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children:
                      SortDirection.values.map((direction) {
                        return ChoiceChip(
                          label: Text(_getSortDirectionDisplayName(direction)),
                          selected: controller.sortDirection.value == direction,
                          onSelected: (selected) {
                            if (selected) {
                              // При выборе направления, оставляем текущее поле
                              controller.setSort(
                                controller.sortField.value,
                                direction,
                              );
                            }
                          },
                          selectedColor: theme.colorScheme.secondaryContainer,
                          labelStyle: TextStyle(
                            color:
                                controller.sortDirection.value == direction
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

              // --- КОНЕЦ СЕКЦИИ СОРТИРОВКИ ---
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // --- СЕКЦИЯ ФИЛЬТРОВ ---
              Text('Фильтры:', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),

              // --- Фильтр по Приоритету ---
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Приоритет:',
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children:
                      controller.priorityOptions.entries.map((entry) {
                        final int priorityValue = entry.key;
                        final String priorityName = entry.value;
                        final bool isSelected = controller.priorityFilter
                            .contains(priorityValue);

                        return FilterChip(
                          label: Text(priorityName),
                          selected: isSelected,
                          onSelected: (selected) {
                            final currentSelection =
                                controller.priorityFilter.toList();
                            if (selected) {
                              currentSelection.add(priorityValue);
                            } else {
                              currentSelection.remove(priorityValue);
                            }
                            controller.setPriorityFilter(currentSelection);
                          },
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

              // --- Добавляем небольшой отступ/разделитель перед следующим фильтром ---
              const SizedBox(height: 8),

              // --- Фильтр по Создателю ---
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Создатель:',
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
                ),
              ),
              const SizedBox(height: 8),
              // Используем GetBuilder для обновления списка создателей, если он изменится
              GetBuilder<TasksController>(
                id: 'creators_list', // ID для обновления из контроллера
                builder: (_) {
                  // Используем (_) т.к. controller уже доступен
                  final creators = controller.availableCreators;
                  if (creators.isEmpty &&
                      controller.creatorFilter.value == null) {
                    // Если нет создателей и фильтр не активен, ничего не показываем
                    // или показываем сообщение типа "Нет создателей для фильтра"
                    return const SizedBox(height: 36); // Placeholder высоты
                  }
                  // Добавляем опцию "Все" вручную
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
                        child: Text(contact.username ?? contact.id),
                      );
                    }).toList(),
                  ];

                  // Если текущий фильтр по создателю, которого нет в списке, временно добавим его
                  // (Например, если список задач обновился и создатель пропал)
                  final selectedValue = controller.creatorFilter.value;
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
                    value:
                        controller
                            .creatorFilter
                            .value, // Текущее значение фильтра
                    items: items,
                    onChanged: (String? newValue) {
                      controller.setCreatorFilter(newValue);
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: BorderSide(
                          color: theme.dividerColor.withOpacity(0.4),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: BorderSide(
                          color: theme.dividerColor.withOpacity(0.4),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                    isExpanded: true, // Растягиваем на всю ширину
                    // hint: const Text('Выберите создателя'),
                  );
                },
              ),

              // ---------------------------
              const SizedBox(height: 20), // Отступ снизу
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
    // print("Show Filter/Sort Bottom Sheet"); // Можно убрать
  }
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Инициализируем поле поиска текущим значением из контроллера (если нужно)
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //    _searchController.text = controller.searchTerm.value ?? '';
    // });

    return MainLayout(
      selectedIndex: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Задачи'),
          centerTitle: true,
          actions: [
            // --- НОВАЯ КНОПКА КАЛЕНДАРЯ ---
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined),
              onPressed: () {
                // Переходим на новый маршрут календаря
                Get.toNamed(Routes.TASK_CALENDAR);
              },
              tooltip: 'Календарь задач',
            ),
            // --- НОВАЯ КНОПКА Фильтры/Сортировка ---
            IconButton(
              icon: const Icon(Icons.filter_list), // Иконка фильтра
              onPressed:
                  () => _showFilterSortSheet(context), // Вызываем BottomSheet
              tooltip: 'Фильтры и сортировка',
            ),
            // --- ИЗМЕНЕНО: Кнопка сброса ---
            Obx(
              () => AnimatedOpacity(
                // Показываем, если активен любой фильтр или нестандартная сортировка
                opacity: controller.isAnyFilterOrSortActive ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child:
                    controller.isAnyFilterOrSortActive
                        ? IconButton(
                          icon: const Icon(Icons.filter_alt_off_outlined),
                          onPressed: _clearSearchAndFilter, // Сбрасывает все
                          tooltip: 'Сбросить фильтры и сортировку',
                        )
                        : const SizedBox.shrink(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => Get.find<TasksController>().fetchTasks(),
              tooltip: 'Обновить задачи',
            ),
          ],
          // Добавляем поле поиска и фильтр под AppBar
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50.0),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                12.0,
                4.0,
                12.0,
                8.0,
              ), // Немного отступ снизу
              child: Row(
                children: [
                  // --- Поле поиска ---
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Поиск...', // Короче текст
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: Obx(
                          () =>
                              controller.searchTerm.value != null &&
                                      controller.searchTerm.value!.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      controller.searchTasks(null);
                                    },
                                  )
                                  : const SizedBox.shrink(),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 10.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant.withOpacity(
                          0.5,
                        ),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // --- Фильтр "Назначенные мне" ---
                  Obx(
                    () => ActionChip(
                      avatar: Icon(
                        controller.assignedToMeFilter.value
                            ? Icons.person
                            : Icons.person_outline,
                        size: 18,
                        color:
                            controller.assignedToMeFilter.value
                                ? theme.colorScheme.onSecondaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                      ),
                      label: const Text('Мне'),
                      onPressed: controller.toggleAssignedToMeFilter,
                      backgroundColor:
                          controller.assignedToMeFilter.value
                              ? theme.colorScheme.secondaryContainer
                              : null,
                      labelStyle: TextStyle(
                        color:
                            controller.assignedToMeFilter.value
                                ? theme.colorScheme.onSecondaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Показать только назначенные мне задачи',
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(
                        color: theme.dividerColor.withOpacity(0.2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Obx(() {
          // --- Состояния загрузки и ошибки ---
          // Проверяем isLoading и основной список taskList для начальной загрузки
          if (controller.isLoading.value && controller.taskList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.errorMessage.value != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ошибка: ${controller.errorMessage.value}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => controller.fetchTasks(),
                      child: const Text('Попробовать снова'),
                    ),
                  ],
                ),
              ),
            );
          }

          // --- Проверка на пустой список ПОСЛЕ применения фильтров ---
          // Считаем общее кол-во задач во всех колонках
          final totalFilteredTasks = controller.tasksByStatus.values.fold<int>(
            0,
            (sum, list) => sum + list.length,
          );
          // --- ИЗМЕНЕНО: Используем isAnyFilterOrSortActive для текста и кнопки сброса ---
          if (!controller.isLoading.value && totalFilteredTasks == 0) {
            final bool filtersActive = controller.isAnyFilterOrSortActive;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filtersActive
                        ? Icons.filter_alt_off_outlined
                        : Icons.space_dashboard_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    filtersActive ? 'Задачи не найдены' : 'Задач пока нет',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
                  if (filtersActive)
                    ElevatedButton(
                      onPressed: _clearSearchAndFilter,
                      child: const Text('Сбросить фильтры и сортировку'),
                    )
                  else // Кнопка создания, если фильтров нет и доска пуста
                    ElevatedButton(
                      onPressed: () => _showCreateTaskDialog(context, null),
                      child: const Text('Создать задачу'),
                    ),
                ],
              ),
            );
          }

          // --- НОВАЯ СТРУКТУРА: ГОРИЗОНТАЛЬНЫЙ LISTVIEW КОЛОНОК ---
          return ListView.builder(
            scrollDirection:
                Axis.horizontal, // Горизонтальная прокрутка колонок
            padding: const EdgeInsets.all(8.0),
            itemCount:
                controller
                    .statusOptions
                    .length, // Количество колонок = количество статусов
            itemBuilder: (context, index) {
              final currentColumnStatus =
                  controller.statusOptions[index]; // Статус текущей колонки
              final tasksInGroup =
                  controller.tasksByStatus[currentColumnStatus] ??
                  <TaskModel>[].obs;

              // --- ВИДЖЕТ КОЛОНКИ ---
              // Оборачиваем в DragTarget, чтобы колонка могла принимать задачи
              return DragTarget<TaskModel>(
                // Указываем, что принимаем TaskModel
                builder: (context, candidateData, rejectedData) {
                  // candidateData - список TaskModel, которые сейчас над целью (обычно один)
                  final bool isHovering =
                      candidateData
                          .isNotEmpty; // true, если что-то тащат над этой колонкой

                  return Container(
                    width: 300,
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color:
                          isHovering
                              ? theme.colorScheme.primaryContainer.withOpacity(
                                0.3,
                              ) // Подсветка при наведении
                              : theme.scaffoldBackgroundColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color:
                            isHovering
                                ? theme
                                    .colorScheme
                                    .primary // Яркая рамка при наведении
                                : theme.dividerColor.withOpacity(0.2),
                        width:
                            isHovering ? 2.0 : 1.0, // Толще рамка при наведении
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- ЗАГОЛОВОК КОЛОНКИ ---
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Text(
                                "${_localizeStatus(currentColumnStatus).toUpperCase()} (${tasksInGroup.length})",
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              // Можно добавить иконку меню для колонки, если нужно
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // --- СПИСОК КАРТОЧЕК ВНУТРИ КОЛОНКИ ---
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8.0),
                            itemCount: tasksInGroup.length,
                            itemBuilder: (context, itemIndex) {
                              final TaskModel task = tasksInGroup[itemIndex];

                              // --- Оборачиваем карточку в Draggable ---
                              return Draggable<TaskModel>(
                                data: task, // Передаем всю модель задачи
                                feedback: Material(
                                  // Обертка для тени и стиля
                                  elevation: 4.0,
                                  color:
                                      Colors
                                          .transparent, // Прозрачный фон под карточкой
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Opacity(
                                    // Делаем перетаскиваемый виджет полупрозрачным
                                    opacity: 0.75,
                                    child: SizedBox(
                                      // Ограничиваем ширину перетаскиваемого элемента
                                      width: 284, // Чуть меньше ширины колонки
                                      child: TaskCard(task: task),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  // Плейсхолдер на месте перетаскиваемой карточки
                                  opacity: 0.3,
                                  child: TaskCard(
                                    task: task,
                                  ), // Можно сделать просто SizedBox с высотой карты
                                ),
                                // child - это то, что отображается обычно
                                child: Obx(() {
                                  final bool isUpdating = controller
                                      .updatingTaskIds
                                      .contains(task.id);
                                  return Stack(
                                    children: [
                                      TaskCard(
                                        task: task,
                                        onTap:
                                            isUpdating
                                                ? null
                                                : () => Get.toNamed(
                                                  Routes.TASK_DETAILS,
                                                  arguments: task.id,
                                                ),
                                      ),
                                      if (isUpdating)
                                        Positioned.fill(
                                          /* ... индикатор без изменений ... */
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            child: const Center(
                                              child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 3,
                                                      color: Colors.white,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                }),
                              );
                            },
                          ),
                        ),

                        // --- ФУТЕР КОЛОНКИ (КНОПКА ДОБАВИТЬ) ---
                        KanbanListFooter(
                          onAddTask:
                              () => _showCreateTaskDialog(
                                context,
                                currentColumnStatus,
                              ),
                        ),
                      ],
                    ),
                  );
                },
                // --- Обработка принятия Draggable ---
                onWillAccept: (TaskModel? data) {
                  // Проверяем, что данные не null и что задача не из этой же колонки
                  // (перетаскивание внутри колонки пока не обрабатываем)
                  if (data != null && data.status != currentColumnStatus) {
                    print(
                      "Target $currentColumnStatus WILL ACCEPT task ${data.id} from ${data.status}",
                    );
                    return true; // Готовы принять
                  }
                  print(
                    "Target $currentColumnStatus WILL REJECT task ${data?.id} from ${data?.status}",
                  );
                  return false; // Не принимаем (либо null, либо из той же колонки)
                },
                onAccept: (TaskModel task) {
                  // Вызывается, когда карточку бросили на эту колонку
                  print(
                    "Target $currentColumnStatus ACCEPTED task ${task.id} from ${task.status}",
                  );
                  // Вызываем метод контроллера для обновления статуса
                  controller.requestStatusUpdate(task.id, currentColumnStatus);
                },
                onLeave: (TaskModel? data) {
                  // Вызывается, когда карточку убрали с этой колонки
                  print("Target $currentColumnStatus: task ${data?.id} LEFT");
                },
              );
            },
          );
          // --- КОНЕЦ НОВОЙ СТРУКТУРЫ ---
        }),
        floatingActionButton: FloatingActionButton(
          onPressed: null, // Делаем неактивным или убираем совсем
          backgroundColor: Colors.transparent, // Скрываем
          elevation: 0,
        ),
      ),
    );
  }

  // Метод для открытия диалога создания
  void _showCreateTaskDialog(BuildContext context, String? initialStatus) {
    controller.initDialogForCreate();
    if (initialStatus != null) {
      controller.dialogSelectedStatus.value = initialStatus;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Новая задача'),
        content: CreateEditTaskDialogContent(controller: controller),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Отмена')),
          Obx(
            () => FilledButton.icon(
              icon:
                  controller.isDialogLoading.value
                      ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                      : Icon(
                        controller.isDialogEditing
                            ? Icons.save_outlined
                            : Icons.add_outlined,
                        size: 18,
                      ),
              label: Text(controller.isDialogEditing ? 'Сохранить' : 'Создать'),
              onPressed:
                  controller.isDialogLoading.value
                      ? null
                      : controller.saveTaskFromDialog,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      // Опционально: сбросить состояние диалога после закрытия, если нужно
      // controller.initDialogForCreate(); // Или другой метод очистки
    });
  }

  // Вспомогательная функция для локализации статуса (можно вынести)
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
        return status;
    }
  }

  // Вспомогательная функция для цвета статуса (пример)
}

// --- Виджет для карточки задачи ---
class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onTap});

  // --- Цвета и иконки приоритета (можно настроить) ---
  Color _getPriorityBorderColor(int priority, ThemeData theme) {
    switch (priority) {
      case 1:
        return Colors.red.shade300;
      case 2:
        return Colors.orange.shade300;
      case 3:
        return Colors.blue.shade300; // Низкий - синий?
      default:
        return theme.dividerColor;
    }
  }

  IconData _getPriorityIcon(int priority) {
    switch (priority) {
      case 1:
        return Icons
            .keyboard_double_arrow_up_rounded; // Двойная стрелка для высокого
      case 2:
        return Icons.keyboard_arrow_up_rounded; // Одинарная для среднего
      case 3:
        return Icons.keyboard_arrow_down_rounded; // Вниз для низкого
      default:
        return Icons.remove_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final TasksController? controller =
        Get.isRegistered<TasksController>()
            ? Get.find<TasksController>()
            : null;
    final Color userColor =
        controller?.getUserColor(task.assigneeId ?? '') ?? Colors.grey;
    final Color priorityBorderColor = _getPriorityBorderColor(
      task.priority,
      theme,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 12.0,
            top: 10.0,
            bottom: 12.0,
            right: 4.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Строка с заголовком и Меню ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Заголовок ---
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  // --- КНОПКА МЕНЮ ---
                  if (controller != null)
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: PopupMenuButton<String>(
                        tooltip: 'Действия',
                        icon: const Icon(Icons.more_vert, size: 20),
                        padding: EdgeInsets.zero,
                        itemBuilder:
                            (BuildContext context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit_outlined, size: 20),
                                  title: Text('Изменить'),
                                  dense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    'Удалить',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  dense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                ),
                              ),
                            ],
                        onSelected: (String value) {
                          if (value == 'edit') {
                            _showEditTaskDialog(context, controller, task);
                          } else if (value == 'delete') {
                            _confirmDeleteTask(context, controller, task);
                          }
                        },
                      ),
                    ),
                ],
              ),
              // --- Описание (если есть) ---
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              // --- Нижняя строка: Приоритет, Дата, Исполнитель ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- Приоритет и Дата ---
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Tooltip(
                        message:
                            'Приоритет: ${controller?.priorityOptions[task.priority] ?? task.priority}',
                        child: Icon(
                          _getPriorityIcon(task.priority),
                          color: priorityBorderColor,
                          size: 20,
                        ),
                      ),
                      // --- Дата выполнения ---
                      if (task.dueDate != null) ...[
                        Builder(
                          builder: (context) {
                            // Используем Builder
                            final bool isOverdue = task.dueDate!.isBefore(
                              DateTime.now(),
                            );
                            final Color dateColor =
                                isOverdue
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant;

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 8),
                                Icon(
                                  isOverdue
                                      ? Icons.warning_amber_rounded
                                      : Icons.calendar_today_outlined,
                                  size: 14,
                                  color: dateColor, // Цвет иконки
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat(
                                    'dd MMM',
                                    'ru',
                                  ).format(task.dueDate!),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: dateColor, // Цвет текста
                                    fontWeight:
                                        isOverdue
                                            ? FontWeight.bold
                                            : null, // Жирный шрифт
                                    decoration:
                                        isOverdue
                                            ? TextDecoration.underline
                                            : null, // Подчеркивание
                                    decorationColor: dateColor,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),

                  // --- Аватар исполнителя ---
                  if (task.assigneeId != null)
                    Tooltip(
                      message: task.assigneeUsername ?? task.assigneeId,
                      child: CircleAvatar(
                        backgroundColor: userColor.withOpacity(0.8),
                        foregroundColor: Colors.white,
                        radius: 14,
                        child: Text(
                          task.assigneeUsername != null &&
                                  task.assigneeUsername!.isNotEmpty
                              ? task.assigneeUsername![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 28, width: 28),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Вспомогательные методы для вызова диалогов из TaskCard ---

  // Показ диалога редактирования
  void _showEditTaskDialog(
    BuildContext context,
    TasksController controller,
    TaskModel task,
  ) {
    controller.initDialogForEdit(task);
    Get.dialog(
      AlertDialog(
        title: const Text('Изменить задачу'),
        content: CreateEditTaskDialogContent(controller: controller),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Отмена')),
          Obx(
            () => FilledButton.icon(
              icon:
                  controller.isDialogLoading.value
                      ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                      : Icon(
                        controller.isDialogEditing
                            ? Icons.save_outlined
                            : Icons.add_outlined,
                        size: 18,
                      ),
              label: Text(controller.isDialogEditing ? 'Сохранить' : 'Создать'),
              onPressed:
                  controller.isDialogLoading.value
                      ? null
                      : controller.saveTaskFromDialog,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      controller.initDialogForCreate();
    });
  }

  // Показ диалога подтверждения удаления
  void _confirmDeleteTask(
    BuildContext context,
    TasksController controller,
    TaskModel task,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Удалить задачу?'),
        content: Text(
          'Вы уверены, что хотите удалить задачу "${task.title}"? Это действие необратимо.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Отмена')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Get.back();
              await controller.deleteTask(task.id);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

// --- Виджет Заголовка Колонки (ListHeader) ---
class KanbanListHeader extends StatelessWidget {
  final String title;
  final int count;
  // final Color stateColor; // Можно добавить цвет статуса, если нужно

  const KanbanListHeader({
    super.key,
    required this.title,
    required this.count,
    // required this.stateColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      // Добавляем внешние отступы
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            "${title.toUpperCase()}  (${count})", // Добавим пару пробелов для воздуха
            style: theme.textTheme.titleSmall?.copyWith(
              // Стиль titleSmall
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600, // Чуть жирнее
              letterSpacing: 0.5, // Небольшое разряжение
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// --- Виджет Футера Колонки (ListFooter) ---
class KanbanListFooter extends StatelessWidget {
  final VoidCallback? onAddTask;

  const KanbanListFooter({super.key, this.onAddTask});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Используем TextButton.icon для Material стиля
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 8.0,
      ), // Отступы вокруг кнопки
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          minimumSize: const Size(double.infinity, 40), // Растянем по ширине
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0), // Скругление как у Card
            // Можно добавить слабую рамку, если хочется
            // side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        icon: const Icon(Icons.add_circle_outline, size: 18),
        label: const Text("Добавить задачу"),
        onPressed: onAddTask,
      ),
    );
  }
}
