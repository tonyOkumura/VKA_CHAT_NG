import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';
import 'package:vka_chat_ng/app/modules/chats/views/chat_detail.dart';

class ChatsView extends GetView<ChatsController> {
  const ChatsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // На маленьких экранах показываем либо список, либо детали
          if (constraints.maxWidth < 900) {
            return Obx(
              () =>
                  controller.selectedConversation.value == null
                      ? ChatList()
                      : ChatDetail(),
            );
          }
          // На больших экранах показываем список и детали рядом
          return Row(
            children: [
              // Список чатов
              Container(
                width: 300,
                decoration: BoxDecoration(
                  color: Get.theme.colorScheme.surface,
                  border: Border(
                    right: BorderSide(
                      color: Get.theme.colorScheme.outline.withOpacity(0.12),
                    ),
                  ),
                ),
                child: ChatList(),
              ),
              // Область сообщений
              Expanded(
                child: Obx(() {
                  final selectedConversation =
                      controller.selectedConversation.value;
                  if (selectedConversation == null) {
                    return const Center(child: Text('Выберите чат'));
                  }
                  return ChatDetail();
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ChatList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 900;

        return Container(
          child: Obx(
            () =>
                controller.isLoading.value
                    ? Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: ListView.builder(
                        controller: controller.conversationsScrollController,
                        itemCount: 10,
                        itemBuilder:
                            (context, index) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.white,
                              ),
                              title: Container(
                                width: double.infinity,
                                height: 10.0,
                                color: Colors.white,
                              ),
                              subtitle: Container(
                                width: double.infinity,
                                height: 10.0,
                                color: Colors.white,
                              ),
                            ),
                      ),
                    )
                    : ListView.builder(
                      controller: controller.conversationsScrollController,
                      itemCount: controller.conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = controller.conversations[index];
                        final hasUnread =
                            conversation.unread_count != null &&
                            conversation.unread_count! > 0;

                        return ListTile(
                          leading:
                              conversation.is_group_chat
                                  ? Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Get.theme.colorScheme.tertiary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.group,
                                      color: Get.theme.colorScheme.onTertiary,
                                    ),
                                  )
                                  : CircleAvatar(
                                    radius: 20,
                                    backgroundColor:
                                        Get.theme.colorScheme.primary,
                                    child: Text(
                                      conversation.conversation_name[0]
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: Get.theme.colorScheme.onPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          title: Text(
                            conversation.conversation_name,
                            style: TextStyle(
                              color: Get.theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            conversation.last_message ?? "",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Get.theme.colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('MMMM d, HH:mm').format(
                                  conversation.last_message_time ??
                                      DateTime.now(),
                                ),
                                style: TextStyle(
                                  color: Get.theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 5),
                              if (conversation.unread_count != null &&
                                  conversation.unread_count! > 0)
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color:
                                        Get.theme.colorScheme.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      conversation.unread_count.toString(),
                                      style: TextStyle(
                                        color:
                                            Get
                                                .theme
                                                .colorScheme
                                                .onPrimaryContainer,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            controller.selectConversation(index);
                          },
                        );
                      },
                    ),
          ),
        );
      },
    );
  }

  String _formatMessageTime(DateTime messageTime) {
    final now = DateTime.now();
    final difference = now.difference(messageTime);

    if (difference.inDays > 7) {
      return DateFormat('dd.MM.yyyy').format(messageTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}д';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м';
    } else {
      return 'только что';
    }
  }
}
