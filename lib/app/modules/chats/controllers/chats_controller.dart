import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:vka_chat_ng/app/constants.dart';
import 'package:vka_chat_ng/app/data/models/conversation_model.dart';
import 'package:vka_chat_ng/app/data/models/message_model.dart';
import 'package:vka_chat_ng/app/data/models/message_reads_model.dart';
import 'package:vka_chat_ng/app/services/socket_service.dart';
import 'package:vka_chat_ng/app/services/file_service.dart';
import 'dart:async';
import 'package:vka_chat_ng/app/services/notification_service.dart';
import 'package:vka_chat_ng/app/data/models/file_model.dart' as file_model;
import 'package:vka_chat_ng/app/data/models/contact_model.dart';
import 'package:vka_chat_ng/app/data/models/chat_participant_model.dart';

class ChatsController extends GetxController {
  final _storage = FlutterSecureStorage();
  final _baseUrl = AppConstants.baseUrl;
  final conversations = <Conversation>[].obs;
  final filteredConversations = <Conversation>[].obs;
  final messages = <Message>[].obs;
  final messageReads = <String, List<MessageReads>>{}.obs;
  final userColors = <String, Color>{}.obs; // Хранение цветов пользователей
  final onlineUsers =
      <String, bool>{}
          .obs; // Добавляем отслеживание онлайн статуса пользователей
  final downloadingFiles = <String>{}.obs;
  final downloadedFiles = <String>{}.obs;
  var selectedConversation = Rxn<Conversation>();

  // --- Input Controllers & Focus Nodes ---
  final messageController = TextEditingController();
  final messageFocusNode = FocusNode();
  final searchController = TextEditingController(); // For ChatList search
  final searchFocusNode = FocusNode(); // For ChatList search
  final chatSearchController =
      TextEditingController(); // For Chat Search within Detail
  final chatSearchFocusNode = FocusNode(); // For Chat Search within Detail
  // --- End Input Controllers & Focus Nodes ---

  // --- Loading & State Flags ---
  final isLoading = false.obs;
  final isLoadingMessages = false.obs;
  final isSendingMessage = false.obs;
  final selectedFile = Rxn<File>();
  final selectedTab = 0.obs; // 0 - чаты, 1 - диалоги
  final isChatSearchActive = false.obs;
  final isLoadingUsers = false.obs;
  // --- End Loading & State Flags ---

  // --- Reactive Text Values ---
  final searchText = ''.obs; // For ChatList search
  final messageText = ''.obs; // For message input
  final chatSearchQuery = ''.obs; // For Chat Search within Detail
  // --- End Reactive Text Values ---

  // --- Services & User Info ---
  late SocketService _socketService;
  late String userId;
  // --- End Services & User Info ---

  // --- Other Controllers & Timers ---
  final scrollController = ScrollController(); // For message list
  Timer? _refreshTimer;
  // --- End Other Controllers & Timers ---

  // --- Reactive Lists ---
  final usersToAddList = <Contact>[].obs;
  final filteredMessages = <Message>[].obs; // For in-chat search results
  // --- End Reactive Lists ---

  // Computed property for send button enablement
  bool get canSendMessage =>
      (messageText.value.trim().isNotEmpty ||
          selectedFile.value != null) && // Use messageText here
      !isSendingMessage.value;

