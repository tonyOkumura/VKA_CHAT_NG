import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/data/models/contact_model.dart';
import 'package:vka_chat_ng/app/modules/tasks/controllers/tasks_controller.dart'; // Для getUserColor

class SingleAssigneeSelectionDialog extends StatefulWidget {
  final Contact? initialSelectedContact;
  final List<Contact> availableContacts;

  const SingleAssigneeSelectionDialog({
    super.key,
    this.initialSelectedContact,
    required this.availableContacts,
  });

  @override
  State<SingleAssigneeSelectionDialog> createState() =>
      _SingleAssigneeSelectionDialogState();
}

class _SingleAssigneeSelectionDialogState
    extends State<SingleAssigneeSelectionDialog> {
  // Используем Contact? для хранения выбора, null означает "не назначен"
  late Rxn<Contact> _selectedContact;
  final _searchController = TextEditingController();
  final RxList<Contact> _filteredContacts = <Contact>[].obs;
  // Получаем TasksController для цвета аватара
  final TasksController _tasksController = Get.find<TasksController>();

  @override
  void initState() {
    super.initState();
    _selectedContact = Rxn<Contact>(widget.initialSelectedContact);
    _filteredContacts.assignAll(widget.availableContacts);
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterContacts);
    _searchController.dispose();
    _selectedContact.close(); // Закрываем Rxn
    _filteredContacts.close();
    super.dispose();
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _filteredContacts.assignAll(widget.availableContacts);
    } else {
      _filteredContacts.assignAll(
        widget.availableContacts.where((contact) {
          return contact.username.toLowerCase().contains(query) ||
              contact.email.toLowerCase().contains(query);
        }).toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Выберите исполнителя'),
      contentPadding: const EdgeInsets.only(top: 0), // Убираем отступ сверху
      content: SizedBox(
        width: double.maxFinite,
        height: Get.height * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Поле поиска ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск контактов...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => _searchController.clear(),
                          )
                          : null,
                ),
              ),
            ),
            const Divider(height: 1), // Разделитель
            // --- Опция "Не назначен" ---
            Obx(
              () => RadioListTile<Contact?>(
                title: const Text(
                  'Не назначен',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                value: null, // null значение для "не назначен"
                groupValue: _selectedContact.value,
                onChanged: (Contact? value) {
                  _selectedContact.value = value; // Выбираем null
                },
              ),
            ),
            const Divider(height: 1),
            // --- Список контактов ---
            Expanded(
              child: Obx(() {
                if (_filteredContacts.isEmpty &&
                    _searchController.text.isNotEmpty) {
                  return const Center(child: Text('Контакты не найдены'));
                }
                if (widget.availableContacts.isEmpty) {
                  // Если вообще нет контактов
                  return const Center(child: Text('Нет доступных контактов'));
                }
                // Используем RadioListTile для выбора одного
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = _filteredContacts[index];
                    final userColor = _tasksController.getUserColor(contact.id);
                    return Obx(
                      () => RadioListTile<Contact?>(
                        title: Text(contact.username),
                        subtitle: Text(
                          contact.email,
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: contact, // Значение - сам объект Contact
                        groupValue:
                            _selectedContact.value, // Сравниваем объекты
                        onChanged: (Contact? value) {
                          _selectedContact.value = value; // Выбираем контакт
                        },
                        secondary: CircleAvatar(
                          backgroundColor: userColor,
                          foregroundColor: Colors.white,
                          child: Text(
                            contact.username.isNotEmpty
                                ? contact.username[0].toUpperCase()
                                : '?',
                          ),
                          radius: 16,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          // Передаем null при отмене
          onPressed: () => Get.back(result: null),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          // Передаем выбранный Contact? (может быть null)
          onPressed: () => Get.back(result: _selectedContact.value),
          child: const Text('Выбрать'),
        ),
      ],
    );
  }
}
