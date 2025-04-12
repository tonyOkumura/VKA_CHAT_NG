import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:vka_chat_ng/app/data/models/chat_participant_model.dart';
import 'package:vka_chat_ng/app/data/models/conversation_model.dart';
import 'package:vka_chat_ng/app/data/models/message_model.dart';
import 'package:vka_chat_ng/app/routes/app_pages.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vka_chat_ng/app/widgets/main_layout.dart';
import 'package:vka_chat_ng/app/services/file_service.dart';
import '../controllers/chats_controller.dart';

class ChatsView extends GetView<ChatsController> {
  const ChatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text('chats'.tr),
          centerTitle: false,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () async {
                await controller.fetchConversations();
                if (controller.selectedConversation.value != null) {
                  controller.fetchMessages();
                }
              },
              icon: Icon(Icons.refresh),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            // На маленьких экранах показываем либо список, либо детали
            if (constraints.maxWidth < 900) {
              return Obx(
                () =>
                    controller.selectedConversation.value == null
                        ? ChatList()
                        : ChatDetail(),
              );
            }

            // На больших экранах показываем разделенный вид
            return Row(
              children: [
                // Список чатов
                Container(
                  width: constraints.maxWidth * 0.3,
                  constraints: BoxConstraints(maxWidth: 400),
                  child: ChatList(),
                ),
                // Детали чата
                Expanded(
                  child: Obx(
                    () =>
                        controller.selectedConversation.value == null
                            ? Center(child: Text('select_chat'.tr))
                            : ChatDetail(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ChatList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    return Container(
      child: Column(
        children: [
          // Добавляем переключатель вкладок
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: () => controller.switchTab(0),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            controller.selectedTab.value == 0
                                ? Get.theme.colorScheme.primaryContainer
                                : Get.theme.colorScheme.surface,
                        foregroundColor:
                            controller.selectedTab.value == 0
                                ? Get.theme.colorScheme.onPrimaryContainer
                                : Get.theme.colorScheme.onSurface,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Группы'),
                          SizedBox(width: 4),
                          Obx(() {
                            final unreadGroups =
                                controller.conversations
                                    .where(
                                      (c) =>
                                          c.is_group_chat &&
                                          (c.unread_count ?? 0) > 0,
                                    )
                                    .length;
                            if (unreadGroups > 0) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Get.theme.colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$unreadGroups',
                                  style: TextStyle(
                                    color: Get.theme.colorScheme.onSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                            return SizedBox.shrink();
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: () => controller.switchTab(1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            controller.selectedTab.value == 1
                                ? Get.theme.colorScheme.primaryContainer
                                : Get.theme.colorScheme.surface,
                        foregroundColor:
                            controller.selectedTab.value == 1
                                ? Get.theme.colorScheme.onPrimaryContainer
                                : Get.theme.colorScheme.onSurface,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Диалоги'),
                          SizedBox(width: 4),
                          Obx(() {
                            final unreadDialogs =
                                controller.conversations
                                    .where(
                                      (c) =>
                                          !c.is_group_chat &&
                                          (c.unread_count ?? 0) > 0,
                                    )
                                    .length;
                            if (unreadDialogs > 0) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Get.theme.colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$unreadDialogs',
                                  style: TextStyle(
                                    color: Get.theme.colorScheme.onSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                            return SizedBox.shrink();
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Поле поиска
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controller.searchController,
              focusNode: controller.searchFocusNode,
              decoration: InputDecoration(
                hintText:
                    'Поиск ${controller.selectedTab.value == 0 ? 'чатов' : 'диалогов'}...',
                prefixIcon: Icon(Icons.search),
                suffixIcon:
                    controller.searchController.text.isNotEmpty
                        ? InkWell(
                          onTap: () {
                            controller.searchController.clear();
                            controller.filterConversations('');
                          },
                          child: Icon(Icons.clear),
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Get.theme.colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Get.theme.colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Get.theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Get.theme.colorScheme.surfaceVariant,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) => controller.filterConversations(value),
              onTapOutside: (event) => controller.searchFocusNode.unfocus(),
              onSubmitted: (value) => controller.searchFocusNode.unfocus(),
            ),
          ),
          // Список чатов/диалогов
          Expanded(
            child: Obx(
              () =>
                  controller.isLoading.value
                      ? Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: ListView.builder(
                          itemCount: 10,
                          itemBuilder:
                              (context, index) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.white,
                                ),
                                title: Container(
                                  width: double.infinity,
                                  height: 10.0,
                                  color: Colors.white,
                                ),
                                subtitle: Container(
                                  width: double.infinity,
                                  height: 10.0,
                                  color: Colors.white,
                                ),
                              ),
                        ),
                      )
                      : ListView.builder(
                        itemCount: controller.filteredConversations.length,
                        itemBuilder: (context, index) {
                          final conversation =
                              controller.filteredConversations[index];
                          return ListTile(
                            leading:
                                conversation.is_group_chat
                                    ? Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Get.theme.colorScheme.tertiary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.group,
                                        color: Get.theme.colorScheme.onTertiary,
                                      ),
                                    )
                                    : CircleAvatar(
                                      radius: 20,
                                      backgroundColor:
                                          Get.theme.colorScheme.primary,
                                      child: Text(
                                        conversation.conversation_name[0]
                                            .toUpperCase(),
                                        style: TextStyle(
                                          color:
                                              Get.theme.colorScheme.onPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            title: Text(
                              conversation.conversation_name,
                              style: TextStyle(
                                color: Get.theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              maxLines: 1,
                              conversation.last_message ?? "",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Get.theme.colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('MMMM d , HH:mm').format(
                                    conversation.last_message_time ??
                                        DateTime.now(),
                                  ),
                                  style: TextStyle(
                                    color:
                                        Get.theme.colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 5),
                                if (conversation.unread_count != 0)
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Get.theme.colorScheme.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        (conversation.unread_count ?? 0) > 99
                                            ? '99'
                                            : conversation.unread_count
                                                .toString(),
                                        style: TextStyle(
                                          color:
                                              Get.theme.colorScheme.onSecondary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () {
                              controller.selectConversation(
                                controller.conversations.indexWhere(
                                  (c) => c.id == conversation.id,
                                ),
                              );
                            },
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [ChatHeader(), Expanded(child: ChatMessages()), ChatInput()],
      ),
    );
  }
}

class ChatHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    return Obx(() {
      final conversation = controller.selectedConversation.value!;
      return Container(
        padding: EdgeInsets.all(16),
        color: Get.theme.colorScheme.primaryContainer,
        child: Row(
          children: [
            // Кнопка "назад" для маленьких экранов
            if (MediaQuery.of(context).size.width < 1000)
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Get.theme.colorScheme.onPrimaryContainer,
                ),
                onPressed: () => controller.selectConversation(null),
              ),
            conversation.is_group_chat
                ? Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Get.theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.group,
                    color: Get.theme.colorScheme.onPrimary,
                  ),
                )
                : CircleAvatar(
                  radius: 20,
                  backgroundColor: Get.theme.colorScheme.primary,
                  child: Text(
                    conversation.conversation_name[0].toUpperCase(),
                    style: TextStyle(
                      color: Get.theme.colorScheme.onPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            SizedBox(width: 16),
            Expanded(
              child:
                  conversation.is_group_chat
                      ? GestureDetector(
                        onTap: () {
                          _showParticipantsPopup(context, conversation);
                        },
                        child: Row(
                          children: [
                            Text(
                              conversation.conversation_name,
                              style: TextStyle(
                                color: Get.theme.colorScheme.onPrimaryContainer,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Get.theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${conversation.participants?.length ?? 0} участников',
                                style: TextStyle(
                                  color: Get.theme.colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      : Text(
                        conversation.conversation_name,
                        style: TextStyle(
                          color: Get.theme.colorScheme.onPrimaryContainer,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: Get.theme.colorScheme.onPrimaryContainer,
              ),
              onPressed: () {
                // TODO: Implement chat options menu
              },
            ),
          ],
        ),
      );
    });
  }

  void _showParticipantsPopup(BuildContext context, Conversation conversation) {
    final controller = Get.find<ChatsController>();
    final RenderBox button = context.findRenderObject() as RenderBox;
    final position = button.localToGlobal(Offset.zero);
    final size = button.size;

    final sortedParticipants =
        (conversation.participants ?? [])..sort((a, b) {
          // Сначала сортируем по онлайн статусу
          if (a.is_online != b.is_online) {
            return b.is_online ? 1 : -1;
          }
          // Затем по имени пользователя
          return a.username.compareTo(b.username);
        });

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height,
        position.dx + size.width,
        position.dy + size.height + 300,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          child: Container(
            constraints: BoxConstraints(maxWidth: 300, maxHeight: 250),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Участники группы',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Get.theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          sortedParticipants
                              .map(
                                (participant) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: controller
                                            .getUserColor(participant.user_id),
                                        child: Text(
                                          participant.username[0].toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              participant.username,
                                              style: TextStyle(
                                                color:
                                                    Get
                                                        .theme
                                                        .colorScheme
                                                        .onSurface,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              participant.email,
                                              style: TextStyle(
                                                color:
                                                    Get
                                                        .theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (participant.is_online)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
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
}

class ChatMessages extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    final screenWidth = MediaQuery.of(context).size.width;

    // Определяем максимальную ширину сообщения в зависимости от размера экрана
    final maxMessageWidth =
        screenWidth < 600
            ? screenWidth *
                0.85 // 85% ширины экрана для мобильных
            : screenWidth < 900
            ? screenWidth *
                0.7 // 70% для планшетов
            : screenWidth * 0.5; // 50% для десктопов

    return Obx(
      () =>
          controller.isLoadingMessages.value
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                controller: controller.scrollController,
                reverse: true,
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final isSender = message.sender_id == controller.userId;
                  final messageDate = DateTime.parse(message.created_at);

                  final showDateHeader =
                      index == controller.messages.length - 1 ||
                      messageDate.day !=
                          DateTime.parse(
                            controller.messages[index + 1].created_at,
                          ).day;

                  return Column(
                    children: [
                      if (showDateHeader) _buildDateHeader(messageDate),
                      Align(
                        alignment:
                            isSender
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxMessageWidth,
                          ),
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            padding: EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color:
                                  isSender
                                      ? Get.theme.colorScheme.tertiaryContainer
                                      : Get
                                          .theme
                                          .colorScheme
                                          .secondaryContainer,
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Get.theme.colorScheme.shadow
                                      .withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  isSender
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                              children: [
                                if (!isSender &&
                                    controller
                                        .selectedConversation
                                        .value!
                                        .is_group_chat) ...[
                                  Text(
                                    message.sender_username,
                                    style: TextStyle(
                                      color: controller.getUserColor(
                                        message.sender_id,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                ],
                                if (message.content.isNotEmpty) ...[
                                  Text(
                                    message.content,
                                    style: TextStyle(
                                      color:
                                          isSender
                                              ? Get
                                                  .theme
                                                  .colorScheme
                                                  .onTertiaryContainer
                                              : Get
                                                  .theme
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                      fontSize: 16,
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                ],
                                // Отображаем файлы только если они есть и не пусты
                                if (message.files != null &&
                                    message.files!.isNotEmpty)
                                  Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Get.theme.colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListTile(
                                      leading: _getFileIcon(
                                        message.files!.first.fileType,
                                      ),
                                      title: Text(
                                        message.files!.first.fileName,
                                        style: TextStyle(
                                          color:
                                              Get
                                                  .theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        _formatFileSize(
                                          message.files!.first.fileSize,
                                        ),
                                        style: TextStyle(
                                          color: Get
                                              .theme
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: Obx(() {
                                        final controller =
                                            Get.find<ChatsController>();
                                        final fileService =
                                            Get.find<FileService>();
                                        final file = message.files!.first;
                                        final filePath =
                                            '${Platform.environment['USERPROFILE']}\\Downloads\\VKA Chat\\${file.fileName}';
                                        final isDownloading = controller
                                            .downloadingFiles
                                            .contains(file.id);

                                        if (isDownloading) {
                                          return SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Get
                                                        .theme
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                            ),
                                          );
                                        }

                                        return FutureBuilder<bool>(
                                          future: File(filePath).exists(),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData &&
                                                snapshot.data!) {
                                              // Файл существует
                                              return IconButton(
                                                icon: Icon(
                                                  Icons.open_in_new,
                                                  color:
                                                      Get
                                                          .theme
                                                          .colorScheme
                                                          .primary,
                                                ),
                                                onPressed: () async {
                                                  final result =
                                                      await Process.run('cmd', [
                                                        '/c',
                                                        'start',
                                                        '',
                                                        filePath,
                                                      ]);
                                                  if (result.exitCode != 0) {
                                                    Get.snackbar(
                                                      'Ошибка',
                                                      'Не удалось открыть файл',
                                                      snackPosition:
                                                          SnackPosition.BOTTOM,
                                                    );
                                                  }
                                                },
                                              );
                                            } else {
                                              // Файл не существует
                                              return IconButton(
                                                icon: Icon(
                                                  Icons.download,
                                                  color:
                                                      Get
                                                          .theme
                                                          .colorScheme
                                                          .primary,
                                                ),
                                                onPressed: () async {
                                                  controller.downloadingFiles
                                                      .add(file.id);
                                                  final downloadedFile =
                                                      await fileService
                                                          .downloadFile(
                                                            file.id,
                                                          );
                                                  controller.downloadingFiles
                                                      .remove(file.id);

                                                  if (downloadedFile != null) {
                                                    controller.downloadedFiles
                                                        .add(file.id);
                                                    Get.snackbar(
                                                      'Успешно',
                                                      'Файл загружен',
                                                      snackPosition:
                                                          SnackPosition.BOTTOM,
                                                    );
                                                  } else {
                                                    Get.snackbar(
                                                      'Ошибка',
                                                      'Не удалось загрузить файл',
                                                      snackPosition:
                                                          SnackPosition.BOTTOM,
                                                    );
                                                  }
                                                },
                                              );
                                            }
                                          },
                                        );
                                      }),
                                      onTap: () async {
                                        final controller =
                                            Get.find<ChatsController>();
                                        final fileService =
                                            Get.find<FileService>();
                                        final file = message.files!.first;
                                        final filePath =
                                            '${Platform.environment['USERPROFILE']}\\Downloads\\VKA Chat\\${file.fileName}';
                                        final localFile = File(filePath);

                                        if (await localFile.exists()) {
                                          // Если файл существует, открываем его
                                          final result = await Process.run(
                                            'cmd',
                                            ['/c', 'start', '', filePath],
                                          );
                                          if (result.exitCode != 0) {
                                            Get.snackbar(
                                              'Ошибка',
                                              'Не удалось открыть файл',
                                              snackPosition:
                                                  SnackPosition.BOTTOM,
                                            );
                                          }
                                        } else {
                                          // Если файла нет, показываем диалог с предложением загрузить
                                          Get.dialog(
                                            AlertDialog(
                                              title: Text('Загрузка файла'),
                                              content: Text(
                                                'Файл не найден в системе. Хотите загрузить его?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Get.back(),
                                                  child: Text('Отмена'),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    Get.back();
                                                    controller.downloadingFiles
                                                        .add(file.id);
                                                    final downloadedFile =
                                                        await fileService
                                                            .downloadFile(
                                                              file.id,
                                                            );
                                                    controller.downloadingFiles
                                                        .remove(file.id);

                                                    if (downloadedFile !=
                                                        null) {
                                                      controller.downloadedFiles
                                                          .add(file.id);
                                                      Get.snackbar(
                                                        'Успешно',
                                                        'Файл загружен',
                                                        snackPosition:
                                                            SnackPosition
                                                                .BOTTOM,
                                                      );
                                                    } else {
                                                      Get.snackbar(
                                                        'Ошибка',
                                                        'Не удалось загрузить файл',
                                                        snackPosition:
                                                            SnackPosition
                                                                .BOTTOM,
                                                      );
                                                    }
                                                  },
                                                  child: Text('Загрузить'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment:
                                      isSender
                                          ? MainAxisAlignment.end
                                          : MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('HH:mm').format(
                                        DateTime.parse(message.created_at),
                                      ),
                                      style: TextStyle(
                                        color:
                                            isSender
                                                ? Get
                                                    .theme
                                                    .colorScheme
                                                    .onTertiaryContainer
                                                : Get
                                                    .theme
                                                    .colorScheme
                                                    .onSecondaryContainer,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (isSender) ...[
                                      SizedBox(width: 4),
                                      SizedBox(
                                        width: 20,
                                        child: _buildReadStatus(message),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 16.0),
      child: Text(
        _formatDate(date),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Nunito',
          color: Get.theme.colorScheme.secondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "Сегодня";
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return "Вчера";
    } else {
      return "${date.day}.${date.month}.${date.year}";
    }
  }

  Widget _buildReadStatus(Message message) {
    final controller = Get.find<ChatsController>();
    final readByOthers =
        message.read_by_users
            ?.where((user) => user.contact_id != controller.userId)
            .toList() ??
        [];
    final isReadByCurrentUser =
        message.read_by_users?.any(
          (user) => user.contact_id == controller.userId,
        ) ??
        false;
    final readCount = readByOthers.length;

    return PopupMenuButton<void>(
      enabled: true,
      tooltip: '',
      offset: Offset(0, -10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder:
          (context) => [
            if (readCount == 0)
              PopupMenuItem<void>(
                enabled: false,
                height: 40,
                child: Text(
                  'message_no_reads'.tr,
                  style: TextStyle(
                    color: Get.theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              )
            else
              ...readByOthers
                  .map(
                    (user) => PopupMenuItem<void>(
                      enabled: false,
                      height: 50,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: controller.getUserColor(
                              user.contact_id,
                            ),
                            child: Text(
                              user.username[0],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  user.username,
                                  style: TextStyle(
                                    color: Get.theme.colorScheme.onSurface,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'MMM d HH:mm',
                                  ).format(DateTime.parse(user.read_at)),
                                  style: TextStyle(
                                    color:
                                        Get.theme.colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.check,
                            size: 16,
                            color: Get.theme.colorScheme.tertiary,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
          ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isReadByCurrentUser)
            Icon(Icons.check, size: 16)
          else if (readCount == 0)
            Icon(
              Icons.check,
              size: 16,
              color: Get.theme.colorScheme.onTertiaryContainer,
            )
          else
            Icon(
              Icons.done_all,
              size: 16,
              color: Get.theme.colorScheme.onTertiaryContainer,
            ),
        ],
      ),
    );
  }

  Widget _getFileIcon(String fileType) {
    if (fileType.startsWith('image/')) {
      return Icon(Icons.image, color: Get.theme.colorScheme.primary);
    } else if (fileType.startsWith('video/')) {
      return Icon(Icons.video_file, color: Get.theme.colorScheme.primary);
    } else if (fileType.startsWith('audio/')) {
      return Icon(Icons.audio_file, color: Get.theme.colorScheme.primary);
    } else if (fileType == 'application/pdf') {
      return Icon(Icons.picture_as_pdf, color: Get.theme.colorScheme.primary);
    } else if (fileType.startsWith('application/')) {
      return Icon(
        Icons.insert_drive_file,
        color: Get.theme.colorScheme.primary,
      );
    } else {
      return Icon(Icons.attach_file, color: Get.theme.colorScheme.primary);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class ChatInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    final fileService = Get.find<FileService>();

    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(color: Get.theme.colorScheme.surface),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: Get.theme.colorScheme.primary),
            onPressed: () async {
              final result = await fileService.pickFile();
              if (result != null && result.files.isNotEmpty) {
                final file = File(result.files.first.path!);
                controller.sendMessageWithFile(file);
              }
            },
          ),
          Expanded(
            child: TextField(
              controller: controller.messageController,
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.send,
              keyboardType: TextInputType.multiline,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'type_message'.tr,
                hintStyle: TextStyle(
                  color: Get.theme.colorScheme.onSurfaceVariant,
                  fontFamily: 'Nunito',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide(color: Get.theme.colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide(color: Get.theme.colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide(
                    color: Get.theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                filled: true,
                fillColor: Get.theme.colorScheme.surfaceVariant,
              ),
              style: TextStyle(
                color: Get.theme.colorScheme.onSurfaceVariant,
                fontSize: 16,
                fontFamily: 'Nunito',
              ),
              cursorColor: Get.theme.colorScheme.primary,
              focusNode: controller.messageFocusNode,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  controller.sendMessage();
                  controller.messageController.clear();
                  controller.messageFocusNode.requestFocus();
                }
              },
            ),
          ),
          SizedBox(width: 8.0),
          IconButton(
            icon: Icon(Icons.send, color: Get.theme.colorScheme.primary),
            onPressed: () {
              if (controller.messageController.text.isNotEmpty) {
                controller.sendMessage();
                controller.messageController.clear();
                controller.messageFocusNode.requestFocus();
              }
            },
          ),
        ],
      ),
    );
  }
}
