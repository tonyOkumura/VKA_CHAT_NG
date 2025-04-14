import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:vka_chat_ng/app/data/models/contact_model.dart';
import 'package:vka_chat_ng/app/constants.dart';
import 'package:vka_chat_ng/app/services/socket_service.dart';
import 'package:flutter/material.dart';

class ContactsController extends GetxController {
  final _storage = FlutterSecureStorage();
  final _baseUrl = AppConstants.baseUrl;
  final contacts = <Contact>[].obs;
  final filteredContacts = <Contact>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final selectedContacts = <String>{}.obs;
  final isSelectionMode = false.obs;
  final isCreatingGroup = false.obs;
  final groupNameController = TextEditingController();
  final groupNameFocusNode = FocusNode();
  final groupNameError = RxnString();
  final isCreatingDialog = false.obs;
  final dialogNameController = TextEditingController();
  final dialogNameFocusNode = FocusNode();
  final dialogNameError = RxnString();
  final selectedContact = Rxn<Contact>();
  final userColors = <String, Color>{}.obs;
  final userColorsList = [
    Colors.blue.shade700,
    Colors.red.shade700,
    Colors.green.shade700,
    Colors.orange.shade700,
    Colors.purple.shade700,
    Colors.teal.shade700,
    Colors.pink.shade700,
    Colors.indigo.shade700,
    Colors.amber.shade700,
    Colors.cyan.shade700,
    Colors.grey.shade700,
    Colors.lime.shade700,
    Colors.deepPurple.shade700,
    Colors.deepOrange.shade700,
    Colors.blue.shade300,
    Colors.red.shade300,
    Colors.green.shade300,
    Colors.orange.shade300,
    Colors.purple.shade300,
    Colors.teal.shade300,
    Colors.pink.shade300,
    Colors.indigo.shade300,
    Colors.amber.shade300,
    Colors.cyan.shade300,
    Colors.grey.shade300,
    Colors.lime.shade300,
    Colors.deepPurple.shade300,
    Colors.deepOrange.shade300,
  ];

  @override
  void onInit() {
    super.onInit();
    fetchContacts();
    print('ContactsController initialized.');
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  // Отмена режима выбора
  void cancelSelectionMode() {
    isSelectionMode.value = false;
    selectedContacts.clear();
  }

  Future<void> fetchContacts() async {
    isLoading.value = true;
    print('Fetching contacts...');
    String token = await _storage.read(key: AppKeys.token) ?? '';
    var response = await http.get(
      Uri.parse('$_baseUrl/contacts'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      contacts.value = data.map((e) => Contact.fromJson(e)).toList();
      filterContacts(searchQuery.value);
      print('Contacts fetched successfully.');
    } else {
      print('Failed to fetch contacts: ${response.body}');
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
    if (response.statusCode == 201) {
      Get.snackbar('Успешно', 'Контакт добавлен');
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
        Uri.parse('$_baseUrl/conversations/dialog'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'contact_id': contactId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final _socketService = Get.find<SocketService>();
        _socketService.joinConversation(data['conversation_id']);
        Get.snackbar("Успешно", "Чат создан");
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

  void filterContacts(String query) {
    if (query.isEmpty) {
      filteredContacts.value = contacts;
      return;
    }

    query = query.toLowerCase();
    filteredContacts.value =
        contacts.where((contact) {
          return contact.username.toLowerCase().contains(query) ||
              contact.email.toLowerCase().contains(query);
        }).toList();
  }

  Future<void> createGroup() async {
    if (selectedContacts.isEmpty) {
      Get.snackbar(
        'Ошибка',
        'Выберите хотя бы одного участника',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (groupNameController.text.isEmpty) {
      groupNameError.value = 'Введите название группы';
      return;
    }

    isCreatingGroup.value = true;
    String token = await _storage.read(key: AppKeys.token) ?? '';
    var response = await http.post(
      Uri.parse('$_baseUrl/conversations/group'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': groupNameController.text,
        'participants': selectedContacts.toList(),
      }),
    );

    if (response.statusCode == 201) {
      Get.back();
      Get.snackbar('Успех', 'Группа создана', snackPosition: SnackPosition.TOP);
      selectedContacts.clear();
      isSelectionMode.value = false;
      groupNameController.clear();
      await fetchContacts();
    } else {
      Get.snackbar(
        'Ошибка',
        'Не удалось создать группу',
        snackPosition: SnackPosition.TOP,
      );
    }
    isCreatingGroup.value = false;
  }

  Color getUserColor(String userId) {
    // Генерируем цвет на основе ID пользователя
    final hash = userId.hashCode;
    final hue = (hash % 360).abs();
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.7, 0.5).toColor();
  }
}
