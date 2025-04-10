import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';
import 'package:vka_chat_ng/app/data/message_model.dart' as chat;

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final Map<String, bool> _openChats = {};

  @override
  void onInit() {
    super.onInit();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const windowsSettings = WindowsInitializationSettings(
      appName: 'VKA Chat',
      appUserModelId: 'vka_chat_ng',
      guid: 'E8F5E0B0-0B3F-4F5A-9B8C-1D2E3F4A5B6C',
    );

    final initializationSettings = InitializationSettings(
      windows: windowsSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _onNotificationTapped(NotificationResponse details) async {
    print('Notification tapped with payload: ${details.payload}');
    if (details.payload != null) {
      // Активируем окно приложения
      await windowManager.show();
      await windowManager.focus();

      // Переходим на страницу чатов
      Get.toNamed('/chats');
    }
  }

  void setChatOpen(String conversationId, bool isOpen) {
    _openChats[conversationId] = isOpen;
  }

  bool isChatOpen(String conversationId) {
    return _openChats[conversationId] ?? false;
  }

  Future<void> showMessageNotification(
    chat.Message message,
    String conversationName,
  ) async {
    // Проверяем, свернуто ли приложение
    final isMinimized = await windowManager.isMinimized();

    // Показываем уведомление, если приложение свернуто
    if (isMinimized) {
      const windowsDetails = WindowsNotificationDetails();

      const notificationDetails = NotificationDetails(windows: windowsDetails);

      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        conversationName,
        '${message.sender_username}: ${message.content}',
        notificationDetails,
        payload: message.conversation_id,
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
