import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:vka_chat_ng/app/data/contact_model.dart';
import 'package:vka_chat_ng/app/constants.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';
import 'package:vka_chat_ng/app/routes/app_pages.dart';
import 'package:vka_chat_ng/app/services/socket_service.dart';

class ContactsController extends GetxController {
  final _storage = FlutterSecureStorage();
  final _baseUrl = AppConstants.baseUrl;
  final contacts = <Contact>[].obs;
  final isLoading = false.obs;
  final selectedContacts = <String>{}.obs;
  final isSelectionMode = false.obs; // Режим выбора контактов

  @override
  void onInit() {
    super.onInit();
    fetchContacts();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  // Включение режима выбора
  void startSelectionMode() {
    isSelectionMode.value = true;
    selectedContacts.clear();
  }

  // Отмена режима выбора
  void cancelSelectionMode() {
    isSelectionMode.value = false;
    selectedContacts.clear();
  }

  // Подтверждение выбора и создание группы
  Future<void> confirmSelectionAndCreateGroup({
    required String groupName,
  }) async {
    if (selectedContacts.isEmpty) {
      Get.snackbar(
        'Ошибка',
        'Выберите хотя бы одного участника',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      String token = await _storage.read(key: AppKeys.token) ?? '';

      // Получаем первого выбранного контакта
      final firstContactId = selectedContacts.first;

      // 1. Создаем групповой чат с первым контактом
      var createResponse = await http.post(
        Uri.parse('$_baseUrl/conversations/check-or-create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contact_id': firstContactId,
          'is_group_chat': true,
          'name': groupName,
        }),
      );

      if (createResponse.statusCode != 200) {
        throw Exception('Не удалось создать групповой чат');
      }

      final data = jsonDecode(createResponse.body);
      final conversationId = data['conversation_id'];

      final _socketService = Get.find<SocketService>();
      _socketService.joinConversation(conversationId);

      // 2. Добавляем остальных участников
      for (String contactId in selectedContacts.skip(1)) {
        var addParticipantResponse = await http.post(
          Uri.parse('$_baseUrl/conversations/add-participant'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'conversation_id': conversationId,
            'participant_id': contactId,
          }),
        );

        if (addParticipantResponse.statusCode != 200) {
          print('Ошибка при добавлении участника $contactId');
        }
      }

      // Обновляем список чатов и переходим к созданному чату
      final chatsController = Get.find<ChatsController>();
      await chatsController.fetchConversations();

      final conversationIndex = chatsController.conversations.indexWhere(
        (c) => c.id == conversationId,
      );

      if (conversationIndex != -1) {
        chatsController.selectConversation(conversationIndex);
      }
      Get.snackbar('Успешно', 'Групповой чат создан');
    } catch (e) {
      print('Error creating group chat: $e');
      Get.snackbar(
        'Ошибка',
        'Произошла ошибка при создании группового чата',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      cancelSelectionMode();
    }
  }

  // Переключение выбора контакта
  void toggleContactSelection(String contactId) {
    if (!isSelectionMode.value) return;

    if (selectedContacts.contains(contactId)) {
      selectedContacts.remove(contactId);
    } else {
      selectedContacts.add(contactId);
    }
  }

  // Проверка, выбран ли контакт
  bool isContactSelected(String contactId) {
    return selectedContacts.contains(contactId);
  }

  // Очистка выбранных контактов
  void clearSelectedContacts() {
    selectedContacts.clear();
  }

  Future<void> fetchContacts() async {
    isLoading.value = true;
    String token = await _storage.read(key: AppKeys.token) ?? '';
    var response = await http.get(
      Uri.parse('$_baseUrl/contacts'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      contacts.value = data.map((e) => Contact.fromJson(e)).toList();
    }
    isLoading.value = false;
  }

  Future<void> addContact({required String contactEmail}) async {
    String token = await _storage.read(key: AppKeys.token) ?? '';
    var response = await http.post(
      Uri.parse('$_baseUrl/contacts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'contact_email': contactEmail}),
    );
    if (response.statusCode == 200) {
      await fetchContacts();
    }
  }

  Future<void> chechkOrCreateConversation({
    required String contactId,
    required String contactEmail,
  }) async {
    try {
      String token = await _storage.read(key: AppKeys.token) ?? '';
      var response = await http.post(
        Uri.parse('$_baseUrl/conversations/check-or-create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contact_id': contactId,
          'is_group_chat': false,
          'name': 'dialog',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final _socketService = Get.find<SocketService>();
        _socketService.joinConversation(data['conversation_id']);
        print(data);
        final chatsController = Get.find<ChatsController>();
        await chatsController.fetchConversations();

        final conversationIndex = chatsController.conversations.indexWhere(
          (c) => c.id == data['conversation_id'],
        );

        if (conversationIndex != -1) {
          chatsController.selectConversation(conversationIndex);
        }
        Get.snackbar('Успешно', 'Чат создан');
      } else {
        Get.snackbar(
          'Ошибка',
          'Не удалось создать чат',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('Error creating conversation: $e');
      Get.snackbar(
        'Ошибка',
        'Произошла ошибка при создании чата',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
