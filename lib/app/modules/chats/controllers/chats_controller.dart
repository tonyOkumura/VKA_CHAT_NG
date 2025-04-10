import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:vka_chat_ng/app/constants.dart';
import 'package:vka_chat_ng/app/data/conversation_model.dart';
import 'package:vka_chat_ng/app/data/message_model.dart';
import 'package:vka_chat_ng/app/data/message_reads_model.dart';
import 'package:vka_chat_ng/app/data/contact_model.dart';
import 'package:vka_chat_ng/app/services/socket_service.dart';
import 'dart:async';
import 'package:vka_chat_ng/app/services/notification_service.dart';

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
  var selectedConversation = Rxn<Conversation>();
  final messageController = TextEditingController();
  final messageFocusNode = FocusNode();
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  final isLoading = false.obs;
  final isLoadingMessages = false.obs;
  late SocketService _socketService;
  late String userId;
  final scrollController = ScrollController();
  final selectedTab = 0.obs; // 0 - чаты, 1 - диалоги
  Timer? _refreshTimer;

  // Список предопределенных цветов для аватаров
  final List<Color> avatarColors = [
    Colors.blue.shade700,
    Colors.red.shade700,
    Colors.green.shade700,
    Colors.orange.shade700,
    Colors.purple.shade700,
    Colors.teal.shade700,
    Colors.pink.shade700,
    Colors.indigo.shade700,
    Colors.amber.shade700,
    Colors.cyan.shade700,
    Colors.grey.shade700,
    Colors.lime.shade700,
    Colors.deepPurple.shade700,
    Colors.deepOrange.shade700,
    Colors.blue.shade300,
    Colors.red.shade300,
    Colors.green.shade300,
    Colors.orange.shade300,
    Colors.purple.shade300,
    Colors.teal.shade300,
    Colors.pink.shade300,
    Colors.indigo.shade300,
    Colors.amber.shade300,
    Colors.cyan.shade300,
    Colors.grey.shade300,
    Colors.lime.shade300,
    Colors.deepPurple.shade300,
    Colors.deepOrange.shade300,
  ];

  // Получение или создание цвета для пользователя
  Color getUserColor(String userId) {
    if (!userColors.containsKey(userId)) {
      // Используем хэш userId для выбора цвета из списка
      final colorIndex = userId.hashCode % avatarColors.length;
      userColors[userId] = avatarColors[colorIndex];
    }
    return userColors[userId]!;
  }

  @override
  void onInit() {
    super.onInit();
    print('ChatsController initialized.');
    _socketService = Get.find<SocketService>();
    _initializeUserId();
    fetchConversations().then((_) {
      // После получения списка чатов подключаемся ко всем
      for (var conversation in conversations) {
        _socketService.joinConversation(conversation.id);
      }
    });
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.minScrollExtent) {
        print('Reached the top of the list.');
      }
    });
    // Запускаем периодическое обновление каждые 5 минут
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
    messageController.dispose();
    messageFocusNode.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    scrollController.dispose();
    _socketService.socket.off('newMessage', handleIncomingMessage);
    _socketService.socket.off('messageRead', handleMessageRead);
    print('ChatsController disposed.');
    _refreshTimer?.cancel(); // Отменяем таймер при закрытии контроллера
    super.onClose();
  }

  Future<void> _initializeUserId() async {
    userId = await _storage.read(key: AppKeys.userId) ?? '';
    print('User ID: $userId');

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
    var response = await http.get(
      Uri.parse('$_baseUrl/conversations'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      conversations.value = await Future.wait(
        data.map((e) async {
          final conversation = Conversation.fromJson(e);
          if (conversation.is_group_chat) {
            final participantsResponse = await http.post(
              Uri.parse('$_baseUrl/conversations/participants'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'conversation_id': conversation.id}),
            );
            if (participantsResponse.statusCode == 200) {
              final participantsData = jsonDecode(participantsResponse.body);
              return conversation.copyWith(
                participants:
                    participantsData.map((p) => Contact.fromJson(p)).toList(),
              );
            }
          }
          return conversation;
        }),
      );

      // Сортируем чаты по времени последнего сообщения
      conversations.sort((a, b) {
        // Если у обоих чатов есть последнее сообщение
        if (a.last_message_time != null && b.last_message_time != null) {
          return b.last_message_time!.compareTo(a.last_message_time!);
        }
        // Если только у одного есть последнее сообщение, он идет первым
        if (a.last_message_time != null) return -1;
        if (b.last_message_time != null) return 1;
        // Если у обоих нет последнего сообщения, сортируем по ID
        return b.id.compareTo(a.id);
      });

      // Инициализируем отфильтрованный список с учетом текущей вкладки
      filterConversations(searchController.text);
      print('Conversations fetched successfully.');
    } else {
      print('Failed to fetch conversations: ${response.body}');
    }
    isLoading.value = false;
  }

  Future<void> fetchMessages() async {
    isLoadingMessages.value = true;
    messages.clear();
    print('Fetching messages...');
    String token = await _storage.read(key: AppKeys.token) ?? '';
    var response = await http.get(
      Uri.parse('$_baseUrl/messages/${selectedConversation.value!.id}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      messages.addAll(
        data.map((e) {
          final message = Message.fromJson(e);
          // Устанавливаем is_unread в зависимости от количества прочитавших
          final readCount = message.read_by_users?.length ?? 0;
          return message.copyWith(
            is_unread: readCount < 2, // Если прочитал только один человек
          );
        }),
      );
      print('Messages fetched successfully.');
    } else {
      print('Failed to fetch messages: ${response.body}');
    }
    isLoadingMessages.value = false;
    _scrollToBottom();
  }

  void _markAllMessagesAsRead() {
    if (selectedConversation.value != null) {
      // Отправляем событие через сокет
      _socketService.socket.emit('markMessagesAsRead', {
        'conversation_id': selectedConversation.value!.id,
        'user_id': userId,
      });

      // Обновляем счетчик непрочитанных в текущем чате
      final conversationIndex = conversations.indexWhere(
        (c) => c.id == selectedConversation.value!.id,
      );
      if (conversationIndex != -1) {
        final updatedConversation = conversations[conversationIndex].copyWith(
          unread_count: 0,
        );
        conversations[conversationIndex] = updatedConversation;
        conversations.refresh();
      }

      // Обновляем статус всех сообщений как прочитанных
      messages.value =
          messages.map((message) {
            if (!message.read_by_users!.any(
              (user) => user.contact_id == userId,
            )) {
              final newReadByUser = ReadByUser(
                contact_id: userId,
                username:
                    'Вы', // Или можно использовать реальное имя пользователя
                email: '',
                read_at: DateTime.now().toIso8601String(),
              );
              return message.copyWith(
                is_unread: false,
                read_by_users: [...message.read_by_users ?? [], newReadByUser],
              );
            }
            return message;
          }).toList();
      messages.refresh();
    }
  }

  Future<void> sendMessage() async {
    if (messageController.text.isNotEmpty &&
        selectedConversation.value != null) {
      print('Sending message: ${messageController.text}');

      _socketService.sendMessageWithParams(
        selectedConversation.value!.id,
        messageController.text,
        userId,
      );
      messageController.clear();
    } else {
      print('Message is empty or no conversation selected.');
    }
  }

  void handleIncomingMessage(dynamic data) {
    print('New message received: $data');
    final message = Message.fromJson(data);

    if (selectedConversation.value != null &&
        message.conversation_id == selectedConversation.value!.id) {
      // Устанавливаем is_unread в зависимости от количества прочитавших
      final readCount = message.read_by_users?.length ?? 0;
      final updatedMessage = message.copyWith(
        is_unread: readCount < 2, // Если прочитал только один человек
      );
      messages.insert(0, updatedMessage);
      _scrollToBottom();
    }
    _updateConversationLastMessage(message);
  }

  void _updateConversationLastMessage(Message message) {
    final index = conversations.indexWhere(
      (c) => c.id == message.conversation_id,
    );
    if (index != -1) {
      final updatedConversation = conversations[index].copyWith(
        lastMessage: message.content,
        lastMessageTime: DateTime.parse(message.created_at),
        // Увеличиваем счетчик непрочитанных только если это не текущий чат
        unread_count:
            selectedConversation.value?.id == message.conversation_id
                ? 0 // Если это текущий чат, сообщения считаются прочитанными
                : (conversations[index].unread_count ?? 0) + 1,
      );
      conversations[index] = updatedConversation;
      conversations.refresh();

      // Если это не текущий чат, обновляем его позицию в списке
      if (selectedConversation.value?.id != message.conversation_id) {
        // Удаляем чат из текущей позиции
        final conversation = conversations.removeAt(index);
        // Добавляем его в начало списка
        conversations.insert(0, conversation);
      }

      // Обновляем отфильтрованный список
      filterConversations(searchController.text);
    }
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void handleMessageRead(dynamic data) {
    print('Message read event received: $data');
    final messageId = data['message_id'];
    final userId = data['user_id'];
    final readAt = data['read_at'];

    // Обновляем статус сообщения в списке
    final messageIndex = messages.indexWhere((m) => m.id == messageId);
    if (messageIndex != -1) {
      final currentMessage = messages[messageIndex];
      final currentReadByUsers = currentMessage.read_by_users ?? [];

      // Проверяем, не прочитал ли уже этот пользователь сообщение
      if (!currentReadByUsers.any((user) => user.contact_id == userId)) {
        final newReadByUser = ReadByUser(
          contact_id: userId,
          username: data['username'] ?? 'Пользователь',
          email: data['email'] ?? '',
          read_at: readAt,
        );

        final updatedReadByUsers = [...currentReadByUsers, newReadByUser];

        // Обновляем сообщение с новым списком прочитавших
        messages[messageIndex] = currentMessage.copyWith(
          is_unread:
              updatedReadByUsers.length <
              2, // Если прочитал только один человек
          read_by_users: updatedReadByUsers,
        );
        messages.refresh();

        // Если это сообщение в текущем чате, обновляем статус в списке чатов
        if (selectedConversation.value != null &&
            currentMessage.conversation_id == selectedConversation.value!.id) {
          final conversationIndex = conversations.indexWhere(
            (c) => c.id == currentMessage.conversation_id,
          );
          if (conversationIndex != -1) {
            final currentUnreadCount =
                conversations[conversationIndex].unread_count ?? 0;
            final updatedConversation = conversations[conversationIndex]
                .copyWith(
                  unread_count:
                      currentUnreadCount > 0 ? currentUnreadCount - 1 : 0,
                );
            conversations[conversationIndex] = updatedConversation;
            conversations.refresh();
          }
        }
      }
    }
  }

  List<MessageReads> getMessageReads(String messageId) {
    return messageReads[messageId] ?? [];
  }

  void showMessageReadsDialog(
    BuildContext context,
    String messageId,
    Offset position,
    Size size,
  ) {
    final message = messages.firstWhere((m) => m.id == messageId);
    // Фильтруем список прочитавших, исключая текущего пользователя
    final reads =
        (message.read_by_users ?? [])
            .where((read) => read.contact_id != userId)
            .toList();

    if (reads.isEmpty) {
      _showReadStatusPopup(context, position, size, [], false);
      return;
    }

    _showReadStatusPopup(context, position, size, reads, true);
  }

  void _showReadStatusPopup(
    BuildContext context,
    Offset position,
    Size size,
    List<ReadByUser> reads,
    bool hasReads,
  ) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy - 200, // Увеличиваем отступ сверху
        position.dx + size.width,
        position.dy,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 300,
              maxHeight: 250, // Ограничиваем высоту контейнера
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasReads ? 'Прочитано' : 'Не прочитано',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Get.theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 8),
                Expanded(
                  // Добавляем Expanded для прокрутки
                  child: SingleChildScrollView(
                    // Добавляем прокрутку
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasReads)
                          ...reads.map(
                            (read) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: getUserColor(
                                      read.contact_id,
                                    ),
                                    child: Text(
                                      read.username[0],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          read.username,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                Get.theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('HH:mm dd.MM.yyyy').format(
                                            DateTime.parse(read.read_at),
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                Get
                                                    .theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Text(
                            'Сообщение еще никто не прочитал',
                            style: TextStyle(
                              color: Get.theme.colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void filterConversations(String query) {
    if (query.isEmpty) {
      filteredConversations.value =
          conversations.where((conversation) {
            return selectedTab.value == 0
                ? conversation.is_group_chat
                : !conversation.is_group_chat;
          }).toList();
    } else {
      query = query.toLowerCase();
      filteredConversations.value =
          conversations.where((conversation) {
            // Сначала проверяем тип чата
            if (selectedTab.value == 0 && !conversation.is_group_chat)
              return false;
            if (selectedTab.value == 1 && conversation.is_group_chat)
              return false;

            // Затем проверяем поисковый запрос
            if (conversation.conversation_name.toLowerCase().contains(query)) {
              return true;
            }

            if (conversation.last_message?.toLowerCase().contains(query) ??
                false) {
              return true;
            }

            if (conversation.is_group_chat &&
                conversation.participants != null) {
              return conversation.participants!.any(
                (participant) =>
                    participant.username.toLowerCase().contains(query) ||
                    participant.email.toLowerCase().contains(query),
              );
            }

            return false;
          }).toList();
    }

    // Сортируем отфильтрованные чаты по времени последнего сообщения
    filteredConversations.sort((a, b) {
      // Если у обоих чатов есть последнее сообщение
      if (a.last_message_time != null && b.last_message_time != null) {
        return b.last_message_time!.compareTo(a.last_message_time!);
      }
      // Если только у одного есть последнее сообщение, он идет первым
      if (a.last_message_time != null) return -1;
      if (b.last_message_time != null) return 1;
      // Если у обоих нет последнего сообщения, сортируем по ID
      return b.id.compareTo(a.id);
    });
  }

  // Добавляем метод для переключения вкладок
  void switchTab(int index) {
    selectedTab.value = index;
    filterConversations(searchController.text);
  }

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
}
