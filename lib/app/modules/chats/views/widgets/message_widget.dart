import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vka_chat_ng/app/data/message_model.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';

class MessageWidget extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isGroupChat;
  final Function(String) onMessageTap;

  const MessageWidget({
    Key? key,
    required this.message,
    required this.isMe,
    required this.isGroupChat,
    required this.onMessageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();

    return GestureDetector(
      onTap: () => onMessageTap(message.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe && isGroupChat) ...[
              // Аватар отправителя для группового чата
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: controller.getUserColor(message.sender_id),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    message.sender_id[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe && isGroupChat)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          message.sender_id,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(
                            DateTime.parse(message.created_at).toLocal(),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: isMe ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.is_unread ?? true
                                ? Icons.check
                                : Icons.done_all,
                            size: 16,
                            color:
                                (message.is_unread ?? true)
                                    ? Colors.white70
                                    : Colors.blue[100],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
