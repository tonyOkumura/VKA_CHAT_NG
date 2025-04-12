import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/routes/app_pages.dart';
import 'package:vka_chat_ng/app/widgets/main_layout.dart';
import '../controllers/settings_controller.dart';
import 'language_selector.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 3,
      child: Scaffold(
        appBar: AppBar(title: Text('settings'.tr), centerTitle: true),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  ListTile(
                    leading: Icon(Icons.brightness_6),
                    title: Text('theme'.tr),
                    trailing: Obx(
                      () => Switch(
                        value: controller.isDarkMode.value,
                        onChanged: (value) {
                          controller.toggleTheme(value);
                        },
                      ),
                    ),
                  ),
                  const Divider(),
                  const LanguageSelector(),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.account_circle),
                    title: Text('profile'.tr),
                    onTap: () {
                      // Navigate to account settings
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.notifications),
                    title: Text('notifications'.tr),
                    onTap: () {
                      // Navigate to notification settings
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.lock),
                    title: Text('privacy'.tr),
                    onTap: () {
                      // Navigate to privacy settings
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.help),
                    title: Text('help_support'.tr),
                    onTap: () {
                      // Navigate to help & support
                    },
                  ),
                  Container(
                    padding: EdgeInsets.all(16.0),

                    child: ElevatedButton(
                      onPressed: () => Get.offAndToNamed(Routes.CHATS),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Get.theme.colorScheme.primary,
                        foregroundColor: Get.theme.colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'save'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
