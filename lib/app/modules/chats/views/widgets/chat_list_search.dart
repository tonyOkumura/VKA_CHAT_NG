import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';

class ChatListSearch extends StatelessWidget {
  const ChatListSearch({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12.0,
        0,
        12.0,
        12.0,
      ), // Increased bottom padding
      child: Obx(
        () => TextField(
          controller: controller.searchController,
          focusNode: controller.searchFocusNode,
          decoration: InputDecoration(
            hintText:
                'search_${controller.selectedTab.value == 0 ? 'groups' : 'dialogs'}_hint'
                    .tr,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 22,
              color: colorScheme.onSurfaceVariant,
            ),
            suffixIcon:
                controller.searchText.value.isNotEmpty
                    ? IconButton(
                      icon: Icon(
                        Icons.close_rounded, // Rounded clear icon
                        size: 20,
                        color: colorScheme.secondary,
                      ),
                      tooltip: 'Очистить поиск',
                      onPressed: () {
                        controller.searchController.clear();
                        controller.searchFocusNode.unfocus();
                      },
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12, // Adjusted vertical padding
            ),
            isDense: true,
          ),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ), // Use theme style
          onTapOutside: (event) => controller.searchFocusNode.unfocus(),
          onSubmitted: (value) => controller.searchFocusNode.unfocus(),
        ),
      ),
    );
  }
}
