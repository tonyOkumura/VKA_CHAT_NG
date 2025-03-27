import 'package:get/get.dart';
import 'package:flutter/material.dart';

class LanguageController extends GetxController {
  var locale = Locale('ru', 'RU').obs;

  final languages = [
    {'name': 'Русский', 'code': 'ru_RU'},
    {'name': 'English', 'code': 'en_US'},
  ];

  String get currentLanguageName {
    final currentCode = locale.value.toString();
    return languages.firstWhere(
      (lang) => lang['code'] == currentCode,
      orElse: () => languages.first,
    )['name']!;
  }

  void changeLocale(String languageCode) {
    locale.value = Locale(
      languageCode.split('_')[0],
      languageCode.split('_')[1],
    );
    Get.updateLocale(locale.value);
  }
}
