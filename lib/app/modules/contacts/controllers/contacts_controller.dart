import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:vka_chat_ng/app/data/models/contact_model.dart';
import 'package:vka_chat_ng/app/constants.dart';
import 'package:vka_chat_ng/app/data/models/user_model.dart';
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
  final globalUsers = <User>[].obs;
  final filteredGlobalUsers = <User>[].obs;
  final isFetchingGlobalUsers = false.obs;
  final globalSearchQuery = ''.obs;
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

  late String currentUserId;
  late final SocketService _socketService;

  @override
  void onInit() async {
    super.onInit();
    _socketService = Get.find<SocketService>();
    await _getCurrentUserId();
    await fetchContacts();
    print('ContactsController initialized.');
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    groupNameController.dispose();
    groupNameFocusNode.dispose();
    dialogNameController.dispose();
    dialogNameFocusNode.dispose();
    super.onClose();
  }

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
      List data = jsonDecode(utf8.decode(response.bodyBytes));
      contacts.value = data.map((e) => Contact.fromJson(e)).toList();
      for (var contact in contacts) {
        _ensureUserColor(contact.id);
      }
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
      Get.back();
    } else {
      Get.snackbar(
        'Ошибка',
        'Не удалось добавить контакт: ${response.reasonPhrase}',
        snackPosition: SnackPosition.BOTTOM,
      );
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
    searchQuery.value = query;
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
      groupNameError.value = null;
    } else {
      Get.snackbar(
        'Ошибка',
        'Не удалось создать группу',
        snackPosition: SnackPosition.TOP,
      );
    }
    isCreatingGroup.value = false;
  }

  Future<void> _getCurrentUserId() async {
    currentUserId = await _storage.read(key: AppKeys.userId) ?? '';
    if (currentUserId.isEmpty) {
      print('Error: Could not retrieve current user ID.');
    } else {
      print('Current User ID: $currentUserId');
    }
  }

  Future<void> fetchGlobalUsers() async {
    if (globalUsers.isNotEmpty) {
      filterGlobalUsers('');
      return;
    }

    isFetchingGlobalUsers.value = true;
    print('Fetching global users...');
    String token = await _storage.read(key: AppKeys.token) ?? '';
    if (token.isEmpty) {
      print('No token found for fetching global users.');
      Get.snackbar('Ошибка', 'Отсутствует токен авторизации.');
      isFetchingGlobalUsers.value = false;
      return;
    }
    if (currentUserId.isEmpty) {
      print('Current user ID is empty. Cannot filter.');
      Get.snackbar('Ошибка', 'Не удалось определить текущего пользователя.');
      isFetchingGlobalUsers.value = false;
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/all'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(utf8.decode(response.bodyBytes));
        List<User> allUsers = data.map((e) => User.fromJson(e)).toList();

        final contactIds = contacts.map((c) => c.id).toSet();

        globalUsers.value =
            allUsers.where((user) {
              return user.id != currentUserId && !contactIds.contains(user.id);
            }).toList();

        for (var user in globalUsers) {
          _ensureUserColor(user.id);
        }

        filterGlobalUsers('');
        print(
          'Global users fetched and filtered successfully: ${globalUsers.length} users.',
        );
      } else {
        print(
          'Failed to fetch global users: ${response.statusCode} ${response.body}',
        );
        Get.snackbar(
          'Ошибка',
          'Не удалось загрузить список пользователей: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Error fetching global users: $e');
      Get.snackbar('Ошибка', 'Произошла ошибка при загрузке пользователей.');
    } finally {
      isFetchingGlobalUsers.value = false;
    }
  }

  void filterGlobalUsers(String query) {
    globalSearchQuery.value = query;
    if (query.isEmpty) {
      filteredGlobalUsers.value = globalUsers;
    } else {
      query = query.toLowerCase();
      filteredGlobalUsers.value =
          globalUsers.where((user) {
            return user.username.toLowerCase().contains(query) ||
                user.email.toLowerCase().contains(query);
          }).toList();
    }
  }

  Color _ensureUserColor(String userId) {
    if (!userColors.containsKey(userId)) {
      final colorIndex = userColors.length % userColorsList.length;
      final color = userColorsList[colorIndex];
      userColors[userId] = color;
      return color;
    }
    return userColors[userId]!;
  }

  Color getUserColor(String userId) {
    if (userColors.containsKey(userId)) {
      return userColors[userId]!;
    } else {
      print(
        'Warning: Color for userId $userId not pre-assigned. Generating fallback color.',
      );
      final hash = userId.hashCode;
      final hue = (hash % 360).abs();
      return HSLColor.fromAHSL(1, hue.toDouble(), 0.7, 0.5).toColor();
    }
  }

  void handleNewContactAdded(dynamic data) {
    print("[WebSocket Contacts] Received newContactAdded: $data");
    try {
      final newContact = Contact.fromJson(data as Map<String, dynamic>);
      if (!contacts.any((c) => c.id == newContact.id)) {
        _ensureUserColor(newContact.id);
        contacts.add(newContact);
        filterContacts(searchQuery.value);
        print("  New contact ${newContact.username} added via WebSocket.");
      }
    } catch (e) {
      print("Error processing newContactAdded event: $e");
    }
  }

  void handleContactUpdated(dynamic data) {
    print("[WebSocket Contacts] Received contactUpdated: $data");
    try {
      final updatedContact = Contact.fromJson(data as Map<String, dynamic>);
      final index = contacts.indexWhere((c) => c.id == updatedContact.id);
      if (index != -1) {
        contacts[index] = updatedContact;
        filterContacts(searchQuery.value);
        print("  Contact ${updatedContact.username} updated via WebSocket.");
      }
    } catch (e) {
      print("Error processing contactUpdated event: $e");
    }
  }

  void handleContactRemoved(dynamic data) {
    print("[WebSocket Contacts] Received contactRemoved: $data");
    try {
      final contactId = data['contactId'] as String?;
      if (contactId != null) {
        final contactExists = contacts.any((c) => c.id == contactId);
        if (contactExists) {
          contacts.removeWhere((c) => c.id == contactId);
          filterContacts(searchQuery.value);
          print("  Contact $contactId removed via WebSocket.");
        }
      }
    } catch (e) {
      print("Error processing contactRemoved event: $e");
    }
  }
}
