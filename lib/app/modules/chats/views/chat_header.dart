import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/data/models/conversation_model.dart'; // Import Conversation model
import 'package:vka_chat_ng/app/data/models/chat_participant_model.dart'; // Import ChatParticipant
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';
import 'package:vka_chat_ng/app/modules/chats/views/widgets/chat_participants_popup.dart';
import 'package:vka_chat_ng/app/modules/chats/views/widgets/group_settings_dialog.dart';

class ChatHeader extends StatelessWidget {
  const ChatHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isSmallScreen = MediaQuery.of(context).size.width < 900;

    return Obx(() {
      final conversation = controller.selectedConversation.value;
      if (conversation == null) {
        return Container(
          height: 68,
          color: colorScheme.surface, // Use surface color for placeholder
        );
      }

      String participantId = '';
      if (!conversation.is_group_chat &&
          conversation.participants != null &&
          conversation.participants!.isNotEmpty) {
        participantId =
            conversation.participants!
                .firstWhereOrNull((p) => p.user_id != controller.userId)
                ?.user_id ??
            '';
      }

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface, // Specify color here
          border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
          ),
        ),
        // Use Obx to switch between normal header and search bar
        child: Obx(
          () =>
              controller.isChatSearchActive.value
                  // --- Search Bar UI ---
                  ? Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        tooltip: 'Отменить поиск',
                        onPressed:
                            controller.toggleChatSearch, // Close search mode
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller.chatSearchController,
                          focusNode: controller.chatSearchFocusNode,
                          autofocus:
                              true, // Automatically focus when search opens
                          decoration: InputDecoration(
                            hintText: 'Поиск в чате...',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant.withOpacity(
                                0.7,
                              ),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                          ),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      // Optionally add clear button
                      if (controller.chatSearchQuery.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: colorScheme.secondary,
                            size: 20,
                          ),
                          tooltip: 'Очистить поиск',
                          onPressed:
                              () => controller.chatSearchController.clear(),
                        ),
                    ],
                  )
                  // --- Normal Header UI ---
                  : Row(
                    children: [
                      if (isSmallScreen)
                        IconButton(
                          icon: Icon(
                            Icons
                                .arrow_back_ios_new_rounded, // Different back icon
                            color: colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () => controller.selectConversation(null),
                          tooltip: 'Назад к списку чатов',
                        ),
                      if (isSmallScreen) SizedBox(width: 4),
                      _buildAvatar(
                        conversation,
                        controller,
                        colorScheme,
                        participantId,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            return conversation.is_group_chat
                                ? _buildGroupHeaderContent(
                                  context,
                                  conversation,
                                  theme,
                                )
                                : _buildDialogHeaderContent(
                                  conversation,
                                  theme,
                                );
                          },
                        ),
                      ),
                      SizedBox(width: 8), // Add spacing before options
                      // Search Icon
                      IconButton(
                        icon: Icon(
                          Icons.search,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        tooltip: 'Поиск в чате',
                        onPressed:
                            controller.toggleChatSearch, // Open search mode
                      ),
                      // More Options Icon
                      IconButton(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          // Show group settings if it's a group chat
                          if (conversation.is_group_chat) {
                            _showGroupSettingsDialog(context, conversation);
                          } else {
                            // TODO: Implement options for dialog chats
                            Get.snackbar(
                              'Info',
                              'Опции диалога пока не реализованы',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        },
                        tooltip:
                            conversation.is_group_chat
                                ? 'Настройки группы'
                                : 'Опции чата',
                      ),
                    ],
                  ),
        ),
      );
    });
  }

  Widget _buildAvatar(
    Conversation conversation,
    ChatsController controller,
    ColorScheme colorScheme,
    String participantId,
  ) {
    if (conversation.is_group_chat) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.group_outlined,
          color: colorScheme.onTertiaryContainer,
          size: 24, // Slightly smaller icon
        ),
      );
    } else {
      return CircleAvatar(
        radius: 20,
        backgroundColor: controller.getUserColor(participantId),
        child: Text(
          conversation.conversation_name.isNotEmpty
              ? conversation.conversation_name[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  Widget _buildGroupHeaderContent(
    BuildContext context,
    Conversation conversation,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;
    final controller = Get.find<ChatsController>(); // Get controller
    final participantCount = conversation.participants?.length ?? 0;

    return InkWell(
      onTap: () => ChatParticipantsPopup.show(context, conversation),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              conversation.conversation_name,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Show participant count OR typing indicator
            Obx(() {
              final typingUserIds =
                  controller.typingUsers[conversation.id]
                      ?.where((id) => id != controller.userId) // Exclude self
                      .toSet() ??
                  {};

              if (typingUserIds.isNotEmpty) {
                // Build typing indicator string
                String typingText = _buildTypingIndicatorText(
                  typingUserIds,
                  conversation.participants,
                );
                return Text(
                  typingText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary, // Use primary color
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              } else {
                // Show participant count if no one is typing
                if (participantCount > 0) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$participantCount участ.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  );
                } else {
                  return SizedBox(height: 16);
                }
              }
            }),
          ],
        ),
      ),
    );
  }

  // Helper to build the typing indicator text for groups
  String _buildTypingIndicatorText(
    Set<String> typingUserIds,
    List<ChatParticipant>? participants,
  ) {
    if (participants == null || participants.isEmpty) {
      return 'Печатает...'; // Fallback
    }

    List<String> typingNames = [];
    for (String userId in typingUserIds) {
      final participant = participants.firstWhereOrNull(
        (p) => p.user_id == userId,
      );
      typingNames.add(
        participant?.username ?? 'Кто-то',
      ); // Add name or fallback (safe due to firstWhereOrNull)
    }

    if (typingNames.length == 1) {
      return '${typingNames[0]} печатает...';
    } else if (typingNames.length == 2) {
      return '${typingNames[0]} и ${typingNames[1]} печатают...';
    } else if (typingNames.length > 2) {
      return 'Несколько человек печатают...';
    } else {
      return ''; // Should not happen if typingUserIds is not empty
    }
  }

  Widget _buildDialogHeaderContent(Conversation conversation, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final controller = Get.find<ChatsController>(); // Get controller

    // Find the other participant's ID
    final otherParticipant = conversation.participants?.firstWhereOrNull(
      (p) => p.user_id != controller.userId,
    );
    final otherParticipantId = otherParticipant?.user_id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          conversation.conversation_name,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Display online status if we found the other participant
        if (otherParticipantId != null)
          Obx(() {
            // Get the latest status from the reactive map, fallback to initial status from participant object
            final isOnline =
                controller.onlineUsers[otherParticipantId] ??
                otherParticipant?.is_online ??
                false;
            // Check if the other user is typing
            final isTyping =
                controller.typingUsers[conversation.id]?.contains(
                  otherParticipantId,
                ) ??
                false;

            if (isTyping) {
              return Text(
                'Печатает...', // Typing indicator text
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary, // Use primary color for typing?
                  fontStyle: FontStyle.italic,
                ),
              );
            } else if (isOnline) {
              return Text(
                'Online',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      Colors.green.shade600, // Use a distinct color for online
                  fontWeight: FontWeight.w500,
                ),
              );
            } else {
              // Optionally show offline status or last seen (if available)
              // return Text('Offline', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant));
              return SizedBox(height: 2); // Keep height consistent
            }
          })
        else
          SizedBox(height: 2), // Placeholder if participant not found
      ],
    );
  }

  // Function to show the group settings dialog
  void _showGroupSettingsDialog(
    BuildContext context,
    Conversation conversation,
  ) {
    Get.dialog(
      GroupSettingsDialog(conversation: conversation), // Use the new widget
      // Optional: barrierDismissible, etc.
      barrierDismissible: true,
    );
  }
}
