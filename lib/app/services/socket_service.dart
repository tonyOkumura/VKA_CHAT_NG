import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:vka_chat_ng/app/constants.dart';
import 'package:vka_chat_ng/app/services/notification_service.dart';
import 'package:vka_chat_ng/app/data/message_model.dart';
import 'package:vka_chat_ng/app/data/conversation_model.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';

class SocketService extends GetxService {
  late IO.Socket socket;
  final _storage = FlutterSecureStorage();
  final _baseUrl = AppConstants.baseUrl;
  final NotificationService _notificationService =
      Get.find<NotificationService>();
  bool isInitialized = false;

  @override
  void onInit() {
    super.onInit();
    initializeSocket();
  }

  Future<void> initializeSocket() async {
    if (isInitialized) return;

    String token = await _storage.read(key: AppKeys.token) ?? '';
    if (token.isEmpty) {
      print('No token found, cannot initialize socket');
      return;
    }

    socket = IO.io(
      _baseUrl,
      IO.OptionBuilder().setTransports(['websocket']).setExtraHeaders({
        'Authorization': 'Bearer $token',
      }).build(),
    );

    socket.onConnect((_) {
      print('Socket connected');
    });

    socket.on('newMessage', _handleMessage);
    socket.on('messageRead', _handleMessageRead);
    socket.on('authenticate', _handleAuthentication);
    socket.on('userStatusChanged', _handleUserStatusChanged);

    socket.onDisconnect((_) {
      print('Socket disconnected');
    });

    socket.onError((error) {
      print('Socket error: $error');
    });

    socket.connect();
    isInitialized = true;
  }

  void joinConversation(String conversationId) {
    socket.emit('joinConversation', conversationId);
  }

  void sendMessage(Map<String, dynamic> message) {
    socket.emit('sendMessage', message);
  }

  void sendMessageWithParams(
    String conversationId,
    String content,
    String senderId,
  ) {
    socket.emit('sendMessage', {
      'conversation_id': conversationId,
      'content': content,
      'sender_id': senderId,
    });
  }

  void _handleMessage(dynamic data) {
    try {
      final message = Message.fromJson(data);

      // Проверяем, открыт ли чат, только если ChatsController существует
      bool isChatOpen = false;
      if (Get.isRegistered<ChatsController>()) {
        isChatOpen = Get.find<ChatsController>().isChatOpen(
          message.conversation_id,
        );
      }

      // Показываем уведомление, если чат не открыт
      if (!isChatOpen) {
        String senderName = message.sender_username;

        // Если ChatsController существует, пытаемся получить название группы
        if (Get.isRegistered<ChatsController>()) {
          final chatsController = Get.find<ChatsController>();
          try {
            final conversation = chatsController.conversations.firstWhere(
              (c) => c.id == message.conversation_id,
            );
            if (conversation.is_group_chat) {
              senderName = conversation.conversation_name;
            }
          } catch (e) {
            print('Error getting conversation info: $e');
          }
        }

        _notificationService.showMessageNotification(message, senderName);
      }

      // Передаем сообщение в контроллер чатов, если он существует
      if (Get.isRegistered<ChatsController>()) {
        Get.find<ChatsController>().handleIncomingMessage(data);
      }
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  void _handleMessageRead(dynamic data) {
    if (Get.isRegistered<ChatsController>()) {
      Get.find<ChatsController>().handleMessageRead(data);
    }
  }

  void _handleAuthentication(dynamic data) {
    if (Get.isRegistered<ChatsController>()) {
      Get.find<ChatsController>().handleAuthentication(data);
    }
  }

  void _handleUserStatusChanged(dynamic data) {
    if (Get.isRegistered<ChatsController>()) {
      Get.find<ChatsController>().handleUserStatusChanged(data);
    }
  }

  @override
  void onClose() {
    socket.disconnect();
    isInitialized = false;
    super.onClose();
  }
}
