import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:vka_chat_ng/app/constants.dart';
import 'package:vka_chat_ng/app/services/notification_service.dart';
import 'package:vka_chat_ng/app/data/models/message_model.dart';
import 'package:vka_chat_ng/app/data/models/conversation_model.dart';
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
    if (isInitialized) {
      await reconnectSocket();
      return;
    }

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

  Future<void> reconnectSocket() async {
    if (socket.connected) {
      await socket.disconnect();
    }

    String token = await _storage.read(key: AppKeys.token) ?? '';
    if (token.isEmpty) {
      print('No token found, cannot reconnect socket');
      return;
    }

    // Обновляем заголовки авторизации
    if (socket.io.options != null) {
      socket.io.options!['extraHeaders'] = {'Authorization': 'Bearer $token'};
    }

    // Переподключаемся
    await socket.connect();
    print('Socket reconnected with new token');
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
      if (data == null) {
        print('Received null message data');
        return;
      }

      final message = Message.fromJson(data);
      final chatsController =
          Get.isRegistered<ChatsController>()
              ? Get.find<ChatsController>()
              : null;

      // Проверяем, открыт ли чат с этим сообщением
      bool isChatOpen = false;
      if (chatsController != null) {
        isChatOpen = chatsController.isChatOpen(message.conversation_id);
      }

      // Если чат не открыт, показываем уведомление
      if (!isChatOpen) {
        String notificationTitle = message.sender_username;

        // Пытаемся получить название беседы для групповых чатов
        if (chatsController != null) {
          try {
            final conversation = chatsController.conversations.firstWhere(
              (c) => c.id == message.conversation_id,
              orElse: () => throw Exception('Conversation not found'),
            );

            if (conversation.is_group_chat) {
              notificationTitle =
                  '${conversation.conversation_name} (${message.sender_username})';
            }
          } catch (e) {
            print('Error getting conversation info: $e');
          }
        }

        _notificationService.showMessageNotification(
          message,
          notificationTitle,
        );
      }

      // Обновляем UI через контроллер, если он доступен
      if (chatsController != null) {
        chatsController.handleIncomingMessage(data);
      }
    } catch (e, stackTrace) {
      print('Error handling message: $e');
      print('Stack trace: $stackTrace');
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
