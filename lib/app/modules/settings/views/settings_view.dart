import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import 'language_selector.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr), centerTitle: true),
      body: Padding(
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
          ],
        ),
      ),
    );
  }
}
