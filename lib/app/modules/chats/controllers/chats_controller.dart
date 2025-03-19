import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:vka_chat_ng/app/constants.dart';
import 'package:vka_chat_ng/app/data/conversation_model.dart';
import 'package:vka_chat_ng/app/data/message_model.dart';
import 'package:vka_chat_ng/app/services/socket_service.dart';

class ChatsController extends GetxController {
  final _storage = FlutterSecureStorage();
  final _baseUrl = AppConstants.baseUrl;
  final conversations = <Conversation>[].obs;
  final messages = <Message>[].obs;
  var selectedConversation = Rxn<Conversation>();
  final messageController = TextEditingController();
  final isLoading = false.obs;
  final isLoadingMessages = false.obs;
  late SocketService _socketService;
  late String userId;

  @override
  void onInit() {
    super.onInit();
    print('ChatsController initialized.');
    _socketService = Get.find<SocketService>();
    _socketService.socket.on('newMessage', _handleIncomingMessage);
    _initializeUserId();
    fetchConversations();
  }

  @override
  void onReady() {
    super.onReady();
    print('ChatsController is ready.');
  }

  @override
  void onClose() {
    messageController.dispose();
    _socketService.socket.off('newMessage', _handleIncomingMessage);
    print('ChatsController disposed.');
    super.onClose();
  }

  Future<void> _initializeUserId() async {
    userId = await _storage.read(key: 'userId') ?? '';
    print('User ID: $userId');
  }

  void selectConversation(int index) {
    selectedConversation.value = conversations[index];
    print(
      'Selected conversation: ${selectedConversation.value!.participantName}',
    );
    _socketService.joinConversation(selectedConversation.value!.id);
    fetchMessages();
  }

  Future<void> fetchConversations() async {
    isLoading.value = true;
    await Future.delayed(Duration(seconds: 5));
    print('Fetching conversations...');
    String token = await _storage.read(key: 'token') ?? '';
    var response = await http.get(
      Uri.parse('$_baseUrl/conversations'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      conversations.value = data.map((e) => Conversation.fromJson(e)).toList();
      print('Conversations fetched successfully.');
    } else {
      print('Failed to fetch conversations: ${response.body}');
    }
    isLoading.value = false;
  }

  void fetchMessages() async {
    isLoadingMessages.value = true;
    messages.clear();
    print('Fetching messages...');
    String token = await _storage.read(key: 'token') ?? '';
    var response = await http.get(
      Uri.parse('$_baseUrl/messages/${selectedConversation.value!.id}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      messages.addAll(data.map((e) => Message.fromJson(e)));

      print('Messages fetched successfully.');
    } else {
      print('Failed to fetch messages: ${response.body}');
    }
    isLoadingMessages.value = false;
  }

  Future<void> sendMessage() async {
    if (messageController.text.isNotEmpty &&
        selectedConversation.value != null) {
      print('Sending message: ${messageController.text}');
      final newMessage = Message(
        id: DateTime.now().toString(), // Generate a temporary ID
        conversationId: selectedConversation.value!.id,
        senderId: userId,
        content: messageController.text,
        createdAt: DateTime.now().toIso8601String(),
      );

      _socketService.sendMessage(
        selectedConversation.value!.id,
        messageController.text,
        userId,
      );
      messageController.clear();
    } else {
      print('Message is empty or no conversation selected.');
    }
  }

  void _handleIncomingMessage(dynamic data) {
    print('New message received: $data');
    final message = Message.fromJson(data);
    if (selectedConversation.value != null &&
        message.conversationId == selectedConversation.value!.id) {
      messages.add(message);
    }
  }
}
