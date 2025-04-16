import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/data/models/conversation_model.dart';
import 'package:vka_chat_ng/app/data/models/chat_participant_model.dart';
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';
import 'package:vka_chat_ng/app/modules/chats/views/widgets/user_selection_dialog.dart';

// Convert to StatefulWidget to manage TextEditingController
class GroupSettingsDialog extends StatefulWidget {
  final Conversation conversation;

  const GroupSettingsDialog({super.key, required this.conversation});

  @override
  State<GroupSettingsDialog> createState() => _GroupSettingsDialogState();
}

class _GroupSettingsDialogState extends State<GroupSettingsDialog> {
  late TextEditingController _nameController;
  late bool _isAdmin;
  bool _nameChanged = false;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<ChatsController>();
    _nameController = TextEditingController(
      text: widget.conversation.conversation_name,
    );

    // --- Updated isAdmin Check (Workaround) ---
    ChatParticipant? adminParticipant;
    try {
      // Find the participant whose username matches the admin_name
      adminParticipant = widget.conversation.participants?.firstWhere(
        (p) => p.username == widget.conversation.admin_name,
      );
    } catch (e) {
      // Handle case where participant with that name is not found (shouldn't happen based on user info)
      print(
        '[GroupSettingsDialog] Warning: Admin participant not found in list by name.',
      );
      adminParticipant = null;
    }
    // Check if the found participant's ID matches the current user's ID
    _isAdmin =
        adminParticipant != null &&
        adminParticipant.user_id == controller.userId;
    // --- End Updated isAdmin Check ---

    // --- Add Debug Prints ---
    print(
      '[GroupSettingsDialog] Conversation Admin Name: ${widget.conversation.admin_name}',
    );
    print('[GroupSettingsDialog] Current User ID: ${controller.userId}');
    print('[GroupSettingsDialog] Is Admin Check Result: $_isAdmin');
    // --- End Debug Prints ---

    _nameController.addListener(() {
      if (_nameController.text != widget.conversation.conversation_name) {
        if (!_nameChanged) {
          setState(() {
            // Update state to enable save button
            _nameChanged = true;
          });
        }
      } else {
        if (_nameChanged) {
          setState(() {
            // Update state to disable save button if name reverts
            _nameChanged = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Use participants from the widget's conversation - Now get reactively
    // final participants = widget.conversation.participants ?? [];
    // Use isAdmin from state
    // final isAdmin = widget.conversation.admin_name == controller.userId;

    // Get the reactive selected conversation
    final Rx<Conversation?> selectedConv = controller.selectedConversation;

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
      contentPadding: const EdgeInsets.only(bottom: 8, left: 24, right: 24),
      actionsPadding: const EdgeInsets.only(right: 16, bottom: 12, left: 16),
      title: Text('Настройки группы', style: theme.textTheme.headlineSmall),
      content: SizedBox(
        width: double.maxFinite, // Allow dialog to size itself reasonably
        child: SingleChildScrollView(
          // Make content scrollable
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Avatar and Name ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar Placeholder
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.group,
                      size: 30,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    // TODO: Add button to change avatar if admin
                  ),
                  const SizedBox(width: 16),
                  // Name TextField - Use _nameController
                  Expanded(
                    child: TextField(
                      controller: _nameController, // Use state controller
                      readOnly: !_isAdmin, // Only editable by admin
                      decoration: InputDecoration(
                        labelText: 'Название группы',
                        // suffixIcon: _isAdmin ? Icon(Icons.edit_outlined, size: 18) : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: theme.textTheme.titleMedium,
                      // Saving logic will be in the button
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Participants Section (Reactive) ---
              Obx(() {
                // Get participants reactively from the controller's selected conversation
                final currentParticipants =
                    selectedConv.value?.participants ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Участники (${currentParticipants.length})', // Update count reactively
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: 200,
                      ), // Limit list height
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount:
                            currentParticipants
                                .length, // Use reactive list length
                        itemBuilder: (context, index) {
                          final participant =
                              currentParticipants[index]; // Use reactive list item
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: controller.getUserColor(
                                participant.user_id,
                              ),
                              child: Text(
                                participant.username.isNotEmpty
                                    ? participant.username[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            title: Text(participant.username),
                            subtitle: Text(
                              participant.email,
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing:
                                _isAdmin &&
                                        participant.user_id != controller.userId
                                    ? IconButton(
                                      icon: Icon(
                                        Icons.remove_circle_outline,
                                        color: colorScheme.error,
                                        size: 20,
                                      ),
                                      tooltip: 'Удалить участника',
                                      onPressed: () {
                                        // Show confirmation dialog
                                        Get.dialog(
                                          AlertDialog(
                                            title: Text('Подтвердите удаление'),
                                            content: Text(
                                              'Вы уверены, что хотите удалить пользователя "${participant.username}" из группы?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Get.back(), // Close confirmation dialog
                                                child: Text('Отмена'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Get.back(); // Close confirmation dialog
                                                  // Call controller method to remove participant
                                                  controller
                                                      .removeGroupParticipant(
                                                        widget.conversation.id,
                                                        participant.user_id,
                                                      );
                                                },
                                                child: Text(
                                                  'Удалить',
                                                  style: TextStyle(
                                                    color: colorScheme.error,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    )
                                    : null,
                          );
                        },
                        separatorBuilder:
                            (context, index) => Divider(height: 1),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 12),
              if (_isAdmin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: Icon(Icons.add_circle_outline, size: 20),
                    label: Text('Добавить участника'),
                    onPressed: () async {
                      // Make onPressed async
                      // Open the user selection dialog
                      // Ensure we use the CURRENT conversation ID from the reactive source
                      final currentConversationId = selectedConv.value?.id;
                      if (currentConversationId == null) return; // Safety check

                      // Get the list of current participant IDs
                      final existingParticipantIds =
                          selectedConv.value?.participants
                              ?.map((p) => p.user_id)
                              .toList() ??
                          [];

                      final result = await Get.dialog<String?>(
                        UserSelectionDialog(
                          conversationId: currentConversationId,
                          existingParticipantIds:
                              existingParticipantIds, // Pass the IDs
                        ),
                        barrierDismissible:
                            true, // Allow dismissing by clicking outside
                      );

                      // If a user was selected (result is not null)
                      if (result != null) {
                        final userIdToAdd = result;
                        // Call controller method to add participant
                        controller.addGroupParticipant(
                          currentConversationId, // Use current ID
                          userIdToAdd,
                        );
                      } else {
                        // User cancelled the dialog
                        print('User selection cancelled.');
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('Закрыть')),
        if (_isAdmin)
          // Use a ValueListenableBuilder or listen to controller.isLoading for disabling during save
          ElevatedButton(
            // Enable only if admin and name has changed
            onPressed:
                _nameChanged
                    ? () {
                      final newName = _nameController.text.trim();
                      if (newName.isNotEmpty &&
                          newName != widget.conversation.conversation_name) {
                        // Call controller method to update name
                        controller.updateGroupName(
                          widget.conversation.id,
                          newName,
                        );
                        // Snackbar is handled by the controller now
                        // Get.snackbar('Info', 'Сохранение имени "$newName" не реализовано');
                        // Dialog closing is also handled by the controller on success
                        // Get.back();
                      } else {
                        // Reset name if trimmed value is empty or same as original
                        _nameController.text =
                            widget.conversation.conversation_name;
                        setState(() => _nameChanged = false);
                      }
                    }
                    : null, // Disable button if name hasn't changed
            child: Text('Сохранить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
      ],
    );
  }
}
