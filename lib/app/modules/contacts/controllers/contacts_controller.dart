import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:vka_chat_ng/app/data/contact_model.dart';
import 'package:vka_chat_ng/app/constants.dart';

class ContactsController extends GetxController {
  final contacts = <Contact>[].obs;
  final isLoading = false.obs;
  final _storage = FlutterSecureStorage();

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

  Future<void> fetchContacts() async {
    isLoading.value = true;
    print('Fetching contacts...');
    String token = await _storage.read(key: 'token') ?? '';
    var response = await http.get(
      Uri.parse(AppConstants.baseUrl + '/contacts'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      contacts.value = data.map((e) => Contact.fromJson(e)).toList();
      print('Contacts fetched successfully.');
    } else {
      print('Failed to fetch contacts: ${response.body}');
    }
    isLoading.value = false;
  }

  Future<String> chechkOrCreateConversation({required String contactId}) async {
    isLoading.value = true;
    print('Checking or creating conversation with $contactId...');
    String token = await _storage.read(key: 'token') ?? '';
    var response = await http.post(
      Uri.parse(AppConstants.baseUrl + '/conversations/check-or-create'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'contactId': contactId}),
    );
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      print('Conversation checked or created successfully.');
      isLoading.value = false;
      return data['conversationId'];
    } else {
      throw Exception(
        'Failed to check or create conversation: ${response.body}',
      );
    }
  }
}
