import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:vka_chat_ng/app/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vka_chat_ng/app/routes/app_pages.dart';
import 'package:vka_chat_ng/app/services/socket_service.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;
  final _storage = FlutterSecureStorage();

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> login() async {
    isLoading.value = true;
    print(
      'Email: ${emailController.text}, Password: ${passwordController.text}',
    );
    try {
      final response = await http.post(
        Uri.parse(AppConstants.baseUrl + '/auth/login'),
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      final data = json.decode(response.body);
      print(data);
      if (response.statusCode == 200) {
        Get.snackbar('Success', data['message']);
        log('Token: ${data['token']}');
        await _storage.write(key: AppKeys.token, value: data['token']);

        // Decode the token and save the userId
        Map<String, dynamic> payload = Jwt.parseJwt(data['token']);
        String userId = payload['id'];
        log('User ID: $userId');
        await _storage.write(key: AppKeys.userId, value: userId);

        Get.offAllNamed(Routes.CHATS);
      } else {
        Get.snackbar('Error', data['message']);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
    isLoading.value = false;
  }
}
