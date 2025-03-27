import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/routes/app_pages.dart';
import 'package:vka_chat_ng/app/routes/app_layout.dart';

class SidebarMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (route == null) return null;

    // Проверяем, существует ли уже контроллер
    if (!Get.isRegistered<SidebarController>()) {
      Get.put(SidebarController());
    }

    final sidebarController = Get.find<SidebarController>();
    sidebarController.updateSelectedIndex(route);
    return null;
  }
}
