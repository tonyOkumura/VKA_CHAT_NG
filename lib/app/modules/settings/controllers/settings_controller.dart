import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vka_chat_ng/app/constants.dart';

class SettingsController extends GetxController {
  final isDarkMode = false.obs;
  final sendMessageOnEnter = true.obs;
  final _storage = FlutterSecureStorage();

  @override
  void onInit() {
    super.onInit();
    loadTheme();
    loadMessageSendSetting();
  }

  Future<void> loadTheme() async {
    final savedTheme = await _storage.read(key: AppKeys.isDarkMode);
    final isDark = savedTheme == 'true';
    isDarkMode.value = isDark;
    Get.changeThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggleTheme(bool value) async {
    isDarkMode.value = value;
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    await _storage.write(key: AppKeys.isDarkMode, value: value.toString());
  }

  Future<void> loadMessageSendSetting() async {
    final savedSetting = await _storage.read(key: AppKeys.sendMessageOnEnter);
    sendMessageOnEnter.value =
        savedSetting == null ? true : savedSetting == 'true';
  }

  Future<void> toggleMessageSendSetting(bool value) async {
    sendMessageOnEnter.value = value;
    await _storage.write(
      key: AppKeys.sendMessageOnEnter,
      value: value.toString(),
    );
  }
}
