import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsController extends GetxController {
  final isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = Get.isDarkMode;
  }

  Future<void> toggleTheme(bool value) async {
    if (value) {
      Get.changeThemeMode(ThemeMode.dark);
      await FlutterSecureStorage().write(key: 'darkModeEnabled', value: 'true');
      print('Dark mode enabled: $value');
    } else {
      Get.changeThemeMode(ThemeMode.light);
      await FlutterSecureStorage().write(
        key: 'darkModeEnabled',
        value: 'false',
      );
      print('Dark mode enabled: $value');
    }
    isDarkMode.value = value;
  }
}
