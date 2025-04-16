import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';
import 'package:vka_chat_ng/app/services/socket_service.dart';
import 'dart:async';

class ChatInput extends StatefulWidget {
  const ChatInput({super.key});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final ChatsController controller = Get.find<ChatsController>();
  final SocketService socketService = Get.find<SocketService>();

  bool _wasTyping = false;

  @override
  void initState() {
    super.initState();
    controller.messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    controller.messageController.removeListener(_onTextChanged);
    if (_wasTyping) {
      _sendStopTypingEvent();
    }
    super.dispose();
  }

  void _onTextChanged() {
    if (controller.selectedConversation.value == null) return;

    final conversationId = controller.selectedConversation.value!.id;
    final text = controller.messageController.text;

    if (text.isNotEmpty) {
      if (!_wasTyping) {
        _sendStartTypingEvent(conversationId);
        setState(() {
          _wasTyping = true;
        });
      }
    } else {
      if (_wasTyping) {
        _sendStopTypingEvent();
        setState(() {
          _wasTyping = false;
        });
      }
    }
  }

  void _sendStartTypingEvent(String conversationId) {
    socketService.socket.emit('start_typing', {
      'conversation_id': conversationId,
      'user_id': controller.userId,
    });
    print('Sent start_typing for $conversationId');
  }

  void _sendStopTypingEvent() {
    if (controller.selectedConversation.value == null) return;
    socketService.socket.emit('stop_typing', {
      'conversation_id': controller.selectedConversation.value!.id,
      'user_id': controller.userId,
    });
    print('Sent stop_typing for ${controller.selectedConversation.value!.id}');
  }

  void _sendMessage() {
    if (_wasTyping) {
      _sendStopTypingEvent();
      setState(() {
        _wasTyping = false;
      });
    }
    controller.sendMessage();
  }

  @override
  Widget build(BuildContext context) {
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
                    if (controller.canSendMessage) {
                      _sendMessage();
                    }
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
                  onPressed: controller.canSendMessage ? _sendMessage : null,
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
