import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/controllers/language_controller.dart';

class LanguageSelector extends GetView<LanguageController> {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text('language'.tr),
      subtitle: Text(controller.currentLanguageName),
      onTap: () {
        Get.bottomSheet(
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'language'.tr,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Divider(),
                  ...controller.languages.map(
                    (lang) => ListTile(
                      title: Text(lang['name']!),
                      trailing:
                          controller.currentLanguageName == lang['name']
                              ? const Icon(Icons.check)
                              : null,
                      onTap: () {
                        controller.changeLocale(lang['code']!);
                        Get.back();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
