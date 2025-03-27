import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vka_chat_ng/app/app.dart';
import 'package:vka_chat_ng/app/controllers/language_controller.dart';
import 'package:vka_chat_ng/app/modules/settings/controllers/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация контроллеров
  Get.put(LanguageController());
  Get.put(SettingsController());

  // Загрузка сохраненной темы
  final storage = FlutterSecureStorage();
  final savedTheme = await storage.read(key: 'isDarkMode');
  final isDarkMode = savedTheme == 'true';
  Get.changeThemeMode(isDarkMode ? ThemeMode.dark : ThemeMode.light);

  runApp(MyApp());
}
