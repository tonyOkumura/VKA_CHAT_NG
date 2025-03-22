import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService extends GetxService {
  late IO.Socket _socket;
  final _storage = FlutterSecureStorage();

  Future<SocketService> init() async {
    await initSocket();
    return this;
  }

  Future<void> initSocket() async {
    String token = await _storage.read(key: 'token') ?? '';
    _socket = IO.io(
      'http://localhost:6000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket.onConnect((_) {
      print('Connected to socket server');
    });

    _socket.onDisconnect((_) {
      print('Disconnected from socket server');
    });

    _socket.on('newMessage', (data) {
      print('New message: $data');
    });

    _socket.connect();
  }

  void sendMessage(String conversationId, String content, String senderId) {
    _socket.emit('sendMessage', {
      'conversation_id': conversationId,
      'content': content,
      'sender_id': senderId,
    });
  }

  void joinConversation(String conversationId) {
    _socket.emit('joinConversation', conversationId);
  }

  IO.Socket get socket => _socket;

  @override
  void onClose() {
    _socket.dispose();
    super.onClose();
  }
}
