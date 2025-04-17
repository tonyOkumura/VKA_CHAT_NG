import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vka_chat_ng/app/constants.dart';
import 'package:vka_chat_ng/app/controllers/language_controller.dart';
import 'package:vka_chat_ng/app/modules/settings/controllers/settings_controller.dart';
import 'package:vka_chat_ng/app/services/socket_service.dart';
import 'package:vka_chat_ng/app/services/notification_service.dart';
import 'package:vka_chat_ng/app/services/file_service.dart';
import 'package:window_manager/window_manager.dart';
import 'package:vka_chat_ng/theme.dart';
import 'package:vka_chat_ng/app/translations/app_translations.dart';
import 'package:vka_chat_ng/app/routes/app_pages.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация контроллеров
  Get.put(LanguageController());
  Get.put(SettingsController());

  // Инициализируем сервисы
  final notificationService = Get.put(NotificationService());
  notificationService.onInit();

  // Регистрируем сервисы как синглтоны
  Get.put(SocketService(), permanent: true);
  Get.put(FileService(), permanent: true);

  // Загрузка сохраненной темы
  final storage = FlutterSecureStorage();
  final savedTheme = await storage.read(key: AppKeys.isDarkMode);
  final isDarkMode = savedTheme == 'true';
  Get.changeThemeMode(isDarkMode ? ThemeMode.dark : ThemeMode.light);

  // Инициализируем window_manager
  await windowManager.ensureInitialized();

  // Настраиваем параметры окна
  await windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setTitle('VKA Chat');
    await windowManager.setMinimumSize(const Size(800, 600));
    await windowManager.center();
    await windowManager.show();
  });

  // Инициализируй данные для локалей (например, русской 'ru')
  await initializeDateFormatting('ru', null);

  runApp(MyApp());
}

// Функция для обработки нажатия Esc
void _handleEscKeyPress(RawKeyEvent event) {
  if (event is RawKeyDownEvent &&
      event.logicalKey == LogicalKeyboardKey.escape) {
    // Пытаемся закрыть текущий маршрут/диалог
    if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
      Get.back();
    } else if (Get.key.currentState?.canPop() ?? false) {
      // Используем Get.key.currentState для доступа к Navigator
      Get.back();
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _handleEscKeyPress,
      child: GetMaterialApp(
        title: "VKA Chat",
        theme: AppTheme.lightTheme(AppTheme.lightColorScheme),
        darkTheme: AppTheme.darkTheme(AppTheme.darkColorScheme),
        translations: AppTranslations(),
        locale: Get.find<LanguageController>().locale.value,
        fallbackLocale: const Locale('ru', 'RU'),
        themeMode:
            Get.find<SettingsController>().isDarkMode.value
                ? ThemeMode.dark
                : ThemeMode.light,
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
