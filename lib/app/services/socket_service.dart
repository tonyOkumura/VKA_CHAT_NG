import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:vka_chat_ng/app/constants.dart';
import 'package:vka_chat_ng/app/services/notification_service.dart';
import 'package:vka_chat_ng/app/data/models/message_model.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';
import 'package:vka_chat_ng/app/modules/tasks/controllers/tasks_controller.dart';
import 'package:vka_chat_ng/app/modules/tasks/controllers/task_details_controller.dart';
import 'package:vka_chat_ng/app/modules/contacts/controllers/contacts_controller.dart';

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
    socket.on('newTaskCreated', _handleNewTaskCreated);
    socket.on('taskUpdated', _handleTaskUpdated);
    socket.on('taskDeleted', _handleTaskDeleted);
    socket.on('newTaskComment', _handleNewTaskComment);
    socket.on('newTaskAttachment', _handleNewTaskAttachment);
    socket.on('taskAttachmentDeleted', _handleTaskAttachmentDeleted);
    socket.on('newLogEntry', _handleNewLogEntry);
    socket.on('newContactAdded', _handleNewContactAdded);
    socket.on('contactUpdated', _handleContactUpdated);
    socket.on('contactRemoved', _handleContactRemoved);

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

    if (socket.io.options != null) {
      socket.io.options!['extraHeaders'] = {'Authorization': 'Bearer $token'};
    }

    await socket.connect();
    print('Socket reconnected with new token');
  }

  void joinConversation(String conversationId) {
    if (!isInitialized) return;
    socket.emit('joinConversation', conversationId);
    print('Joined conversation room: $conversationId');
  }

  void leaveConversation(String conversationId) {
    if (!isInitialized) return;
    socket.emit('leaveConversation', conversationId);
    print('Left conversation room: $conversationId');
  }

  void joinTasksRoom() {
    if (!isInitialized) return;
    socket.emit('joinGeneralTasks');
    print('Joined general tasks room');
  }

  void joinTaskRoom(String taskId) {
    if (!isInitialized) return;
    socket.emit('joinTaskDetails', taskId);
    print('Joined task details room: $taskId');
  }

  void leaveTaskRoom(String taskId) {
    if (!isInitialized) return;
    socket.emit('leaveTaskDetails', taskId);
    print('Left task details room: $taskId');
  }

  void sendMessage(Map<String, dynamic> message) {
    if (!isInitialized) return;
    socket.emit('sendMessage', message);
  }

  void sendMessageWithParams(
    String conversationId,
    String content,
    String senderId,
  ) {
    if (!isInitialized) return;
    socket.emit('sendMessage', {
      'conversation_id': conversationId,
      'content': content,
      'sender_id': senderId,
    });
  }

  void _handleMessage(dynamic data) {
    print(
      "[SocketService._handleMessage] Raw data received (type: ${data.runtimeType}): $data",
    );
    try {
      if (data == null) {
        print('[SocketService._handleMessage] Received null message data');
        return;
      }

      Map<String, dynamic> messageData;
      if (data is String) {
        print(
          '[SocketService._handleMessage] Data is String, decoding JSON...',
        );
        messageData = jsonDecode(data);
      } else if (data is Map) {
        print('[SocketService._handleMessage] Data is Map, casting...');
        messageData = Map<String, dynamic>.from(data);
      } else {
        print(
          '[SocketService._handleMessage] Received data of unexpected type: ${data.runtimeType}',
        );
        return;
      }

      final message = Message.fromJson(messageData);
      final chatsController =
          Get.isRegistered<ChatsController>()
              ? Get.find<ChatsController>()
              : null;

      bool isChatOpen = false;
      if (chatsController != null) {
        isChatOpen = chatsController.isChatOpen(message.conversation_id);
      }

      if (!isChatOpen) {
        String notificationTitle = message.sender_username;

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

      if (chatsController != null) {
        chatsController.handleIncomingMessage(messageData);
      }
    } catch (e, stackTrace) {
      print('[SocketService._handleMessage] Error handling message: $e');
      print('Stack trace: $stackTrace');
      print('[SocketService._handleMessage] Original raw data on error: $data');
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

  void _handleNewTaskCreated(dynamic data) {
    if (Get.isRegistered<TasksController>()) {
      Get.find<TasksController>().handleNewTaskCreated(data);
    }
  }

  void _handleTaskUpdated(dynamic data) {
    if (Get.isRegistered<TasksController>()) {
      Get.find<TasksController>().handleTaskUpdated(data);
    }
    if (Get.isRegistered<TaskDetailsController>()) {
      Get.find<TaskDetailsController>().handleTaskUpdated(data);
    }
  }

  void _handleTaskDeleted(dynamic data) {
    if (Get.isRegistered<TasksController>()) {
      Get.find<TasksController>().handleTaskDeleted(data);
    }
  }

  void _handleNewTaskComment(dynamic data) {
    if (Get.isRegistered<TaskDetailsController>()) {
      Get.find<TaskDetailsController>().handleNewTaskComment(data);
    }
  }

  void _handleNewTaskAttachment(dynamic data) {
    if (Get.isRegistered<TaskDetailsController>()) {
      Get.find<TaskDetailsController>().handleNewTaskAttachment(data);
    }
  }

  void _handleTaskAttachmentDeleted(dynamic data) {
    if (Get.isRegistered<TaskDetailsController>()) {
      Get.find<TaskDetailsController>().handleTaskAttachmentDeleted(data);
    }
  }

  void _handleNewLogEntry(dynamic data) {
    if (Get.isRegistered<TaskDetailsController>()) {
      Get.find<TaskDetailsController>().handleNewLogEntry(data);
    }
  }

  void _handleNewContactAdded(dynamic data) {
    if (Get.isRegistered<ContactsController>()) {
      Get.find<ContactsController>().handleNewContactAdded(data);
    }
  }

  void _handleContactUpdated(dynamic data) {
    if (Get.isRegistered<ContactsController>()) {
      Get.find<ContactsController>().handleContactUpdated(data);
    }
  }

  void _handleContactRemoved(dynamic data) {
    if (Get.isRegistered<ContactsController>()) {
      Get.find<ContactsController>().handleContactRemoved(data);
    }
  }

  @override
  void onClose() {
    if (isInitialized) {
      socket.disconnect();
    }
    isInitialized = false;
    super.onClose();
  }
}
