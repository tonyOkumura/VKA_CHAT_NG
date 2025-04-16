import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/data/models/chat_participant_model.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';

class ChatParticipantsDialogContent extends StatelessWidget {
  final List<ChatParticipant> participants;

  const ChatParticipantsDialogContent({super.key, required this.participants});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      surfaceTintColor: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ), // Smoother corners
      titlePadding: const EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: 10,
      ),
      contentPadding: const EdgeInsets.only(bottom: 16),
      title: Text(
        'Участники группы (${participants.length})', // Show count in title
        style: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite, // Ensure dialog takes reasonable width
        height: 300, // Set max height for the content area
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: participants.length,
          itemBuilder: (context, index) {
            final participant = participants[index];
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 4.0,
                horizontal: 16.0,
              ),
              child: _buildParticipantRow(
                controller,
                participant,
                theme,
                colorScheme,
              ),
            );
          },
          separatorBuilder:
              (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outlineVariant.withOpacity(0.5),
                indent: 60, // Indent to align after avatar
                endIndent: 16,
              ),
        ),
      ),
      // Optional: Add actions like a close button if needed
      actionsPadding: const EdgeInsets.only(right: 16, bottom: 12),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('Закрыть')),
      ],
    );
  }

  Widget _buildParticipantRow(
    ChatsController controller,
    ChatParticipant participant,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final username = participant.username ?? '';

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: controller.getUserColor(participant.user_id),
          child: Text(
            username.isNotEmpty ? username[0].toUpperCase() : '?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (participant.email.isNotEmpty)
                Text(
                  participant.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        SizedBox(width: 8),
        if (participant.is_online)
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.green.shade400,
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.surfaceContainerHigh,
                width: 1.5,
              ),
            ),
          ),
      ],
    );
  }
}
