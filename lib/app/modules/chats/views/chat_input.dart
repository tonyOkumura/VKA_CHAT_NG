import 'dart:io';
// Убираем импорты desktop_drop и cross_file
// import 'package:desktop_drop/desktop_drop.dart';
// import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';
import 'package:vka_chat_ng/app/modules/settings/controllers/settings_controller.dart';
import 'package:vka_chat_ng/app/services/socket_service.dart';
import 'dart:async';

// Определяем намерение для отправки сообщения
class SendIntent extends Intent {}

class ChatInput extends StatefulWidget {
  const ChatInput({super.key});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final ChatsController controller = Get.find<ChatsController>();
  final SettingsController settingsController = Get.find<SettingsController>();
  final SocketService socketService = Get.find<SocketService>();

  bool _wasTyping = false;
  // Убираем _isDragOver
  // final RxBool _isDragOver = false.obs;

  // Обновляем действие, чтобы вызывать sendCurrentInput
  late final SendAction _sendAction = SendAction(controller.sendCurrentInput);

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

  // Этот метод больше не нужен напрямую из UI
  // void _sendMessage() { ... }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Map<ShortcutActivator, Intent> shortcuts = {
      if (settingsController.sendMessageOnEnter.value)
        LogicalKeySet(LogicalKeyboardKey.enter): SendIntent(),
      if (!settingsController.sendMessageOnEnter.value)
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.enter):
            SendIntent(),
    };

    final Map<Type, Action<Intent>> actions = {SendIntent: _sendAction};

    // Убираем DropTarget и внешний Obx
    // return Obx(() => DropTarget(... child:
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        // Убираем зависимость от _isDragOver
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Превью файла здесь больше нет
          Actions(
            actions: actions,
            child: Shortcuts(
              shortcuts: shortcuts,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.attach_file_rounded,
                      color: colorScheme.secondary,
                    ),
                    tooltip: 'Прикрепить файл',
                    onPressed: () async {
                      // Вызываем selectFilesToSend
                      await controller.selectFilesToSend();
                      if (controller.filesToSend.isNotEmpty) {
                        controller.showSendFileDialogFromController();
                      }
                    },
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
                        fillColor: colorScheme.surfaceContainerHighest,
                        isDense: true,
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      cursorColor: colorScheme.primary,
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
                                        : colorScheme.onSurface.withOpacity(
                                          0.3,
                                        ),
                              ),
                      tooltip: 'Отправить сообщение',
                      // Кнопка всегда вызывает sendCurrentInput
                      onPressed:
                          controller.canSendMessage
                              ? controller.sendCurrentInput
                              : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    // )); // Закрывающий Obx от DropTarget
  }
}

// Обновляем SendAction, чтобы вызывать sendCurrentInput
class SendAction extends Action<SendIntent> {
  final Future<void> Function() onSend; // Функция теперь async
  SendAction(this.onSend);

  @override
  Future<void> invoke(SendIntent intent) async {
    await onSend(); // Вызываем sendCurrentInput
  }
}
