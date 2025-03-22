import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:vka_chat_ng/app/constants.dart';

class RegisterController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();
  final isLoading = false.obs;
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
    super.onClose();
  }

  Future<void> register() async {
    isLoading.value = true;
    print(
      'Email: ${emailController.text}, Password: ${passwordController.text}, Username: ${usernameController.text}',
    );
    try {
      final response = await http.post(
        Uri.parse(AppConstants.baseUrl + '/auth/register'),
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
          'username': usernameController.text,
        }),

        headers: {'Content-Type': 'application/json'},
      );
      final data = json.decode(response.body);
      print(data);
      if (response.statusCode == 201) {
        Get.back();
        Get.snackbar('Success', data['message']);
      } else {
        Get.snackbar('Error', data['message']);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
    isLoading.value = false;
  }
}
