import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:vka_chat_ng/app/constants.dart';
import 'package:vka_chat_ng/app/services/notification_service.dart';
import 'package:vka_chat_ng/app/data/message_model.dart';

class SocketService extends GetxService {
  late IO.Socket socket;
  final _storage = FlutterSecureStorage();
  final _baseUrl = AppConstants.baseUrl;
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  @override
  void onInit() {
    super.onInit();
    initSocket();
  }

  Future<SocketService> init() async {
    await initSocket();
    return this;
  }

  Future<void> initSocket() async {
    String? token = await _storage.read(key: AppKeys.token);
    String? userId = await _storage.read(key: AppKeys.userId);

    socket = IO.io(_baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer $token'},
    });

    socket.connect();

    socket.onConnect((_) {});

    socket.on('newMessage', _handleMessage);
    socket.onDisconnect((_) => print('Socket disconnected'));
    socket.onError((error) => print('Socket error: $error'));
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
      final conversationName = data['conversation_name'] as String;

      // Показываем уведомление
      _notificationService.showMessageNotification(message, conversationName);

      // Отправляем событие о новом сообщении
      Get.find<GetxController>().update(['new_message']);
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  @override
  void onClose() {
    socket.disconnect();
    super.onClose();
  }
}
