import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vka_chat_ng/app/app.dart';
import 'package:vka_chat_ng/app/controllers/language_controller.dart';
import 'package:vka_chat_ng/app/modules/settings/controllers/settings_controller.dart';
import 'package:vka_chat_ng/app/services/socket_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация контроллеров
  Get.put(LanguageController());
  Get.put(SettingsController());
  await Get.putAsync<SocketService>(() async {
    final service = SocketService();
    return await service.init();
  });

  // Загрузка сохраненной темы
  final storage = FlutterSecureStorage();
  final savedTheme = await storage.read(key: 'isDarkMode');
  final isDarkMode = savedTheme == 'true';
  Get.changeThemeMode(isDarkMode ? ThemeMode.dark : ThemeMode.light);

  runApp(MyApp());
}
