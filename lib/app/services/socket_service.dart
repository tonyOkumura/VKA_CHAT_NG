import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:vka_chat_ng/app/constants.dart';
import 'package:vka_chat_ng/app/modules/contacts/controllers/contacts_controller.dart';

class SocketService extends GetxService {
  late IO.Socket socket;
  final _storage = FlutterSecureStorage();
  final _baseUrl = AppConstants.baseUrl;
  late ContactsController contactsController;

  @override
  void onInit() {
    super.onInit();
    contactsController = Get.find<ContactsController>();
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

    socket.onConnect((_) {
      print('Socket connected');
      if (userId != null) {
        socket.emit('authenticate', userId);
      }
    });

    socket.on('userStatusChanged', (data) {
      print('User status changed: $data');
      final userId = data['userId'];
      final isOnline = data['isOnline'];

      // Обновляем статус в контроллере контактов
      contactsController.updateContactStatus(userId, isOnline);
    });

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

  @override
  void onClose() {
    socket.disconnect();
    super.onClose();
  }
}
