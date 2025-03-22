import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/routes/app_pages.dart';
import 'package:vka_chat_ng/theme.dart';

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;

    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: AppTheme.lightTheme(AppTheme.lightColorScheme),
      darkTheme: AppTheme.darkTheme(AppTheme.darkColorScheme),

      // Устанавливаем режим темы на основе предпочтения пользователя
      themeMode:
          brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
