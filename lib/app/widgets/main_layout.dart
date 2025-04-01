import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:vka_chat_ng/app/routes/app_pages.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex;

  const MainLayout({Key? key, required this.child, required this.selectedIndex})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sidebarXController = SidebarXController(
      selectedIndex: selectedIndex,
      extended: false,
    );

    return Scaffold(
      body: Row(
        children: [
          AppSidebar(controller: sidebarXController),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class AppSidebar extends StatelessWidget {
  final SidebarXController controller;

  const AppSidebar({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SidebarX(
      controller: controller,
      theme: SidebarXTheme(
        margin: EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        hoverColor: Get.theme.colorScheme.surfaceVariant,
        itemTextPadding: EdgeInsets.only(left: 30),
        selectedItemTextPadding: EdgeInsets.only(left: 30),
        itemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Get.theme.colorScheme.outline.withOpacity(0.12),
          ),
        ),
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Get.theme.colorScheme.primaryContainer,
          border: Border.all(
            color: Get.theme.colorScheme.primaryContainer,
            width: 1,
          ),
        ),
        iconTheme: IconThemeData(
          color: Get.theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
        selectedIconTheme: IconThemeData(
          color: Get.theme.colorScheme.onPrimaryContainer,
          size: 20,
        ),
        textStyle: TextStyle(
          color: Get.theme.colorScheme.onSurfaceVariant,
          fontSize: 16,
          fontFamily: 'Nunito',
        ),
        selectedTextStyle: TextStyle(
          color: Get.theme.colorScheme.onPrimaryContainer,
          fontSize: 16,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w600,
        ),
      ),
      extendedTheme: SidebarXTheme(
        width: 200,
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        padding: EdgeInsets.symmetric(horizontal: 10),
        itemTextPadding: EdgeInsets.only(left: 30),
        selectedItemTextPadding: EdgeInsets.only(left: 30),
        itemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Get.theme.colorScheme.outline.withOpacity(0.12),
          ),
        ),
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Get.theme.colorScheme.primaryContainer,
          border: Border.all(
            color: Get.theme.colorScheme.primaryContainer,
            width: 1,
          ),
        ),
        iconTheme: IconThemeData(
          color: Get.theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
        selectedIconTheme: IconThemeData(
          color: Get.theme.colorScheme.onPrimaryContainer,
          size: 20,
        ),
        textStyle: TextStyle(
          color: Get.theme.colorScheme.onSurfaceVariant,
          fontSize: 16,
          fontFamily: 'Nunito',
        ),
        selectedTextStyle: TextStyle(
          color: Get.theme.colorScheme.onPrimaryContainer,
          fontSize: 16,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w600,
        ),
      ),
      items: [
        SidebarXItem(
          icon: Icons.home,
          label: 'messages'.tr,
          onTap: () {
            Get.offNamed(Routes.CHATS);
          },
        ),
        SidebarXItem(
          icon: Icons.contacts,
          label: 'contacts'.tr,
          onTap: () {
            Get.offNamed(Routes.CONTACTS);
          },
        ),
        SidebarXItem(
          icon: Icons.settings,
          label: 'settings'.tr,
          onTap: () {
            Get.offNamed(Routes.SETTINGS);
          },
        ),
        SidebarXItem(
          icon: Icons.logout,
          label: 'logout'.tr,
          onTap: () {
            final _storage = FlutterSecureStorage();
            _storage.delete(key: 'token');
            _storage.delete(key: 'userId');
            print("Logged out");
            Get.offAllNamed(Routes.LOGIN);
          },
        ),
      ],
    );
  }
}
