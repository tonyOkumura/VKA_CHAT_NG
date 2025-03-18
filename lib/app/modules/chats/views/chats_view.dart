import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/routes/app_pages.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/chats_controller.dart';

class ChatsView extends GetView<ChatsController> {
  const ChatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        centerTitle: false,
        elevation: 0,
      ),
      drawer: AppDrawer(),
      body: Row(
        children: [
          Expanded(flex: 2, child: ChatList()),
          Expanded(
            flex: 5,
            child: Obx(
              () =>
                  controller.selectedConversation.value == null
                      ? Center(child: Text('Select a chat'))
                      : ChatDetail(),
            ),
          ),
        ],
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Messages'),
            onTap: () {
              Get.back();
            },
          ),
          ListTile(
            leading: Icon(Icons.contacts),
            title: Text('Contacts'),
            onTap: () {
              Get.toNamed(Routes.CONTACTS);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Get.toNamed(Routes.SETTINGS);
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () {
              final _storage = FlutterSecureStorage();
              _storage.delete(key: 'token');
              _storage.delete(key: 'userId');
              print("Logged out");
              Get.offAllNamed(Routes.LOGIN);
            },
          ),
        ],
      ),
    );
  }
}

class ChatList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    return Container(
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
                          leading: CircleAvatar(backgroundColor: Colors.white),
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
                  itemCount: controller.conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = controller.conversations[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          conversation.participantName[0],
                        ), // Replace with actual avatar
                      ),
                      title: Text(
                        conversation.participantName,
                      ), // Replace with actual chat name
                      subtitle: Text(
                        conversation.lastMessage,
                      ), // Replace with actual last message
                      trailing: Text(
                        conversation.lastMessageTime.toString(),
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      onTap: () {
                        controller.selectConversation(index);
                        controller.fetchMessages();
                      },
                    );
                  },
                ),
      ),
    );
  }
}

class ChatDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          ChatHeader(),
          Expanded(
            child: Center(
              child: Text(
                'Chat details will be displayed here.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          ),
          ChatInput(),
        ],
      ),
    );
  }
}

class ChatHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    return Container(
      padding: EdgeInsets.all(16),
      color: Get.theme.colorScheme.onPrimary,
      child: Row(
        children: [
          CircleAvatar(
            child: Text(
              controller.selectedConversation.value!.participantName[0],
            ), // Replace with actual avatar
          ),
          SizedBox(width: 16),
          Text(
            controller
                .selectedConversation
                .value!
                .participantName, // Replace with actual chat name
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ],
      ),
    );
  }
}

//  class ChatMessages extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.find<ChatsController>();
//     return ListView.builder(
//       itemCount: controller.selectedConversation.value!.messages.length,
//       itemBuilder: (context, index) {
//         final message = controller.selectedConversation.value!.messages[index];
//         return ListTile(
//           title: Align(
//             alignment:
//                 message.isSentByMe
//                     ? Alignment.centerRight
//                     : Alignment.centerLeft,
//             child: Container(
//               padding: EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: message.isSentByMe ? Colors.blue[800] : Colors.grey[800],
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Text(message.text), // Replace with actual message
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

class ChatInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(onPressed: () {}, icon: Icon(Icons.attach_file)),
          Expanded(
            child: TextField(
              controller: controller.messageController,
              decoration: InputDecoration(
                hintText: 'Type a message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              // controller.sendMessage();
            },
          ),
        ],
      ),
    );
  }
}
