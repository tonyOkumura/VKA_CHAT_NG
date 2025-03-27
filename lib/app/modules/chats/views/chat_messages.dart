import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vka_chat_ng/app/data/message_model.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';

class ChatMessages extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    final screenWidth = MediaQuery.of(context).size.width;

    // Определяем максимальную ширину сообщения в зависимости от размера экрана
    final maxMessageWidth =
        screenWidth < 600
            ? screenWidth *
                0.85 // 85% ширины экрана для мобильных
            : screenWidth < 900
            ? screenWidth *
                0.7 // 70% для планшетов
            : screenWidth * 0.5; // 50% для десктопов

    return Obx(
      () =>
          controller.isLoadingMessages.value
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                controller: controller.messagesScrollController,
                reverse: true,
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final isSender = message.sender_id == controller.userId;
                  final messageDate = DateTime.parse(message.created_at);

                  final showDateHeader =
                      index == controller.messages.length - 1 ||
                      messageDate.day !=
                          DateTime.parse(
                            controller.messages[index + 1].created_at,
                          ).day;

                  return Column(
                    children: [
                      if (showDateHeader) _buildDateHeader(messageDate),
                      Align(
                        alignment:
                            isSender
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxMessageWidth,
                          ),
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            padding: EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color:
                                  isSender
                                      ? Get.theme.colorScheme.tertiaryContainer
                                      : Get
                                          .theme
                                          .colorScheme
                                          .secondaryContainer,
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Get.theme.colorScheme.shadow
                                      .withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  isSender
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                              children: [
                                if (!isSender &&
                                    controller
                                        .selectedConversation
                                        .value!
                                        .is_group_chat) ...[
                                  Text(
                                    message.sender_username,
                                    style: TextStyle(
                                      color: controller.getUserColor(
                                        message.sender_id,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                ],
                                Text(
                                  message.content,
                                  style: TextStyle(
                                    color:
                                        isSender
                                            ? Get
                                                .theme
                                                .colorScheme
                                                .onTertiaryContainer
                                            : Get
                                                .theme
                                                .colorScheme
                                                .onSecondaryContainer,
                                    fontSize: 16,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment:
                                      isSender
                                          ? MainAxisAlignment.end
                                          : MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('HH:mm').format(
                                        DateTime.parse(message.created_at),
                                      ),
                                      style: TextStyle(
                                        color:
                                            isSender
                                                ? Get
                                                    .theme
                                                    .colorScheme
                                                    .onTertiaryContainer
                                                : Get
                                                    .theme
                                                    .colorScheme
                                                    .onSecondaryContainer,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (isSender) ...[
                                      SizedBox(width: 4),
                                      SizedBox(
                                        width: 20,
                                        child: _buildReadStatus(message),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 16.0),
      child: Text(
        _formatDate(date),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Nunito',
          color: Get.theme.colorScheme.secondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "Сегодня";
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return "Вчера";
    } else {
      return "${date.day}.${date.month}.${date.year}";
    }
  }

  Widget _buildReadStatus(Message message) {
    final controller = Get.find<ChatsController>();
    final readByOthers =
        message.read_by_users
            ?.where((user) => user.contact_id != controller.userId)
            .toList() ??
        [];
    final isReadByCurrentUser =
        message.read_by_users?.any(
          (user) => user.contact_id == controller.userId,
        ) ??
        false;
    final readCount = readByOthers.length;

    return PopupMenuButton<void>(
      enabled: true,
      tooltip: '',
      offset: Offset(0, -10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder:
          (context) => [
            if (readCount == 0)
              PopupMenuItem<void>(
                enabled: false,
                height: 40,
                child: Text(
                  'message_no_reads'.tr,
                  style: TextStyle(
                    color: Get.theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              )
            else
              ...readByOthers
                  .map(
                    (user) => PopupMenuItem<void>(
                      enabled: false,
                      height: 50,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: controller.getUserColor(
                              user.contact_id,
                            ),
                            child: Text(
                              user.username[0],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  user.username,
                                  style: TextStyle(
                                    color: Get.theme.colorScheme.onSurface,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'MMM d HH:mm',
                                  ).format(DateTime.parse(user.read_at)),
                                  style: TextStyle(
                                    color:
                                        Get.theme.colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.check,
                            size: 16,
                            color: Get.theme.colorScheme.tertiary,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
          ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isReadByCurrentUser)
            Icon(Icons.check, size: 16)
          else if (readCount == 0)
            Icon(
              Icons.check,
              size: 16,
              color: Get.theme.colorScheme.onTertiaryContainer,
            )
          else
            Icon(
              Icons.done_all,
              size: 16,
              color: Get.theme.colorScheme.onTertiaryContainer,
            ),
        ],
      ),
    );
  }
}
