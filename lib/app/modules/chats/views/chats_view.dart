import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vka_chat_ng/app/data/message_model.dart';
import 'package:vka_chat_ng/app/routes/app_pages.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/chats_controller.dart';

class ChatsView extends GetView<ChatsController> {
  const ChatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('chats'.tr), centerTitle: false, elevation: 0),
      drawer: AppDrawer(),
      body: Row(
        children: [
          Expanded(flex: 2, child: Container(child: ChatList())),
          Expanded(
            flex: 5,
            child: Container(
              child: Obx(
                () =>
                    controller.selectedConversation.value == null
                        ? Center(child: Text('select_chat'.tr))
                        : ChatDetail(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Get.theme.colorScheme.primaryContainer,
            ),
            child: Text(
              'menu'.tr,
              style: TextStyle(
                color: Get.theme.colorScheme.onPrimaryContainer,
                fontSize: 20,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('messages'.tr),
            onTap: () {
              Get.back();
            },
          ),
          ListTile(
            leading: Icon(Icons.contacts),
            title: Text('contacts'.tr),
            onTap: () {
              Get.toNamed(Routes.CONTACTS);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('settings'.tr),
            onTap: () {
              Get.offNamed(Routes.SETTINGS);
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('logout'.tr),
            onTap: () {
              final _storage = FlutterSecureStorage();
              _storage.delete(key: 'token');
              _storage.delete(key: 'userId');
              print("Logged out");
              Get.offAllNamed(Routes.LOGIN);
            },
          ),
        ],
      ),
    );
  }
}

class ChatList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    return Container(
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
                          leading: CircleAvatar(backgroundColor: Colors.white),
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
                  itemCount: controller.conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = controller.conversations[index];
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
                                backgroundColor: Get.theme.colorScheme.primary,
                                child: Text(
                                  conversation.conversation_name[0]
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: Get.theme.colorScheme.onPrimary,
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
                              conversation.last_message_time ?? DateTime.now(),
                            ),
                            style: TextStyle(
                              color: Get.theme.colorScheme.onSurfaceVariant,
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
                                  conversation.unread_count.toString(),
                                  style: TextStyle(
                                    color: Get.theme.colorScheme.onSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        controller.selectConversation(index);
                      },
                    );
                  },
                ),
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
              child: Text(
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
}

class ChatMessages extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
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
                            maxWidth: MediaQuery.of(context).size.width * 0.5,
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
}

class ChatInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(color: Get.theme.colorScheme.surface),
      child: Row(
        children: [
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
