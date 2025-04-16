import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vka_chat_ng/app/data/models/message_model.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';

class ChatReadStatus extends StatelessWidget {
  final Message message;

  const ChatReadStatus({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
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
