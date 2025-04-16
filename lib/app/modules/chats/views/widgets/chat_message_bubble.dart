import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vka_chat_ng/app/data/models/message_model.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';
import 'package:vka_chat_ng/app/modules/chats/views/widgets/chat_file_attachment.dart';
import 'package:vka_chat_ng/app/modules/chats/views/widgets/chat_read_status.dart';

class ChatMessageBubble extends StatelessWidget {
  final Message message;
  final bool isSender;
  final double maxMessageWidth;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isSender,
    required this.maxMessageWidth,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final messageTime = DateFormat(
      'HH:mm',
    ).format(DateTime.parse(message.created_at));
    final isGroupChat = controller.selectedConversation.value!.is_group_chat;

    // Define bubble colors based on sender
    final bubbleColor =
        isSender
            ? colorScheme
                .primaryContainer // User's messages
            : colorScheme.surfaceContainerHighest; // Others' messages
    final textColor =
        isSender ? colorScheme.onPrimaryContainer : colorScheme.onSurface;
    final timeColor =
        isSender
            ? colorScheme.onPrimaryContainer.withOpacity(0.7)
            : colorScheme.onSurfaceVariant;

    // Define bubble border radius
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft:
          isSender
              ? Radius.circular(16)
              : Radius.circular(4), // Pointy corner for receiver
      bottomRight:
          isSender
              ? Radius.circular(4)
              : Radius.circular(16), // Pointy corner for sender
    );

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxMessageWidth),
        child: Container(
          margin: EdgeInsets.only(
            left: isSender ? 0 : 8.0,
            right: isSender ? 8.0 : 0,
            top: 2.0,
            bottom: 2.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: borderRadius,
            // Removed shadow for a flatter look
            // boxShadow: [
            //   BoxShadow(
            //     color: colorScheme.shadow.withOpacity(0.05),
            //     blurRadius: 3,
            //     offset: Offset(0, 1),
            //   ),
            // ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align content left
            children: [
              // Sender name (for group chats, non-sender messages)
              if (!isSender && isGroupChat)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    message.sender_username,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: controller.getUserColor(message.sender_id),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // Message content
              if (message.content.isNotEmpty)
                Text(
                  message.content,
                  // Use bodyLarge style with appropriate color
                  style: theme.textTheme.bodyLarge?.copyWith(color: textColor),
                ),

              // File attachment (if any)
              if (message.files != null && message.files!.isNotEmpty)
                // Add padding if there's also text content
                Padding(
                  padding: EdgeInsets.only(
                    top: message.content.isNotEmpty ? 4.0 : 0,
                  ),
                  child: ChatFileAttachment(file: message.files!.first),
                ),

              // Timestamp and Read Status (aligned to the right)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end, // Align to end
                  children: [
                    Text(
                      messageTime,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: timeColor,
                      ),
                    ),
                    if (isSender) ...[
                      SizedBox(width: 4),
                      SizedBox(
                        width: 18, // Adjusted width
                        height: 14, // Adjusted height
                        child: ChatReadStatus(message: message),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
