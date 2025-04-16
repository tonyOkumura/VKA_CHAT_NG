import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/data/models/contact_model.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';
import 'dart:async'; // For Timer

class UserSelectionDialog extends StatefulWidget {
  final String conversationId;
  final List<String> existingParticipantIds;

  const UserSelectionDialog({
    super.key,
    required this.conversationId,
    required this.existingParticipantIds,
  });

  @override
  State<UserSelectionDialog> createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends State<UserSelectionDialog> {
  final ChatsController controller = Get.find<ChatsController>();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Fetch initial list of users (without search query)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchUsersForAdding(widget.conversationId);
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    // Clear the list when dialog is closed to avoid showing stale data next time
    controller.usersToAddList.clear();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      controller.fetchUsersForAdding(
        widget.conversationId,
        searchQuery: _searchController.text.trim(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      surfaceTintColor: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: 10,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ), // Less padding for content
      actionsPadding: const EdgeInsets.only(right: 16, bottom: 12, left: 16),
      title: Text('Добавить участника', style: theme.textTheme.headlineSmall),
      content: SizedBox(
        width: double.maxFinite,
        height: 400, // Fixed height for the dialog content area
        child: Column(
          children: [
            // --- Search Field ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск пользователя...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                ),
              ),
            ),
            // --- User List ---
            Expanded(
              child: Obx(() {
                if (controller.isLoadingUsers.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.usersToAddList.isEmpty) {
                  return Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Нет доступных пользователей'
                          : 'Пользователи не найдены',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                // Display the list of users
                return ListView.builder(
                  itemCount: controller.usersToAddList.length,
                  itemBuilder: (context, index) {
                    final user = controller.usersToAddList[index];
                    // Check if the current user is already a participant
                    final bool isAlreadyParticipant = widget
                        .existingParticipantIds
                        .contains(user.id);

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: controller.getUserColor(user.id),
                        child: Text(
                          user.username.isNotEmpty
                              ? user.username[0].toUpperCase()
                              : '?',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      title: Text(user.username),
                      subtitle: Text(
                        user.email,
                        style: theme.textTheme.bodySmall,
                      ),
                      // Show checkmark and disable tap if already a participant
                      trailing:
                          isAlreadyParticipant
                              ? Icon(Icons.check, color: colorScheme.primary)
                              : null,
                      onTap:
                          isAlreadyParticipant
                              ? null // Disable tap if already participant
                              : () {
                                // Return the selected user ID when tapped
                                Get.back(result: user.id);
                              },
                      enabled:
                          !isAlreadyParticipant, // Visually disable if already participant
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(), // Close without selecting
          child: Text('Отмена'),
        ),
      ],
    );
  }
}
