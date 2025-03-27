import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';
import 'package:vka_chat_ng/app/modules/chats/views/chat_header.dart';
import 'package:vka_chat_ng/app/modules/chats/views/chat_messages.dart';
import 'package:vka_chat_ng/app/modules/chats/views/chat_input.dart';

class ChatDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar:
          isSmallScreen
              ? AppBar(
                leading: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Get.back();
                  },
                ),
                title: Obx(() {
                  final conversation =
                      Get.find<ChatsController>().selectedConversation.value;
                  return Text(conversation?.conversation_name ?? '');
                }),
              )
              : null,
      body: Column(
        children: [
          if (!isSmallScreen) ChatHeader(),
          Expanded(child: ChatMessages()),
          ChatInput(),
        ],
      ),
    );
  }
}