  // Получение или создание цвета для пользователя
  Color getUserColor(String userId) {
    // Генерируем цвет на основе ID пользователя
    final hash = userId.hashCode;
    final hue = (hash % 360).abs();
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.7, 0.5).toColor();
  }

  @override
  void onInit() {
    super.onInit();
    print('ChatsController initialized.');
    _socketService = Get.find<SocketService>();
    _initializeUserId();

    // --- Add listeners for text controllers ---
    searchController.addListener(() {
      searchText.value = searchController.text;
    });
    messageController.addListener(() {
      messageText.value = messageController.text;
    });
    // Automatically filter when searchText changes
    ever(searchText, (_) => filterConversations());
    // Automatically filter when selectedTab changes
    ever(selectedTab, (_) => filterConversations());

    // --- Listener for Chat Search ---
    chatSearchController.addListener(() {
      // Check if the controller text actually changed to avoid loops
      if (chatSearchQuery.value != chatSearchController.text) {
        chatSearchQuery.value = chatSearchController.text;
        _filterChatMessages(); // Filter when query changes
      }
    });
    // --- End listeners ---

    fetchConversations().then((_) {
      for (var conversation in conversations) {
        _socketService.joinConversation(conversation.id);
      }
      // Initial filter after fetching
      filterConversations();
    });

    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.minScrollExtent) {
        print('Reached the top of the list.');
      }
    });
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      fetchConversations();
    });
  }

  @override
  void onReady() {
    super.onReady();
    print('ChatsController is ready.');
  }

  @override
  void onClose() {
    // --- Remove listeners ---
    searchController.removeListener(() {
      searchText.value = searchController.text;
    });
    messageController.removeListener(() {
      messageText.value = messageController.text;
    });
    // --- End remove listeners ---

    messageController.dispose();
    messageFocusNode.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    // --- Dispose Chat Search ---
    chatSearchController.dispose();
    chatSearchFocusNode.dispose();
    // --- End Dispose Chat Search ---
    scrollController.dispose();
    _socketService.socket.off('newMessage', handleIncomingMessage);
    _socketService.socket.off('messageRead', handleMessageRead);
    _refreshTimer?.cancel();
    print('ChatsController disposed.');
    super.onClose();
  }

  Future<void> _initializeUserId() async {
    userId = await _storage.read(key: AppKeys.userId) ?? '';
    print('[ChatsController] Initialized User ID: $userId');

    // Отправляем событие аутентификации для текущего пользователя
    if (userId.isNotEmpty) {
      _socketService.socket.emit('authenticate', userId);
    }
  }

  void selectConversation(int? index) {
    if (index == null) {
      // Уведомляем о закрытии текущего чата
      if (selectedConversation.value != null) {
        Get.find<NotificationService>().setChatOpen(
          selectedConversation.value!.id,
          false,
        );
      }
      selectedConversation.value = null;
      messages.clear();
      return;
    }
    // Уведомляем о закрытии предыдущего чата
    if (selectedConversation.value != null) {
      Get.find<NotificationService>().setChatOpen(
        selectedConversation.value!.id,
        false,
      );
    }
    selectedConversation.value = conversations[index];
    // Уведомляем об открытии нового чата
    Get.find<NotificationService>().setChatOpen(
      selectedConversation.value!.id,
      true,
    );
    fetchMessages().then((_) {
      // После загрузки сообщений отмечаем их как прочитанные
      _markAllMessagesAsRead();
    });
  }

  bool isChatOpen(String conversationId) {
    return selectedConversation.value?.id == conversationId;
  }

  Future<void> fetchConversations() async {
    isLoading.value = true;
    print('Fetching conversations...');
    String token = await _storage.read(key: AppKeys.token) ?? '';
    try {
      var response = await http.get(
        Uri.parse('$_baseUrl/conversations'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(utf8.decode(response.bodyBytes));
        conversations.value =
            data.map((e) {
              // Parse conversation directly, participants are included
              final conversation = Conversation.fromJson(e);
              // No need for a separate participant fetch here
              return conversation;
            }).toList(); // Use toList() after map, no need for Future.wait

        // Sort conversations after parsing
        conversations.sort((a, b) {
          if (a.last_message_time != null && b.last_message_time != null) {
            return b.last_message_time!.compareTo(a.last_message_time!);
          }
          if (a.last_message_time != null) return -1;
          if (b.last_message_time != null) return 1;
          return b.id.compareTo(a.id);
        });

        filterConversations(); // Update filtered list after fetching and sorting
        print('Conversations fetched successfully.');

        // Re-join socket rooms after fetching
        for (var conversation in conversations) {
          _socketService.joinConversation(conversation.id);
        }
      } else {
        print('Failed to fetch conversations: ${response.body}');
        // Handle error appropriately, maybe show a snackbar
      }
    } catch (e) {
      print('Error fetching conversations: $e');
      // Handle error appropriately
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMessages() async {
    if (selectedConversation.value == null) return;

    isLoadingMessages.value = true;
    messages.clear();
    print('=== Starting fetchMessages ===');
    print('Current conversation ID: ${selectedConversation.value!.id}');
    String token = await _storage.read(key: AppKeys.token) ?? '';
    print('Token found: ${token.isNotEmpty}');

    try {
      var response = await http.get(
        Uri.parse('$_baseUrl/messages/${selectedConversation.value!.id}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Successfully received messages');
        List data = jsonDecode(
          utf8.decode(response.bodyBytes),
        ); // Handle encoding
        print('Decoded JSON array length: ${data.length} messages');

        // Directly assign the mapped list
        messages.value =
            data.map((e) {
              final messageData =
                  e is Map && e.containsKey('message') ? e['message'] : e;
              final message = Message.fromJson(messageData);

              // Determine if the current user has read the message
              bool currentUserHasRead =
                  message.read_by_users?.any(
                    (user) => user.contact_id == userId,
                  ) ??
                  false;

              // Update unread status (consider group chat participant count later)
              // For now, just check if the current user has read it
              final finalMessage = message.copyWith(
                is_unread: !currentUserHasRead,
              );
              return finalMessage;
            }).toList();

        print('Successfully added ${messages.length} messages to the list');
        _filterChatMessages(); // Filter after fetching messages
        _scrollToBottom(animate: false); // Scroll immediately without animation
      } else {
        print('Failed to fetch messages: ${response.statusCode}');
        print('Error response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching messages: $e');
    } finally {
      isLoadingMessages.value = false;
    }
    print('=== Finished fetchMessages ===');
  }

  void _markAllMessagesAsRead() {
    if (selectedConversation.value != null && userId.isNotEmpty) {
      _socketService.socket.emit('markMessagesAsRead', {
        'conversation_id': selectedConversation.value!.id,
        'user_id': userId,
      });

      final conversationIndex = conversations.indexWhere(
        (c) => c.id == selectedConversation.value!.id,
      );
      if (conversationIndex != -1) {
        if (conversations[conversationIndex].unread_count != 0) {
          final updatedConversation = conversations[conversationIndex].copyWith(
            unread_count: 0,
          );
          conversations[conversationIndex] = updatedConversation;
          // conversations.refresh(); // May not be needed if filterConversations is called
          filterConversations(); // Update filtered list which includes counts
        }
      }

      // Mark messages as read locally immediately
      messages.value =
          messages.map((message) {
            if (message.is_unread == true) {
              final isAlreadyReadLocally =
                  message.read_by_users?.any((u) => u.contact_id == userId) ??
                  false;
              if (!isAlreadyReadLocally) {
                final newReadByUser = ReadByUser(
                  contact_id: userId,
                  username: 'Вы', // Placeholder
                  email: '',
                  read_at: DateTime.now().toIso8601String(),
                );
                return message.copyWith(
                  is_unread: false,
                  read_by_users: [
                    ...message.read_by_users ?? [],
                    newReadByUser,
                  ],
                );
              } else {
                // Already marked as read locally, ensure is_unread is false
                return message.copyWith(is_unread: false);
              }
            }
            return message;
          }).toList();
      // messages.refresh(); // Not needed due to .value assignment
    }
  }

  Future<void> sendMessage() async {
    if (!canSendMessage || selectedConversation.value == null) {
      print('Cannot send message. Condition not met.');
      return;
    }

    isSendingMessage.value = true;
    final messageContent = messageText.value.trim();
    final fileToSend = selectedFile.value;

    // Clear input immediately
    messageController
        .clear(); // This triggers the listener, clearing messageText
    selectedFile.value = null;

    try {
      if (fileToSend != null) {
        // --- Send with File ---
        print('Sending message with file: ${fileToSend.path}');
        final fileService = Get.find<FileService>();
        final result = await fileService.uploadFileWithMessage(
          file: fileToSend,
          conversationId: selectedConversation.value!.id,
          senderId: userId,
          content: messageContent, // Send text along with file
        );

        if (result != null && result.containsKey('message')) {
          print('File upload successful, server response: $result');
          final message = Message.fromJson(result['message']);
          // Server response already contains the message, no need to add locally?
          // Assuming socket event 'newMessage' will deliver it correctly.
          // _addMessageLocally(message); // Maybe redundant if socket works
          _updateConversationLastMessage(message); // Update list view
        } else {
          print('Failed to upload file: Invalid server response');
          // Handle error: Maybe show snackbar, restore input?
          // For now, just log it.
          Get.snackbar(
            'Ошибка',
            'Не удалось отправить файл',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else if (messageContent.isNotEmpty) {
        // --- Send Text Only ---
        print('Sending text message: $messageContent');
        // Optimistically add message locally? Maybe not needed if socket is fast.
        _socketService.sendMessageWithParams(
          selectedConversation.value!.id,
          messageContent,
          userId,
        );
        // Don't add locally, wait for 'newMessage' event to avoid duplicates
        // and ensure correct 'read_by_users' status.
      }
    } catch (e) {
      print('Error sending message: $e');
      Get.snackbar(
        'Ошибка',
        'Не удалось отправить сообщение',
        snackPosition: SnackPosition.BOTTOM,
      );
      // Consider restoring input?
    } finally {
      isSendingMessage.value = false;
      // Request focus back?
      // Future.delayed(Duration(milliseconds: 50), () => messageFocusNode.requestFocus());
    }
  }

  // Helper to add message locally (if needed for optimism)
  // void _addMessageLocally(Message message) {
  //   messages.insert(0, message);
  //   _scrollToBottom();
  // }

  void handleIncomingMessage(dynamic data) {
    print('New message received via socket: $data');
    try {
      final message = Message.fromJson(data);

      // Mark as unread if not from self
      final updatedMessage = message.copyWith(
        is_unread: message.sender_id != userId,
      );

      if (selectedConversation.value != null &&
          message.conversation_id == selectedConversation.value!.id) {
        // If chat is open, add message and mark as read
        messages.insert(0, updatedMessage);
        _filterChatMessages(); // Filter when a new message is added locally
        _scrollToBottom();
        // Mark as read immediately if chat is open
        if (message.sender_id != userId) {
          _socketService.socket.emit('markMessagesAsRead', {
            'conversation_id': selectedConversation.value!.id,
            'user_id': userId,
          });
          // Also update locally immediately
          final index = messages.indexWhere((m) => m.id == updatedMessage.id);
          if (index != -1) {
            final newReadByUser = ReadByUser(
              contact_id: userId,
              username: 'Вы',
              email: '',
              read_at: DateTime.now().toIso8601String(),
            );
            messages[index] = messages[index].copyWith(
              is_unread: false,
              read_by_users: [
                ...messages[index].read_by_users ?? [],
                newReadByUser,
              ],
            );
            messages.refresh(); // Refresh to update read status icon
          }
        }
      } else {
        // If chat is not open, just update the conversation list preview
        _updateConversationLastMessage(updatedMessage, incrementUnread: true);
      }

      // Always update conversation list regardless of chat open status
      _updateConversationLastMessage(updatedMessage);
    } catch (e) {
      print("Error processing incoming message: $e");
      print("Data: $data");
    }
  }

  // Updated to optionally increment unread count
  void _updateConversationLastMessage(
    Message message, {
    bool incrementUnread = false,
  }) {
    final index = conversations.indexWhere(
      (c) => c.id == message.conversation_id,
    );
    if (index != -1) {
      final currentConversation = conversations[index];
      int newUnreadCount = currentConversation.unread_count ?? 0;

      // Increment only if chat not open AND flag is true
      if (incrementUnread &&
          selectedConversation.value?.id != message.conversation_id) {
        newUnreadCount++;
      }
      // If it's the current user's message, unread count shouldn't increase for them
      // Also check if the conversation is currently selected, in which case don't increment
      bool isCurrentConversation =
          selectedConversation.value != null &&
          selectedConversation.value!.id == message.conversation_id;
      if (message.sender_id == userId || isCurrentConversation) {
        newUnreadCount =
            currentConversation.unread_count ?? 0; // Keep existing count
      }
      // Ensure count is not negative
      newUnreadCount = newUnreadCount < 0 ? 0 : newUnreadCount;

      final updatedConversation = currentConversation.copyWith(
        lastMessage:
            message.files != null && message.files!.isNotEmpty
                ? '[Файл] ${message.files!.first.fileName}'
                : message.content,
        lastMessageTime: DateTime.parse(message.created_at),
        unread_count: newUnreadCount,
      );

      // Move updated conversation to top
      conversations.removeAt(index);
      conversations.insert(0, updatedConversation);

      // Update filtered list
      filterConversations();
    }
  }

  // Added optional animate parameter
  void _scrollToBottom({bool animate = true}) {
    // Delay slightly to allow ListView to update
    Future.delayed(Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        if (animate) {
          scrollController.animateTo(
            0.0, // Scroll to top since list is reversed
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          scrollController.jumpTo(0.0); // Jump without animation
        }
      }
    });
  }

  void handleMessageRead(dynamic data) {
    print('Message read event received: $data');
    try {
      final messageId = data['message_id'];
      final readerUserId = data['user_id'];
      final readAt = data['read_at'];
      final readerUsername = data['username'] ?? 'Пользователь';
      final readerEmail = data['email'] ?? '';

      final messageIndex = messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        final currentMessage = messages[messageIndex];
        final currentReadByUsers = currentMessage.read_by_users ?? [];

        if (!currentReadByUsers.any(
          (user) => user.contact_id == readerUserId,
        )) {
          final newReadByUser = ReadByUser(
            contact_id: readerUserId,
            username: readerUsername,
            email: readerEmail,
            read_at: readAt,
          );

          final updatedReadByUsers = [...currentReadByUsers, newReadByUser];

          // Check against participant count for 'read by all' status if needed
          // final totalParticipants = selectedConversation.value?.participants?.length ?? 2; // Assume 2 for dialogs
          // bool readByAll = updatedReadByUsers.length >= totalParticipants;

          messages[messageIndex] = currentMessage.copyWith(
            // is_unread based on current user read status only for simplicity now
            is_unread: !updatedReadByUsers.any((u) => u.contact_id == userId),
            read_by_users: updatedReadByUsers,
          );
          messages
              .refresh(); // Refresh needed to update the read status icon UI
        }
      }

      // Update conversation unread count if necessary (less critical here)
      final conversationId = data['conversation_id'];
      final conversationIndex = conversations.indexWhere(
        (c) => c.id == conversationId,
      );
      if (conversationIndex != -1 && readerUserId == userId) {
        // Only decrement if WE read it
        if (conversations[conversationIndex].unread_count != 0) {
          final updatedConversation = conversations[conversationIndex].copyWith(
            unread_count: 0,
          );
          conversations[conversationIndex] = updatedConversation;
          filterConversations(); // Update filtered list counts
        }
      }
    } catch (e) {
      print("Error processing message read event: $e");
      print("Data: $data");
    }
  }

  // Removed query parameter, uses reactive searchText.value now
  void filterConversations() {
    final query = searchText.value.toLowerCase();

    // Make a temporary list to avoid modifying the list while iterating
    List<Conversation> currentConversations = List.from(conversations);

    if (query.isEmpty) {
      filteredConversations.value =
          currentConversations.where((conversation) {
            return selectedTab.value == 0
                ? conversation.is_group_chat
                : !conversation.is_group_chat;
          }).toList();
    } else {
      filteredConversations.value =
          currentConversations.where((conversation) {
            if (selectedTab.value == 0 && !conversation.is_group_chat)
              return false;
            if (selectedTab.value == 1 && conversation.is_group_chat)
              return false;

            if (conversation.conversation_name.toLowerCase().contains(query))
              return true;
            if (conversation.last_message?.toLowerCase().contains(query) ??
                false)
              return true;

            // Search in participants for group chats
            if (conversation.is_group_chat &&
                conversation.participants != null) {
              return conversation.participants!.any(
                (participant) =>
                    participant.username.toLowerCase().contains(query) ||
                    participant.email.toLowerCase().contains(query),
              );
            }
            // Search other participant name/email in dialogs (assuming name is correct)
            if (!conversation.is_group_chat &&
                conversation.participants != null) {
              final otherParticipant = conversation.participants!
                  .firstWhereOrNull((p) => p.user_id != userId);
              if (otherParticipant != null) {
                return otherParticipant.username.toLowerCase().contains(
                      query,
                    ) ||
                    otherParticipant.email.toLowerCase().contains(query);
              }
            }

            return false;
          }).toList();
    }

    // Sorting should happen on the main conversations list primarily
    // The filtered list will reflect that order if sort is done *before* filtering
    // Or we sort the filtered list here again if needed, but it's already sorted above.
    // filteredConversations.sort((a, b) => ... ); // Already sorted in fetchConversations
  }

  // Removed switchTab as filtering now happens reactively via 'ever'

  void handleAuthentication(dynamic data) async {
    try {
      final userId = data['userId'] as String;
      print('Пользователь $userId аутентифицирован');

      // Обновляем статус пользователя на онлайн
      onlineUsers[userId] = true;

      // Уведомляем всех о том, что пользователь онлайн
      _socketService.socket.emit('userStatusChanged', {
        'userId': userId,
        'isOnline': true,
      });

      print('Статус пользователя $userId обновлен на онлайн');
    } catch (error) {
      print('Ошибка при аутентификации пользователя: $error');
    }
  }

  void handleUserStatusChanged(dynamic data) {
    try {
      final userId = data['userId'] as String;
      final isOnline = data['isOnline'] as bool;

      onlineUsers[userId] = isOnline;
      print(
        'Статус пользователя $userId изменен на ${isOnline ? "онлайн" : "оффлайн"}',
      );
    } catch (error) {
      print('Ошибка при обработке изменения статуса пользователя: $error');
    }
  }

  // Renamed from sendMessageWithFile for clarity
  void selectFileToSend() async {
    final fileService = Get.find<FileService>();
    final result = await fileService.pickFile();
    if (result != null && result.files.isNotEmpty) {
      selectedFile.value = File(result.files.first.path!);
      // Automatically try to send if text is also present or just send file?
      // For now, just select it. User presses send.
      // Optionally trigger send if needed:
      // sendMessage();
    }
  }

  // Added method for downloading file - needed by ChatFileAttachment
  Future<bool> downloadFile(file_model.FileModel file) async {
    if (downloadingFiles.contains(file.id)) return false; // Already downloading

    downloadingFiles.add(file.id);
    final fileService = Get.find<FileService>();
    try {
      final downloaded = await fileService.downloadFile(file.id);
      if (downloaded != null) {
        downloadedFiles.add(file.id); // Mark as downloaded locally
        Get.snackbar(
          'Успешно',
          'Файл "${file.fileName}" загружен',
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      } else {
        Get.snackbar(
          'Ошибка',
          'Не удалось загрузить файл "${file.fileName}"',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      print("Error downloading file ${file.id}: $e");
      Get.snackbar(
        'Ошибка',
        'Произошла ошибка при загрузке файла',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      downloadingFiles.remove(file.id);
    }
  }

  // --- Group Management Methods (Placeholders) ---

  Future<void> removeGroupParticipant(
    String conversationId,
    String participantId,
  ) async {
    isLoading.value = true; // Indicate loading state
    try {
      String token = await _storage.read(key: AppKeys.token) ?? '';
      if (token.isEmpty) {
        Get.snackbar('Ошибка', 'Ошибка аутентификации');
        return;
      }

      final url = Uri.parse('$_baseUrl/conversations/participants/remove');
      print('Removing participant: DELETE $url');

      // Use http.Request for DELETE with body
      final request = http.Request('DELETE', url);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      // Updated body structure
      request.body = jsonEncode({
        'conversation_id': conversationId,
        'participant_id': participantId, // Use participant_id as per API spec
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        Get.snackbar('Успех', 'Участник удален');
        // --- Update Local Data ---
        final conversationIndex = conversations.indexWhere(
          (c) => c.id == conversationId,
        );
        if (conversationIndex != -1) {
          final currentConversation = conversations[conversationIndex];
          final updatedParticipants =
              currentConversation.participants
                  ?.where((p) => p.user_id != participantId)
                  .toList();

          if (updatedParticipants != null) {
            conversations[conversationIndex] = currentConversation.copyWith(
              participants: updatedParticipants,
            );
            // If the current view is this conversation, update it directly
            if (selectedConversation.value?.id == conversationId) {
              selectedConversation.value = conversations[conversationIndex];
            }
            // Refresh lists to update UI (e.g., participant count in header)
            conversations.refresh();
            filterConversations();
          }
        }
        // --- End Update Local Data ---
      } else {
        print(
          'Failed to remove participant: ${response.statusCode} ${response.body}',
        );
        final errorData = jsonDecode(response.body);
        Get.snackbar(
          'Ошибка удаления',
          errorData['message'] ?? 'Не удалось удалить участника',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('Error removing participant: $e');
      Get.snackbar(
        'Ошибка',
        'Произошла ошибка при удалении участника',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addGroupParticipant(
    String conversationId,
    String participantId,
  ) async {
    isLoading.value =
        true; // Indicate loading state, maybe a different one for adding?
    try {
      String token = await _storage.read(key: AppKeys.token) ?? '';
      if (token.isEmpty) {
        Get.snackbar('Ошибка', 'Ошибка аутентификации');
        return;
      }

      final url = Uri.parse('$_baseUrl/conversations/participants/add');
      print('Adding participant: POST $url');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'conversation_id': conversationId,
          'user_id': participantId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // --- Update Local Data ---
        // Since the API only returns a success message, not the participant data,
        // we cannot reliably update the local state without fetching.
        // We will refetch the conversations to get the updated list.
        Get.snackbar('Успех', 'Участник добавлен');
        await fetchConversations(); // Refetch conversations to update the list

        // --- Explicitly update selectedConversation after refetch ---
        final updatedIndex = conversations.indexWhere(
          (c) => c.id == conversationId,
        );
        if (updatedIndex != -1) {
          // Check if the currently selected conversation is still the same one
          if (selectedConversation.value?.id == conversationId) {
            selectedConversation.value = conversations[updatedIndex];
            print(
              '[addGroupParticipant] selectedConversation updated after refetch.',
            );
          }
        }
        // --- End explicit update ---

        /* --- Removed code attempting to parse participant from response ---
        try {
          final addedParticipantData = jsonDecode(utf8.decode(response.bodyBytes));
          final ChatParticipant addedParticipant = ChatParticipant.fromJson(addedParticipantData); // This caused the error
          
          // Update selectedConversation directly for immediate UI refresh in dialog
          if (selectedConversation.value != null && selectedConversation.value!.id == conversationId) {
            final currentParticipants = List<ChatParticipant>.from(selectedConversation.value!.participants ?? []);
            if (!currentParticipants.any((p) => p.user_id == addedParticipant.user_id)) {
               currentParticipants.add(addedParticipant);
               selectedConversation.value = selectedConversation.value!.copyWith(
                 participants: currentParticipants,
               );
            }
          }

          // Also update the main conversations list
          final conversationIndex = conversations.indexWhere((c) => c.id == conversationId);
          if (conversationIndex != -1) {
            final currentParticipantsInList = List<ChatParticipant>.from(conversations[conversationIndex].participants ?? []);
             if (!currentParticipantsInList.any((p) => p.user_id == addedParticipant.user_id)) {
                currentParticipantsInList.add(addedParticipant);
                conversations[conversationIndex] = conversations[conversationIndex].copyWith(
                  participants: currentParticipantsInList,
                );
             }
          }
          
          Get.snackbar('Успех', 'Участник "${addedParticipant.username}" добавлен');
          conversations.refresh(); 
          filterConversations(); 

        } catch (e) {
          print('Error parsing added participant data or updating locally: $e');
          Get.snackbar('Успех', 'Участник добавлен (локальное обновление не удалось)');
          // Fallback to refetch if local update fails
          await fetchConversations(); 
        }
        */
        // --- End Update Local Data ---
      } else {
        print(
          'Failed to add participant: ${response.statusCode} ${response.body}',
        );
        final errorData = jsonDecode(response.body);
        Get.snackbar(
          'Ошибка добавления',
          errorData['message'] ?? 'Не удалось добавить участника',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('Error adding participant: $e');
      Get.snackbar(
        'Ошибка',
        'Произошла ошибка при добавлении участника',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false; // Or the specific loading indicator for adding
    }
  }

  Future<void> updateGroupName(String conversationId, String newName) async {
    isLoading.value = true;
    try {
      String token = await _storage.read(key: AppKeys.token) ?? '';
      if (token.isEmpty) {
        Get.snackbar('Ошибка', 'Ошибка аутентификации');
        return;
      }

      final url = Uri.parse('$_baseUrl/conversations/details');
      print('Updating group name: PATCH $url');

      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'conversation_id': conversationId,
          'conversation_name': newName,
        }),
      );

      if (response.statusCode == 200) {
        // Decode the response containing just the new name
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final String confirmedNewName = responseData['conversation_name'];

        // Don't create a new Conversation from the minimal response
        // final updatedConversationData = jsonDecode(utf8.decode(response.bodyBytes));
        // final updatedConversation = Conversation.fromJson(updatedConversationData); // This caused the error

        Get.snackbar('Успех', 'Название группы обновлено');

        // --- Update Local Data ---
        final conversationIndex = conversations.indexWhere(
          (c) => c.id == conversationId,
        );
        if (conversationIndex != -1) {
          // Create a new Conversation object by copying the old one and updating the name
          final updatedConversation = conversations[conversationIndex].copyWith(
            conversation_name: confirmedNewName, // Update only the name
          );

          conversations[conversationIndex] = updatedConversation;
          // If the current view is this conversation, update it directly
          if (selectedConversation.value?.id == conversationId) {
            selectedConversation.value = updatedConversation;
          }
          // Refresh lists to update UI
          conversations.refresh();
          filterConversations();
        }
        // Close the settings dialog after successful update
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
        // --- End Update Local Data ---
      } else {
        print(
          'Failed to update group name: ${response.statusCode} ${response.body}',
        );
        final errorData = jsonDecode(response.body);
        Get.snackbar(
          'Ошибка обновления',
          errorData['message'] ?? 'Не удалось обновить название группы',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('Error updating group name: $e');
      Get.snackbar(
        'Ошибка',
        'Произошла ошибка при обновлении названия группы',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // --- Method to fetch users for adding to a group ---
  Future<void> fetchUsersForAdding(
    String conversationId, {
    String? searchQuery,
  }) async {
    isLoadingUsers.value = true;
    usersToAddList.clear(); // Clear previous results
    try {
      String token = await _storage.read(key: AppKeys.token) ?? '';
      if (token.isEmpty) {
        Get.snackbar('Ошибка', 'Ошибка аутентификации');
        return;
      }

      // Build query parameters
      Map<String, String> queryParams = {
        'exclude_conversation': conversationId,
      };
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      final url = Uri.parse(
        '$_baseUrl/contacts',
      ).replace(queryParameters: queryParams); // Use /contacts endpoint
      print('Fetching contacts to add: GET $url'); // Update log message

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        // Use correct model name 'Contact'
        usersToAddList.value = data.map((e) => Contact.fromJson(e)).toList();
      } else {
        print(
          'Failed to fetch contacts: ${response.statusCode} ${response.body}',
        ); // Update log message
        Get.snackbar(
          'Ошибка',
          'Не удалось загрузить список контактов',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('Error fetching contacts: $e'); // Update log message
      Get.snackbar(
        'Ошибка',
        'Произошла ошибка при загрузке контактов',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingUsers.value = false;
    }
  }

  // --- End Method to fetch users ---

  // --- Method to toggle chat search mode ---
  void toggleChatSearch() {
    isChatSearchActive.value = !isChatSearchActive.value;
    if (!isChatSearchActive.value) {
      // Clear search query and controller when exiting search mode
      chatSearchController
          .clear(); // This will trigger the listener to clear chatSearchQuery
      chatSearchFocusNode.unfocus();
      // Reset filtered messages list when exiting search mode
      _filterChatMessages(); // Calling with empty query will clear the list
    } else {
      // Request focus when entering search mode
      Future.delayed(
        Duration(milliseconds: 100),
        () => chatSearchFocusNode.requestFocus(),
      );
    }
  }

  // --- End Method to toggle chat search ---

  // --- Private method for filtering chat messages ---
  void _filterChatMessages() {
    final query = chatSearchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      // If query is empty, show all messages (or handle as needed)
      // Assigning the original list might cause issues if AnimatedList modifies it.
      // It's safer to use a copy or handle this in the UI.
      // For now, let's clear the filtered list to indicate no filter is active.
      // The UI will check isChatSearchActive and use the main list.
      filteredMessages.clear();
    } else {
      // Filter the main messages list
      filteredMessages.value =
          messages.where((message) {
            // Basic search in content - case insensitive
            return message.content.toLowerCase().contains(query);
            // TODO: Extend search to sender name, file names etc. if needed
          }).toList();
    }
    // Note: This doesn't handle AnimatedList updates automatically.
    // The UI part needs careful handling.
  }

  // --- End Private method ---
}
