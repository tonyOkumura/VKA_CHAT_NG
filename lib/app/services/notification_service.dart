import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/data/message_model.dart' as chat;
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';
import 'dart:io' show Platform;

class NotificationService extends GetxService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Настройки для Windows
    const WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
          appName: 'VKA Chat',
          appUserModelId: 'vka_chat_ng',
          guid: 'E8F5E0B0-0B3F-4F5A-9B8C-1D2E3F4A5B6C',
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          windows: initializationSettingsWindows,
        );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Обработка нажатия на уведомление
        if (response.payload != null) {
          final conversationId = response.payload!;
          // Находим чат по ID и открываем его
          final chatsController = Get.find<ChatsController>();
          final index = chatsController.conversations.indexWhere(
            (conv) => conv.id == conversationId,
          );
          if (index != -1) {
            chatsController.selectConversation(index);
          }
          Get.toNamed('/chats');
        }
      },
    );
  }

  Future<void> showMessageNotification(
    chat.Message message,
    String conversationName,
  ) async {
    // Проверяем, находится ли пользователь в текущем чате
    final chatsController = Get.find<ChatsController>();

    // Если пользователь находится в чате, откуда пришло сообщение, не показываем уведомление
    if (chatsController.isChatOpen(message.conversation_id)) {
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'messages',
          'Сообщения',
          channelDescription: 'Уведомления о новых сообщениях',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    // Настройки для Windows
    const WindowsNotificationDetails windowsPlatformChannelSpecifics =
        WindowsNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
      windows: windowsPlatformChannelSpecifics,
    );

    await _notifications.show(
      message.hashCode, // Используем hashCode сообщения как уникальный ID
      conversationName,
      '${message.sender_username}: ${message.content}',
      platformChannelSpecifics,
      payload: message.conversation_id,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
