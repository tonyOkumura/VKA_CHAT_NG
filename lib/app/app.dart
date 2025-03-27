import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/routes/app_pages.dart';
import 'package:vka_chat_ng/theme.dart';
import 'package:vka_chat_ng/app/translations/app_translations.dart';
import 'package:vka_chat_ng/app/controllers/language_controller.dart';

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final brightness = View.of(context).platformDispatcher.platformBrightness;

    return GetMaterialApp(
      title: 'VKA Chat',
      theme: AppTheme.lightTheme(AppTheme.lightColorScheme),
      darkTheme: AppTheme.darkTheme(AppTheme.darkColorScheme),
      translations: AppTranslations(),
      locale: languageController.locale.value,
      fallbackLocale: const Locale('ru', 'RU'),
      // Устанавливаем режим темы на основе предпочтения пользователя
      themeMode:
          brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
