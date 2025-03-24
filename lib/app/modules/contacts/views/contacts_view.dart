import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/contacts_controller.dart';

class ContactsView extends GetView<ContactsController> {
  const ContactsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      icon: const Icon(Icons.check),
                      onPressed: () {
                        _showGroupNameDialog(context);
                      },
                    )
                    : IconButton(
                      icon: const Icon(Icons.group_add),
                      onPressed: () {
                        controller.startSelectionMode();
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                    itemCount: controller.contacts.length,
                    itemBuilder: (context, index) {
                      final contact = controller.contacts[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text(contact.username[0])),
                        title: Text(contact.username),
                        subtitle: Text(contact.email),
                        trailing: Obx(
                          () =>
                              controller.isSelectionMode.value
                                  ? Checkbox(
                                    value: controller.isContactSelected(
                                      contact.id,
                                    ),
                                    onChanged: (bool? value) {
                                      controller.toggleContactSelection(
                                        contact.id,
                                      );
                                    },
                                  )
                                  : const SizedBox(),
                        ),
                        onTap: () {
                          if (controller.isSelectionMode.value) {
                            controller.toggleContactSelection(contact.id);
                          } else {
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

  void _showGroupNameDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Название группы'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Введите название группы',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Get.back();
              },
            ),
            TextButton(
              child: const Text('Создать'),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  Get.back();
                  controller.confirmSelectionAndCreateGroup(
                    groupName: nameController.text,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
