import 'dart:async'; // Add import for StreamSubscription

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';
import 'package:vka_chat_ng/app/modules/chats/views/widgets/chat_date_header.dart';
import 'package:vka_chat_ng/app/modules/chats/views/widgets/chat_message_bubble.dart';
import 'package:vka_chat_ng/app/data/models/message_model.dart';

// Convert to StatefulWidget
class ChatMessages extends StatefulWidget {
  const ChatMessages({super.key});

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  final ChatsController controller = Get.find<ChatsController>();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  StreamSubscription? _messageSubscription;
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    // Get initial message count BEFORE listening
    _previousMessageCount = controller.messages.length;
    // Listen to message stream for changes
    _messageSubscription = controller.messages.stream.listen(
      _onMessagesChanged,
    );
  }

  @override
  void dispose() {
    // Cancel the subscription
    _messageSubscription?.cancel();
    super.dispose();
  }

  // Callback for when the messages list changes
  void _onMessagesChanged(List<Message> messages) {
    // Check if a message was added (inserted at index 0)
    if (messages.length > _previousMessageCount) {
      // Calculate how many items were added
      final itemsAdded = messages.length - _previousMessageCount;
      // Trigger insert animation for each added item
      for (int i = 0; i < itemsAdded; i++) {
        // Insert at index 0 because new messages are added to the start of the list
        // and the list is reversed.
        _listKey.currentState?.insertItem(
          0, // Index in the reversed list
          duration: const Duration(milliseconds: 300),
        );
      }
    }
    // TODO: Handle removals if necessary (more complex)

    // Update the count for the next comparison
    _previousMessageCount = messages.length;
  }

  // Helper function to calculate max message width (moved here for clarity)
  double _getMaxMessageWidth(double screenWidth) {
    if (screenWidth < 600) {
      return screenWidth * 0.80; // 80% for mobile
    } else if (screenWidth < 900) {
      return screenWidth * 0.70; // 70% for tablets
    } else {
      return screenWidth * 0.55; // 55% for desktops
    }
  }

  // Builder for each list item (used by both AnimatedList and ListView)
  Widget _buildItem(
    BuildContext context,
    int index,
    Animation<double>? animation, // Animation is now optional
    bool isSearchMode, // Flag to know which list we are building
  ) {
    // Determine the source list based on search mode
    final sourceList =
        isSearchMode ? controller.filteredMessages : controller.messages;

    // Need to check bounds in case list changes during animation/rebuild
    if (index >= sourceList.length) {
      return SizedBox.shrink(); // Or some placeholder
    }

    final message = sourceList[index];
    final isSender = message.sender_id == controller.userId;
    final messageDate = DateTime.parse(message.created_at);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxMessageWidth = _getMaxMessageWidth(screenWidth);

    // Determine if the date header should be shown
    bool showDateHeader = false;
    // Check bounds for previous message *within the same source list*
    final previousMessageIndex = index + 1;
    if (previousMessageIndex >= sourceList.length) {
      showDateHeader = true; // Always show for the oldest message (end of list)
    } else {
      final previousMessageDate = DateTime.parse(
        sourceList[previousMessageIndex].created_at, // Use sourceList
      );
      // Compare day, month, and year
      if (messageDate.day != previousMessageDate.day ||
          messageDate.month != previousMessageDate.month ||
          messageDate.year != previousMessageDate.year) {
        showDateHeader = true;
      }
    }

    // Wrap the item content conditionally based on animation presence
    final itemContent = Column(
      children: [
        // Conditionally display the date header
        if (showDateHeader) ChatDateHeader(date: messageDate),

        // Display the message bubble
        ChatMessageBubble(
          message: message,
          isSender: isSender,
          maxMessageWidth: maxMessageWidth,
        ),
      ],
    );

    // Apply animation only if provided (i.e., not in search mode)
    if (animation != null) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3), // Start slightly below
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: itemContent,
        ),
      );
    } else {
      // Return content directly if no animation (search mode)
      return itemContent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingMessages.value &&
          !controller.isChatSearchActive.value) {
        // Show loading indicator only if not searching
        return const Center(child: CircularProgressIndicator());
      }

      final bool isSearching = controller.isChatSearchActive.value;
      final bool hasSearchQuery = controller.chatSearchQuery.isNotEmpty;
      final List<Message> displayList =
          isSearching && hasSearchQuery
              ? controller.filteredMessages
              : controller.messages;

      if (displayList.isEmpty) {
        if (isSearching && hasSearchQuery) {
          return Center(child: Text('Сообщений не найдено'));
        } else if (!controller.isLoadingMessages.value) {
          return Center(child: Text('no_messages_yet'.tr));
        }
        // If loading but search is active, show empty state until results load or don't match
        // Or show a different indicator?
        return const SizedBox.shrink(); // Or Center(child: Text('Поиск...'))
      }

      // Use ListView.builder when searching, AnimatedList otherwise
      if (isSearching) {
        return ListView.builder(
          controller: controller.scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          itemCount: displayList.length, // Use filtered list length
          itemBuilder: (context, index) {
            // Call _buildItem without animation for search mode
            return _buildItem(context, index, null, true);
          },
        );
      } else {
        // Build the AnimatedList if messages exist and not searching
        return AnimatedList(
          key: _listKey,
          controller: controller.scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          // Use the count stored in the state, managed by the listener
          // For simplicity when not searching, let's use reactive length directly
          // _previousMessageCount logic might become complex with filtering interaction
          initialItemCount: controller.messages.length,
          itemBuilder: (context, index, animation) {
            // Call _buildItem with animation when not searching
            return _buildItem(context, index, animation, false);
          },
        );
      }
    });
  }
}

// Remove the helper function from here if moved to state class
// double _getMaxMessageWidth(double screenWidth) { ... }
