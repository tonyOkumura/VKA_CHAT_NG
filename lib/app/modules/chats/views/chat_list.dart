import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';
import 'package:vka_chat_ng/app/modules/chats/views/widgets/chat_list_search.dart';
import 'package:vka_chat_ng/app/modules/chats/views/widgets/chat_list_tabs.dart';
import 'package:vka_chat_ng/app/modules/chats/views/widgets/conversation_list_tile.dart';

class ChatList extends StatelessWidget {
  const ChatList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      child: Column(
        children: [
          // Tabs (Groups / Dialogs)
          ChatListTabs(),

          // Search Bar
          ChatListSearch(),

          // Conversation List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.filteredConversations.isEmpty) {
                return _buildShimmerList(colorScheme);
              }
              if (controller.filteredConversations.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      controller.searchText.value.isEmpty
                          ? 'no_${controller.selectedTab.value == 0 ? 'groups' : 'dialogs'}_found'
                              .tr
                          : 'no_search_results'.tr,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: controller.filteredConversations.length,
                itemBuilder: (context, index) {
                  final conversation = controller.filteredConversations[index];
                  return ConversationListTile(
                    conversation: conversation,
                    onTap: () {
                      final originalIndex = controller.conversations.indexWhere(
                        (c) => c.id == conversation.id,
                      );
                      if (originalIndex != -1) {
                        controller.selectConversation(originalIndex);
                      }
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList(ColorScheme colorScheme) {
    return Shimmer.fromColors(
      baseColor: colorScheme.onSurface.withOpacity(0.04),
      highlightColor: colorScheme.onSurface.withOpacity(0.02),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: 10,
        itemBuilder:
            (context, index) => ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 6.0,
              ),
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
              title: Container(
                height: 14.0,
                color: colorScheme.surfaceContainerHighest,
                margin: EdgeInsets.only(bottom: 8.0, right: 60),
              ),
              subtitle: Container(
                height: 10.0,
                color: colorScheme.surfaceContainerHighest,
                margin: EdgeInsets.only(right: 100),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 40,
                    height: 10,
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: 20,
                    height: 18,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
              dense: true,
              visualDensity: VisualDensity.compact,
            ),
      ),
    );
  }
}
