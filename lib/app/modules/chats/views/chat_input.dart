import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';

class ChatInput extends StatelessWidget {
  const ChatInput({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => _buildSelectedFilePreview(controller, theme, colorScheme)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  Icons.attach_file_rounded,
                  color: colorScheme.secondary,
                ),
                tooltip: 'Прикрепить файл',
                onPressed: controller.selectFileToSend,
              ),
              SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: controller.messageController,
                  focusNode: controller.messageFocusNode,
                  maxLines: 5,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'type_message'.tr,
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 10.0,
                    ),
                    filled: true,
                    fillColor:
                        colorScheme
                            .surfaceContainerHighest, // Use appropriate container color
                    isDense: true,
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  cursorColor: colorScheme.primary,
                  onSubmitted: (value) {
                    // Attempt to send message on submit
                    if (controller.canSendMessage) {
                      controller.sendMessage();
                    }
                    // Keep focus after submit for easier multi-messaging
                  },
                ),
              ),
              SizedBox(width: 8.0),
              Obx(
                () => IconButton(
                  icon:
                      controller.isSendingMessage.value
                          ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                          : Icon(
                            Icons.send_rounded,
                            color:
                                controller.canSendMessage
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withOpacity(0.3),
                          ),
                  tooltip: 'Отправить сообщение',
                  onPressed:
                      controller.canSendMessage ? controller.sendMessage : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFilePreview(
    ChatsController controller,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final file = controller.selectedFile.value;
    if (file == null) {
      return SizedBox.shrink();
    }

    final fileName = file.path.split(Platform.pathSeparator).last;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: colorScheme.secondaryContainer, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.attach_file_rounded,
            size: 18,
            color: colorScheme.onSecondaryContainer,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: colorScheme.onSecondaryContainer,
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            tooltip: 'Убрать файл',
            onPressed: () {
              controller.selectedFile.value = null;
            },
          ),
        ],
      ),
    );
  }
}
