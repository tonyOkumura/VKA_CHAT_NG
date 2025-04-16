import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/widgets/main_layout.dart';
import '../controllers/chats_controller.dart';
import 'chat_list.dart';
import 'chat_detail.dart';

class ChatsView extends GetView<ChatsController> {
  const ChatsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Use context-aware theme access
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MainLayout(
      selectedIndex: 0,
      child: Scaffold(
        // Use slightly different background for chat area if desired
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          // Use themed background color
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surface, // For MD3 elevation tint
          title: Text(
            'chats'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          centerTitle: false,
          elevation: 0, // Keep elevation 0, rely on border/color
          actions: [
            IconButton(
              onPressed: () async {
                // Consider adding visual feedback like a shimmer or progress indicator
                await controller.fetchConversations();
                // No need to manually call fetchMessages if selectedConversation is watched
                // if (controller.selectedConversation.value != null) {
                //   controller.fetchMessages();
                // }
              },
              icon: Icon(
                Icons.refresh_rounded,
                color: colorScheme.primary,
              ), // Use rounded icon
              tooltip: 'Обновить чаты',
            ),
          ],
          // Optional: Add a bottom border to AppBar for separation
          // bottom: PreferredSize(
          //   preferredSize: Size.fromHeight(1.0),
          //   child: Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant),
          // ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final bool isLargeScreen = constraints.maxWidth >= 900;

            if (isLargeScreen) {
              return Row(
                children: [
                  SizedBox(
                    // Constrain width more precisely if needed
                    width:
                        constraints.maxWidth * 0.35 > 400
                            ? 400
                            : constraints.maxWidth * 0.35,
                    child: ChatList(),
                  ),
                  // Use theme color for divider
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color:
                        colorScheme
                            .outlineVariant, // Use a subtle divider color
                  ),
                  Expanded(
                    child: Obx(() {
                      // Check if a conversation is selected
                      final conversationSelected =
                          controller.selectedConversation.value != null;
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child:
                            conversationSelected
                                ? ChatDetail(
                                  key: ValueKey(
                                    controller.selectedConversation.value!.id,
                                  ),
                                ) // Add key for proper animation
                                : Center(
                                  key: const ValueKey(
                                    'prompt',
                                  ), // Key for prompt
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.forum_outlined, // Changed icon
                                        size: 60,
                                        color:
                                            colorScheme
                                                .secondary, // Use secondary color
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'select_chat_prompt'.tr,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme
                                                      .onSurfaceVariant, // More subtle color
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                      );
                    }),
                  ),
                ],
              );
            } else {
              // Small screen: Animate between ChatList and ChatDetail
              return Obx(() {
                final conversationSelected =
                    controller.selectedConversation.value != null;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    // Slide transition for mobile
                    final tween = Tween<Offset>(
                      begin:
                          child.key == const ValueKey('list')
                              ? Offset.zero
                              : const Offset(1.0, 0.0),
                      end:
                          child.key == const ValueKey('list')
                              ? const Offset(-1.0, 0.0)
                              : Offset.zero,
                    );
                    return ClipRect(
                      child: SlideTransition(
                        position: tween.animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child:
                      conversationSelected
                          ? ChatDetail(
                            key: ValueKey(
                              controller.selectedConversation.value!.id,
                            ),
                          )
                          : ChatList(key: const ValueKey('list')),
                );
              });
            }
          },
        ),
      ),
    );
  }
}
