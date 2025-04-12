import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/data/models/contact_model.dart';

class AssigneeSelectionDialog extends StatefulWidget {
  final List<String> initialSelectedIds;
  final List<Contact> availableContacts;

  const AssigneeSelectionDialog({
    super.key,
    required this.initialSelectedIds,
    required this.availableContacts,
  });

  @override
  State<AssigneeSelectionDialog> createState() =>
      _AssigneeSelectionDialogState();
}

class _AssigneeSelectionDialogState extends State<AssigneeSelectionDialog> {
  late RxList<String> _selectedIds;
  final _searchController = TextEditingController();
  final RxList<Contact> _filteredContacts = <Contact>[].obs;

  @override
  void initState() {
    super.initState();
    // Инициализируем выбранные ID из входных данных
    _selectedIds = RxList<String>.from(widget.initialSelectedIds);
    // Изначально показываем все контакты
    _filteredContacts.assignAll(widget.availableContacts);
    // Слушаем изменения поиска
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterContacts);
    _searchController.dispose();
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
    return AlertDialog(
      title: const Text('Выберите исполнителей'),
      contentPadding: const EdgeInsets.only(
        top: 10.0,
      ), // Уменьшаем отступ сверху
      content: SizedBox(
        // Ограничиваем размер диалога
        width: double.maxFinite,
        height: Get.height * 0.6, // Например, 60% высоты экрана
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
            // --- Список контактов ---
            Expanded(
              child: Obx(() {
                // Используем Obx для реакции на _filteredContacts
                if (_filteredContacts.isEmpty) {
                  return const Center(child: Text('Контакты не найдены'));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = _filteredContacts[index];
                    // Используем Obx для реакции на _selectedIds
                    return Obx(
                      () => CheckboxListTile(
                        title: Text(contact.username),
                        subtitle: Text(
                          contact.email,
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: _selectedIds.contains(contact.id),
                        onChanged: (bool? selected) {
                          if (selected == true) {
                            _selectedIds.add(contact.id);
                          } else {
                            _selectedIds.remove(contact.id);
                          }
                        },
                        secondary: CircleAvatar(
                          // TODO: Улучшить аватар
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
          // Передаем текущий список выбранных ID при подтверждении
          onPressed: () => Get.back(result: _selectedIds.toList()),
          child: const Text('Выбрать'),
        ),
      ],
    );
  }
}
