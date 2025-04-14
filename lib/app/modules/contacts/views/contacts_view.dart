import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import 'package:vka_chat_ng/app/widgets/main_layout.dart';
import '../controllers/contacts_controller.dart';

class ContactsView extends GetView<ContactsController> {
  const ContactsView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 1,
      child: Scaffold(
        appBar: AppBar(
          title: Obx(
            () => Text(
              controller.isSelectionMode.value
                  ? 'Выберите участников'
                  : 'Контакты',
            ),
          ),
          centerTitle: true,
          actions: [
            Obx(
              () =>
                  controller.isSelectionMode.value
                      ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          controller.selectedContacts.clear();
                          controller.isSelectionMode.value = false;
                        },
                      )
                      : IconButton(
                        icon: const Icon(Icons.group_add),
                        onPressed: () {
                          controller.isSelectionMode.value = true;
                        },
                      ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                _showAddContactDialog(context);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (value) {
                  controller.searchQuery.value = value;
                  controller.filterContacts(value);
                },
                decoration: InputDecoration(
                  hintText: 'Поиск контактов...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      controller.searchQuery.value.isNotEmpty
                          ? InkWell(
                            onTap: () {
                              controller.searchQuery.value = '';
                              controller.filterContacts('');
                            },
                            child: Icon(Icons.clear),
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Get.theme.colorScheme.outline,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Get.theme.colorScheme.outline,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Get.theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Get.theme.colorScheme.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(
                () =>
                    controller.isLoading.value
                        ? Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: ListView.builder(
                            itemCount: 10,
                            itemBuilder:
                                (context, index) => ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.white,
                                  ),
                                  title: Container(
                                    width: double.infinity,
                                    height: 10.0,
                                    color: Colors.white,
                                  ),
                                  subtitle: Container(
                                    width: double.infinity,
                                    height: 10.0,
                                    color: Colors.white,
                                  ),
                                ),
                          ),
                        )
                        : ListView.builder(
                          itemCount: controller.filteredContacts.length,
                          itemBuilder: (context, index) {
                            final contact = controller.filteredContacts[index];
                            return ListTile(
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color:
                                          contact.isOnline
                                              ? Colors.green
                                              : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: controller.getUserColor(
                                      contact.id,
                                    ),
                                    child: Text(
                                      contact.username[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              title: Text(contact.username),
                              subtitle: Text(contact.email),
                              trailing: Obx(
                                () =>
                                    controller.isSelectionMode.value
                                        ? Checkbox(
                                          value: controller.selectedContacts
                                              .contains(contact.id),
                                          onChanged: (bool? value) {
                                            if (value == true) {
                                              controller.selectedContacts.add(
                                                contact.id,
                                              );
                                            } else {
                                              controller.selectedContacts
                                                  .remove(contact.id);
                                            }
                                          },
                                        )
                                        : const SizedBox(),
                              ),
                              onTap: () {
                                if (controller.isSelectionMode.value) {
                                  if (controller.selectedContacts.contains(
                                    contact.id,
                                  )) {
                                    controller.selectedContacts.remove(
                                      contact.id,
                                    );
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
                            );
                          },
                        ),
              ),
            ),
            Obx(
              () =>
                  controller.isSelectionMode.value
                      ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () {
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
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(),
                                    child: const Text('Отмена'),
                                  ),
                                  TextButton(
                                    onPressed: () => controller.createGroup(),
                                    child: const Text('Создать'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Создать группу'),
                        ),
                      )
                      : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContactDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Добавить контакт'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(hintText: 'Введите email'),
          ),
          actions: [
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Get.back();
              },
            ),
            TextButton(
              child: const Text('Добавить'),
              onPressed: () {
                if (emailController.text.isNotEmpty) {
                  controller.addContact(contactEmail: emailController.text);
                  Get.back();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
