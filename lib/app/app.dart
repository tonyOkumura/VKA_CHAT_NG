import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/routes/app_pages.dart';
import 'package:vka_chat_ng/theme.dart';
import 'package:vka_chat_ng/util.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;
    TextTheme textTheme = createTextTheme(context, "Noto Sans", "Average Sans");
    MaterialTheme theme = MaterialTheme(textTheme);
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: theme.light(),
      darkTheme: theme.dark(),
      themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,

      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
