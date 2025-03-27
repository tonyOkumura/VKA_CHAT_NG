import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/app.dart';
import 'package:vka_chat_ng/app/controllers/language_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация контроллера языка
  Get.put(LanguageController());

  runApp(MyApp());
}
