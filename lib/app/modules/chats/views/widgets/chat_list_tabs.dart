import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';

class ChatListTabs extends StatelessWidget {
  const ChatListTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12.0,
        8.0,
        12.0,
        8.0,
      ), // Adjusted padding
      child: Obx(
        () => Row(
          children: [
            _buildTabButton(
              controller,
              theme,
              0,
              'Группы',
              _calculateUnreadGroups(controller),
            ),
            SizedBox(width: 8),
            _buildTabButton(
              controller,
              theme,
              1,
              'Диалоги',
              _calculateUnreadDialogs(controller),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateUnreadGroups(ChatsController controller) {
    // Use filteredConversations based on the *unfiltered* list for accurate count?
    // Or keep using conversations directly if counts should reflect all chats.
    return controller.conversations
        .where((c) => c.is_group_chat && (c.unread_count ?? 0) > 0)
        .length;
  }

  int _calculateUnreadDialogs(ChatsController controller) {
    return controller.conversations
        .where((c) => !c.is_group_chat && (c.unread_count ?? 0) > 0)
        .length;
  }

  Widget _buildTabButton(
    ChatsController controller,
    ThemeData theme,
    int tabIndex,
    String title,
    int unreadCount,
  ) {
    final colorScheme = theme.colorScheme;
    final bool isSelected = controller.selectedTab.value == tabIndex;

    // Define styles based on selection state
    final bgColor =
        isSelected
            ? colorScheme.primaryContainer
            : colorScheme
                .surfaceContainer; // Use a less prominent bg for inactive
    final fgColor =
        isSelected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant; // Less contrast for inactive text
    final badgeBg = colorScheme.secondary;
    final badgeFg = colorScheme.onSecondary;
    final side =
        isSelected
            ? null
            : BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ); // Subtle border

    return Expanded(
      child: TextButton(
        // Changed to TextButton for a potentially lighter feel
        onPressed: () => controller.selectedTab.value = tabIndex,
        style: TextButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          padding: EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 12,
          ), // Adjusted padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: side,
          // Ensure minimum size if needed
          // minimumSize: Size(64, 40),
          visualDensity: VisualDensity.compact, // Make button denser
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(color: fgColor),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child:
                  unreadCount > 0
                      ? Container(
                        key: ValueKey('badge_$tabIndex'),
                        margin: EdgeInsets.only(left: 6),
                        padding: EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        constraints: BoxConstraints(minWidth: 18),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: badgeFg,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                      : SizedBox(key: ValueKey('no_badge_$tabIndex')),
            ),
          ],
        ),
      ),
    );
  }
}
