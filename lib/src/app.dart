import 'package:flutter/material.dart';
import 'package:vka_chat_ng/src/pages/chat_page.dart';
import 'package:vka_chat_ng/src/pages/login_page.dart';
import 'package:vka_chat_ng/src/pages/messages_page.dart';
import 'package:vka_chat_ng/src/pages/register_page.dart';
import 'package:vka_chat_ng/theme/theme.dart';
import 'package:vka_chat_ng/theme/util.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;
    TextTheme textTheme = createTextTheme(context, "Golos Text", "Noto Sans");
    MaterialTheme theme = MaterialTheme(textTheme);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
      home: RegisterPage(),
    );
  }
}
