import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/data/models/chat_participant_model.dart';
import 'package:vka_chat_ng/app/data/models/conversation_model.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';
import 'chat_participants_dialog_content.dart';

class ChatParticipantsPopup {
  static void show(BuildContext context, Conversation conversation) {
    // No need for overlay or button RenderBox anymore

    // Defensive copy and sort
    final List<ChatParticipant> participants = List.from(
      conversation.participants ?? [],
    );
    participants.sort((a, b) {
      final isOnlineA = a.is_online;
      final isOnlineB = b.is_online;
      final usernameA = a.username ?? '';
      final usernameB = b.username ?? '';

      if (isOnlineA != isOnlineB) {
        return isOnlineB ? 1 : -1;
      }
      return usernameA.compareTo(usernameB);
    });

    // Use Get.dialog to show the custom dialog content
    Get.dialog(
      ChatParticipantsDialogContent(participants: participants),
      // Optional: barrierDismissible, barrierColor, etc.
      barrierDismissible: true,
    );

    // Remove old showMenu logic
    /*
    showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Get.theme.colorScheme.surfaceContainerHigh,
      items: [
        PopupMenuItem(
          enabled: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 300, maxHeight: 250),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12.0,
                    left: 8.0,
                    top: 4.0,
                  ),
                  child: Text(
                    'Участники группы',
                    style: Get.theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Get.theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final participant = participants[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 8.0,
                        ),
                        child: _buildParticipantRow(Get.find<ChatsController>(), participant),
                      );
                    },
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: Get.theme.colorScheme.outlineVariant.withOpacity(0.5),
                      indent: 48,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    */
  }

  // _buildParticipantRow is now inside ChatParticipantsDialogContent
  // static Widget _buildParticipantRow(
  //   ChatsController controller,
  //   ChatParticipant participant,
  // ) { ... }
}
