import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';

class ChatHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Get.theme.colorScheme.outline.withOpacity(0.12),
          ),
        ),
      ),
      child: Obx(() {
        final conversation =
            Get.find<ChatsController>().selectedConversation.value;
        if (conversation == null) return SizedBox.shrink();

        return Row(
          children: [
            if (!isSmallScreen) ...[
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Get.find<ChatsController>().selectConversation(null);
                },
              ),
              SizedBox(width: 16),
            ],
            conversation.is_group_chat
                ? Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Get.theme.colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.group,
                    color: Get.theme.colorScheme.onTertiary,
                  ),
                )
                : CircleAvatar(
                  radius: 20,
                  backgroundColor: Get.theme.colorScheme.primary,
                  child: Text(
                    conversation.conversation_name[0].toUpperCase(),
                    style: TextStyle(
                      color: Get.theme.colorScheme.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                conversation.conversation_name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Get.theme.colorScheme.onSurface,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.more_vert),
              onPressed: () {
                // TODO: Implement chat options menu
              },
            ),
          ],
        );
      }),
    );
  }
}
