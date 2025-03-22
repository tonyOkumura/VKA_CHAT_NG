import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vka_chat_ng/app/data/message_model.dart';
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
                          conversation.conversation_name[0],
                        ), // Replace with actual avatar
                      ),
                      title: Text(
                        conversation.conversation_name,
                      ), // Replace with actual chat name
                      subtitle: Text(
                        conversation.last_message??"",
                        overflow: TextOverflow.ellipsis,
                      ), // Replace with actual last message
                      trailing: Text(
                        DateFormat(
                          'MMMM d , HH:mm',
                        ).format(conversation.last_message_time??DateTime.now()),
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      onTap: () {
                        controller.selectConversation(index);
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
        children: [ChatHeader(), Expanded(child: ChatMessages()), ChatInput()],
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
              controller.selectedConversation.value!.conversation_name[0],
            ), // Replace with actual avatar
          ),
          SizedBox(width: 16),
          Text(
            controller
                .selectedConversation
                .value!
                .conversation_name, // Replace with actual chat name
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ],
      ),
    );
  }
}

class ChatMessages extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    return Obx(
      () =>
          controller.isLoadingMessages.value
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                controller: controller.scrollController,
                reverse: true,
                itemCount: controller.messages.length,
                padding: const EdgeInsets.only(bottom: 70.0),
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final isSender = message.sender_id == controller.userId;

                  final showDateHeader =
                      index == controller.messages.length - 1 ||
                      DateTime.parse(message.created_at).day !=
                          DateTime.parse(
                            controller.messages[index + 1].created_at,
                          ).day;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showDateHeader)
                        _buildDateHeader(
                          DateTime.parse(message.created_at).toLocal(),
                        ),

                      _buildMessageBubble(message, isSender),
                    ],
                  );
                },
              ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 16.0),
      child: Text(
        _formatDate(date),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Nunito',
          color: Get.theme.colorScheme.secondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "Сегодня";
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return "Вчера";
    } else {
      return "${date.day}.${date.month}.${date.year}";
    }
  }

  Widget _buildMessageBubble(Message message, bool isSender) {
    return ListTile(
      title: Align(
        alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSender ? Colors.blue[800] : Colors.grey[800],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment:
                isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(message.content), // Replace with actual message
              SizedBox(height: 5),
              Text(
                DateFormat(
                  'HH:mm',
                ).format(DateTime.parse(message.created_at).toLocal()),
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
              controller.sendMessage();
            },
          ),
        ],
      ),
    );
  }
}
