import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vka_chat_ng/app/data/models/conversation_model.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';

class ConversationListTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const ConversationListTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unreadCount = conversation.unread_count ?? 0;

    return Obx(() {
      final bool isSelected =
          controller.selectedConversation.value?.id == conversation.id;

      // Determine colors based on selection state
      final cardColor =
          isSelected
              ? colorScheme.secondaryContainer.withOpacity(0.6)
              : colorScheme.surfaceContainerLow;
      final titleColor =
          isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface;
      final subtitleColor =
          isSelected
              ? colorScheme.onSecondaryContainer.withOpacity(0.8)
              : colorScheme.onSurfaceVariant;
      final timeColor =
          isSelected
              ? colorScheme.onSecondaryContainer.withOpacity(0.8)
              : colorScheme.onSurfaceVariant;

      // Use Card as the main container
      return Card(
        // Remove default padding/margin if Card handles it
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        elevation: isSelected ? 2.0 : 0.5, // Slightly elevate selected card
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ), // Consistent rounding
        color: cardColor, // Use dynamic card color
        clipBehavior: Clip.antiAlias, // Ensure content respects card shape
        child: ListTile(
          // Remove properties now handled by Card or specific styling
          // selected: isSelected,
          // selectedTileColor: ...,
          // shape: ...,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ), // Increased vertical padding slightly
          leading: _buildLeading(controller, colorScheme),
          title: Text(
            conversation.conversation_name,
            style: theme.textTheme.titleMedium?.copyWith(
              color: titleColor,
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            conversation.last_message ?? "",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(color: subtitleColor),
          ),
          trailing: _buildTrailing(theme, colorScheme, unreadCount, timeColor),
          onTap: onTap, // Keep onTap on ListTile for ripple effect
          dense: false, // Let ListTile have normal density within Card
          visualDensity: VisualDensity.standard,
        ),
      );
    });
  }

  Widget _buildLeading(ChatsController controller, ColorScheme colorScheme) {
    if (conversation.is_group_chat) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.group_outlined,
          color: colorScheme.onTertiaryContainer,
          size: 26,
        ),
      );
    } else {
      final participantId =
          conversation.participants
              ?.firstWhereOrNull((p) => p.user_id != controller.userId)
              ?.user_id ??
          '';

      return CircleAvatar(
        radius: 22,
        backgroundColor: controller.getUserColor(participantId),
        child: Text(
          conversation.conversation_name.isNotEmpty
              ? conversation.conversation_name[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  Widget _buildTrailing(
    ThemeData theme,
    ColorScheme colorScheme,
    int unreadCount,
    Color timeColor, // Pass timeColor directly
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          conversation.last_message_time != null
              ? DateFormat('HH:mm').format(conversation.last_message_time!)
              : '',
          style: theme.textTheme.bodySmall?.copyWith(color: timeColor),
        ),
        SizedBox(height: 6),
        SizedBox(
          height: 18,
          // Wrap the badge area with AnimatedSwitcher
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child:
                unreadCount > 0
                    ? Container(
                      key: ValueKey(
                        'badge_${conversation.id}',
                      ), // Unique key for switcher
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      constraints: BoxConstraints(minWidth: 18),
                      decoration: BoxDecoration(
                        color:
                            colorScheme
                                .primary, // Changed to primary for consistency
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                    : SizedBox(
                      key: ValueKey('no_badge_${conversation.id}'),
                    ), // Empty SizedBox when no badge
          ),
        ),
      ],
    );
  }
}
