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
        title: const Text('Contacts'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
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
                        onTap: () {
                          controller.chechkOrCreateConversation(
                            contactId: contact.id,
                          );
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
          title: Text('Add Contact'),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(hintText: 'Enter email'),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Get.back();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                controller.addContact(contactEmail: emailController.text);
                Get.back();
              },
            ),
          ],
        );
      },
    );
  }
}
