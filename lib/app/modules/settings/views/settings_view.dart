import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.brightness_6),
              title: Text('Dark Mode'),
              trailing: Obx(
                () => Switch(
                  value: controller.isDarkMode.value,
                  onChanged: (value) {
                    controller.toggleTheme(value);
                  },
                ),
              ),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Account'),
              onTap: () {
                // Navigate to account settings
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notifications'),
              onTap: () {
                // Navigate to notification settings
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.lock),
              title: Text('Privacy'),
              onTap: () {
                // Navigate to privacy settings
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.help),
              title: Text('Help & Support'),
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
