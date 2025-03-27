import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';

class ChatInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(color: Get.theme.colorScheme.surface),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.messageController,
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.send,
              keyboardType: TextInputType.multiline,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'type_message'.tr,
                hintStyle: TextStyle(
                  color: Get.theme.colorScheme.onSurfaceVariant,
                  fontFamily: 'Nunito',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide(color: Get.theme.colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide(color: Get.theme.colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide(
                    color: Get.theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                filled: true,
                fillColor: Get.theme.colorScheme.surfaceVariant,
              ),
              style: TextStyle(
                color: Get.theme.colorScheme.onSurfaceVariant,
                fontSize: 16,
                fontFamily: 'Nunito',
              ),
              cursorColor: Get.theme.colorScheme.primary,
              focusNode: controller.messageFocusNode,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  controller.sendMessage();
                  controller.messageController.clear();
                  controller.messageFocusNode.requestFocus();
                }
              },
            ),
          ),
          SizedBox(width: 8.0),
          IconButton(
            icon: Icon(Icons.send, color: Get.theme.colorScheme.primary),
            onPressed: () {
              if (controller.messageController.text.isNotEmpty) {
                controller.sendMessage();
                controller.messageController.clear();
                controller.messageFocusNode.requestFocus();
              }
            },
          ),
        ],
      ),
    );
  }
}
