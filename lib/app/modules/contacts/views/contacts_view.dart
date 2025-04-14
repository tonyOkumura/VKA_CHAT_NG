import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vka_chat_ng/app/data/models/user_model.dart';

import 'package:vka_chat_ng/app/widgets/main_layout.dart';
import '../controllers/contacts_controller.dart';

class ContactsView extends GetView<ContactsController> {
  const ContactsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MainLayout(
      selectedIndex: 1,
      child: Scaffold(
        appBar: AppBar(
          title: Obx(
            () => Text(
              controller.isSelectionMode.value
                  ? 'Выберите участников'
                  : 'Контакты',
              style: theme.appBarTheme.titleTextStyle,
            ),
          ),
          centerTitle: true,
          elevation: 0, // Убираем тень AppBar
          backgroundColor:
              theme.scaffoldBackgroundColor, // Фон AppBar как у Scaffold
          foregroundColor: colorScheme.onBackground, // Цвет иконок и текста
          actions: [
            Obx(
              () =>
                  controller.isSelectionMode.value
                      ? IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Отменить выбор',
                        onPressed:
                            controller
                                .cancelSelectionMode, // Используем метод контроллера
                      )
                      : IconButton(
                        icon: const Icon(Icons.group_add_outlined),
                        tooltip: 'Создать группу',
                        onPressed:
                            () => controller.isSelectionMode.value = true,
                      ),
            ),
            // Не показываем кнопку добавления в режиме выбора
            Obx(
              () =>
                  !controller.isSelectionMode.value
                      ? IconButton(
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        tooltip: 'Добавить контакт',
                        onPressed: () => _showSearchUsersDialog(context),
                      )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchField(context), // Выносим поиск в отдельный метод
            Expanded(
              child: Obx(
                () =>
                    controller.isLoading.value
                        ? _buildShimmerList(context) // Шиммер
                        : controller.filteredContacts.isEmpty
                        ? _buildEmptyState(
                          context,
                          "У вас пока нет контактов",
                          Icons.people_outline,
                        )
                        : _buildContactsList(context), // Список контактов
              ),
            ),
            _buildCreateGroupButton(context), // Кнопка создания группы
          ],
        ),
      ),
    );
  }

  // Виджет поля поиска контактов
  Widget _buildSearchField(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Используем TextEditingController для возможности очистки
    final searchController = TextEditingController(
      text: controller.searchQuery.value,
    );

    // Слушаем изменения в Rx переменной и обновляем контроллер
    ever(controller.searchQuery, (String query) {
      if (searchController.text != query) {
        searchController.text = query;
      }
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Material(
        elevation: 1.0,
        borderRadius: BorderRadius.circular(12.0),
        shadowColor: colorScheme.shadow.withOpacity(0.2),
        child: TextField(
          controller: searchController,
          onChanged: (value) {
            controller.searchQuery.value = value;
            controller.filterContacts(value);
          },
          decoration: InputDecoration(
            hintText: 'Поиск контактов...',
            prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
            suffixIcon: Obx(
              () =>
                  controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          searchController.clear(); // Очищаем поле
                          controller.searchQuery.value = '';
                          controller.filterContacts('');
                        },
                      )
                      : const SizedBox.shrink(),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none, // Убираем границу по умолчанию
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.6),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14, // Немного увеличиваем высоту
            ),
          ),
        ),
      ),
    );
  }

  // Виджет списка контактов
  Widget _buildContactsList(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      itemCount: controller.filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = controller.filteredContacts[index];
        // Оборачиваем Card в Obx
        return Obx(() {
          // Вычисляем isSelected ВНУТРИ Obx
          final isSelected = controller.selectedContacts.contains(contact.id);

          return Card(
            elevation:
                controller.isSelectionMode.value
                    ? (isSelected ? 3.0 : 1.0)
                    : 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(
                color:
                    controller.isSelectionMode.value && isSelected
                        ? theme.colorScheme.primary.withOpacity(0.7)
                        : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              leading: _buildContactAvatarWithStatus(context, contact),
              title: Text(
                contact.username,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                contact.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing:
                  controller.isSelectionMode.value
                      ? Checkbox(
                        value:
                            isSelected, // Используем isSelected, вычисленный внутри Obx
                        onChanged: (bool? value) {
                          if (value == true) {
                            controller.selectedContacts.add(contact.id);
                          } else {
                            controller.selectedContacts.remove(contact.id);
                          }
                        },
                        activeColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                      : null,
              onTap: () {
                if (controller.isSelectionMode.value) {
                  // Используем isSelected, вычисленный внутри Obx
                  if (isSelected) {
                    controller.selectedContacts.remove(contact.id);
                  } else {
                    controller.selectedContacts.add(contact.id);
                  }
                } else {
                  controller.selectedContact.value = contact;
                  controller.chechkOrCreateConversation(
                    contactId: contact.id,
                    contactEmail: contact.email,
                  );
                }
              },
              selected:
                  controller.isSelectionMode.value &&
                  isSelected, // Используем isSelected
              selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(
                0.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          );
        });
      },
    );
  }

  // Аватар контакта со статусом онлайн/офлайн
  Widget _buildContactAvatarWithStatus(BuildContext context, dynamic contact) {
    final theme = Theme.of(context);
    final avatarColor = controller.getUserColor(contact.id);
    final isOnline =
        contact.isOnline ??
        false; // Учитываем, что контакт может быть и не User

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: avatarColor,
          child: Text(
            contact.username.isNotEmpty
                ? contact.username[0].toUpperCase()
                : '?',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Индикатор статуса
        Positioned(
          bottom: -1,
          right: -1,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: isOnline ? Colors.greenAccent[400] : Colors.grey[400],
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.cardColor, // Цвет фона карточки для обводки
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Шиммер-загрузчик списка
  Widget _buildShimmerList(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      highlightColor: theme.colorScheme.surface.withOpacity(0.8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        itemCount: 8, // Показываем несколько скелетонов
        itemBuilder:
            (context, index) => Card(
              elevation: 1.0,
              margin: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 5.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                leading: const CircleAvatar(radius: 24),
                title: Container(
                  height: 16.0,
                  width: double.infinity,
                  color:
                      Colors
                          .white, // Цвет контейнеров в шиммере должен быть непрозрачным
                  margin: const EdgeInsets.only(bottom: 8.0),
                ),
                subtitle: Container(
                  height: 12.0,
                  width: double.infinity,
                  color: Colors.white,
                ),
              ),
            ),
      ),
    );
  }

  // Виджет состояния "нет данных"
  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 60,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Кнопка создания группы (появляется в режиме выбора)
  Widget _buildCreateGroupButton(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(
      () => AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder:
            (child, animation) =>
                SizeTransition(sizeFactor: animation, child: child),
        child:
            controller.isSelectionMode.value &&
                    controller.selectedContacts.isNotEmpty
                ? Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () {
                      // Открываем диалог ввода имени группы
                      Get.dialog(
                        AlertDialog(
                          title: const Text('Создать группу'),
                          content: TextField(
                            controller: controller.groupNameController,
                            focusNode: controller.groupNameFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Название группы',
                              errorText: controller.groupNameError.value,
                            ),
                            autofocus: true,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                controller.groupNameError.value =
                                    null; // Сбрасываем ошибку
                                Get.back();
                              },
                              child: const Text('Отмена'),
                            ),
                            TextButton(
                              onPressed: controller.createGroup,
                              child: const Text('Создать'),
                            ),
                          ],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                        ),
                      );
                    },
                    label: Text(
                      'Создать группу (${controller.selectedContacts.length})',
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      textStyle: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
                : const SizedBox.shrink(), // Прячем кнопку, если не в режиме выбора или никто не выбран
      ),
    );
  }

  // Модифицированный диалог поиска пользователей
  void _showSearchUsersDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final searchUserController =
        TextEditingController(); // Контроллер для поиска в диалоге

    controller.fetchGlobalUsers();
    controller.filterGlobalUsers('');

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 4.0,
        child: ClipRRect(
          // Обрезаем содержимое по скругленным углам
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            color: colorScheme.surface, // Используем цвет поверхности диалога
            padding: const EdgeInsets.all(16.0),
            constraints: BoxConstraints(
              // Ограничиваем максимальную высоту
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Важно для ограничения высоты
              children: [
                Text(
                  'Найти и добавить пользователя',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: searchUserController,
                  onChanged: (value) => controller.filterGlobalUsers(value),
                  decoration: InputDecoration(
                    hintText: 'Поиск по имени или email...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    suffixIcon: Obx(
                      // Кнопка очистки
                      () =>
                          controller.globalSearchQuery.value.isNotEmpty
                              ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                tooltip: 'Очистить поиск',
                                onPressed: () {
                                  searchUserController.clear();
                                  controller.filterGlobalUsers('');
                                },
                              )
                              : const SizedBox.shrink(),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.6),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                // Используем Flexible вместо Expanded, чтобы он занимал доступное место,
                // но не больше, чем нужно содержимому или ограничениям BoxConstraints
                Flexible(
                  child: Obx(() {
                    if (controller.isFetchingGlobalUsers.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (controller.filteredGlobalUsers.isEmpty &&
                        controller.globalSearchQuery.isNotEmpty) {
                      return _buildEmptyState(
                        context,
                        "Пользователи не найдены",
                        Icons.search_off,
                      );
                    }
                    if (controller.filteredGlobalUsers.isEmpty &&
                        controller.globalSearchQuery.isEmpty) {
                      return _buildEmptyState(
                        context,
                        "Начните вводить имя или email",
                        Icons.person_search,
                      );
                    }
                    // Оборачиваем ListView в Scrollbar для индикации прокрутки
                    return Scrollbar(
                      child: ListView.separated(
                        shrinkWrap: true, // Важно для Flexible
                        itemCount: controller.filteredGlobalUsers.length,
                        itemBuilder: (context, index) {
                          final user = controller.filteredGlobalUsers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: controller.getUserColor(user.id),
                              child: Text(
                                user.username.isNotEmpty
                                    ? user.username[0].toUpperCase()
                                    : '?',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              user.username,
                              style: theme.textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              user.email,
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.person_add_alt_1_outlined,
                                color: colorScheme.primary,
                              ),
                              tooltip: 'Добавить контакт',
                              onPressed: () {
                                // Добавляем контакт и закрываем диалог (addContact сделает это при успехе)
                                controller.addContact(contactEmail: user.email);
                              },
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 4.0,
                              horizontal: 8.0,
                            ),
                            // Убрали onTap со всей строки, используем кнопку
                          );
                        },
                        separatorBuilder:
                            (context, index) => Divider(
                              height: 1,
                              thickness: 0.5,
                              color: colorScheme.outline.withOpacity(0.3),
                              indent: 60, // Отступ слева как у текста
                            ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                // Кнопка закрытия диалога
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    child: Text(
                      'Закрыть',
                      style: TextStyle(color: colorScheme.primary),
                    ),
                    onPressed: () => Get.back(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Не закрывать диалог при клике вне его, если нужно
      // barrierDismissible: false,
    );
  }
}
