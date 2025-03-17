import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:vka_chat_ng/app/data/conversation_model.dart';

class ChatsController extends GetxController {
  final _storage = FlutterSecureStorage();
  final _baseUrl = 'http://127.0.0.1:6000';
  final conversations = <Conversation>[].obs;
  var selectedConversation = Rxn<Conversation>();
  final messageController = TextEditingController();
  final isLoading = false.obs;

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

  @override
  void onInit() {
    super.onInit();
    print('ChatsController initialized.');
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
    print('ChatsController disposed.');
    super.onClose();
  }

  void selectConversation(int index) {
    selectedConversation.value = conversations[index];
    print(
      'Selected conversation: ${selectedConversation.value!.participantName}',
    );
  }

  void sendMessage() {
    if (messageController.text.isNotEmpty &&
        selectedConversation.value != null) {
      print('Sending message: ${messageController.text}');
      // Implement the logic to send a message
      messageController.clear();
    } else {
      print('Message is empty or no conversation selected.');
    }
  }
}
