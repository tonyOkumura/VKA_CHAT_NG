import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';
import 'package:vka_chat_ng/app/modules/chats/views/chat_header.dart';
import 'package:vka_chat_ng/app/modules/chats/views/chat_input.dart';
import 'package:vka_chat_ng/app/modules/chats/views/chat_messages.dart';

class ChatDetail extends StatelessWidget {
  const ChatDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();

    // Ensure selectedConversation is not null before building
    if (controller.selectedConversation.value == null) {
      // This case should ideally be handled by the parent layout,
      // but return an empty container as a fallback.
      return Container();
    }

    return Container(
      // Optionally add background color or decoration
      color: Get.theme.colorScheme.surface,
      child: Column(
        children: [
          // Chat Header
          ChatHeader(),

          // Chat Messages
          Expanded(child: ChatMessages()),

          // Chat Input Area
          ChatInput(),
        ],
      ),
    );
  }
}
