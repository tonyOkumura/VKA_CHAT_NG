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
      appBar: AppBar(
        title: Text('chats'.tr),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Get.theme.colorScheme.primary,
        foregroundColor: Get.theme.colorScheme.onPrimary,
      ),
      drawer: AppDrawer(),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Get.theme.colorScheme.surface,
                border: Border(
                  right: BorderSide(
                    color: Get.theme.colorScheme.outline.withOpacity(0.1),
                  ),
                ),
              ),
              child: ChatList(),
            ),
          ),
          Expanded(
            flex: 5,
            child: Container(
              color: Get.theme.colorScheme.background,
              child: Obx(
                () =>
                    controller.selectedConversation.value == null
                        ? Center(
                          child: Text(
                            'select_chat'.tr,
                            style: TextStyle(
                              color: Get.theme.colorScheme.onBackground,
                              fontSize: 16,
                            ),
                          ),
                        )
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
      backgroundColor: Get.theme.colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Get.theme.colorScheme.primary),
            child: Text(
              'menu'.tr,
              style: TextStyle(
                color: Get.theme.colorScheme.onPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: Get.theme.colorScheme.onSurface),
            title: Text(
              'messages'.tr,
              style: TextStyle(color: Get.theme.colorScheme.onSurface),
            ),
            onTap: () {
              Get.back();
            },
          ),
          ListTile(
            leading: Icon(
              Icons.contacts,
              color: Get.theme.colorScheme.onSurface,
            ),
            title: Text(
              'contacts'.tr,
              style: TextStyle(color: Get.theme.colorScheme.onSurface),
            ),
            onTap: () {
              Get.toNamed(Routes.CONTACTS);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.settings,
              color: Get.theme.colorScheme.onSurface,
            ),
            title: Text(
              'settings'.tr,
              style: TextStyle(color: Get.theme.colorScheme.onSurface),
            ),
            onTap: () {
              Get.toNamed(Routes.SETTINGS);
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Get.theme.colorScheme.onSurface),
            title: Text(
              'logout'.tr,
              style: TextStyle(color: Get.theme.colorScheme.onSurface),
            ),
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
                  baseColor: Get.theme.colorScheme.surface,
                  highlightColor: Get.theme.colorScheme.surface.withOpacity(
                    0.5,
                  ),
                  child: ListView.builder(
                    itemCount: 10,
                    itemBuilder:
                        (context, index) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Get.theme.colorScheme.surface,
                          ),
                          title: Container(
                            width: double.infinity,
                            height: 10.0,
                            color: Get.theme.colorScheme.surface,
                          ),
                          subtitle: Container(
                            width: double.infinity,
                            height: 10.0,
                            color: Get.theme.colorScheme.surface,
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
                                decoration: BoxDecoration(
                                  shape: BoxShape.rectangle,
                                  borderRadius: BorderRadius.circular(10),
                                  color: Get.theme.colorScheme.primaryContainer,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.group,
                                    color:
                                        Get
                                            .theme
                                            .colorScheme
                                            .onPrimaryContainer,
                                  ),
                                ),
                              )
                              : CircleAvatar(
                                backgroundColor:
                                    Get.theme.colorScheme.primaryContainer,
                                child: Text(
                                  conversation.conversation_name[0],
                                  style: TextStyle(
                                    color:
                                        Get
                                            .theme
                                            .colorScheme
                                            .onPrimaryContainer,
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
                        conversation.last_message ?? "",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Get.theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('MMMM d , HH:mm').format(
                              conversation.last_message_time?.toLocal() ??
                                  DateTime.now().toLocal(),
                            ),
                            style: TextStyle(
                              color: Get.theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 5),
                          conversation.unread_count != 0
                              ? Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Get.theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    conversation.unread_count.toString(),
                                    style: TextStyle(
                                      color: Get.theme.colorScheme.onPrimary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                              : SizedBox(),
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
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Get.theme.colorScheme.onPrimary,
            child: Text(
              controller.selectedConversation.value!.conversation_name[0],
              style: TextStyle(
                color: Get.theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 16),
          Text(
            controller.selectedConversation.value!.conversation_name,
            style: TextStyle(
              color: Get.theme.colorScheme.onPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessages extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    return Obx(
      () =>
          controller.isLoadingMessages.value
              ? Center(
                child: CircularProgressIndicator(
                  color: Get.theme.colorScheme.primary,
                ),
              )
              : ListView.builder(
                controller: controller.scrollController,
                reverse: true,
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final isSender = message.sender_id == controller.userId;

                  final showDateHeader =
                      index == controller.messages.length - 1 ||
                      DateTime.parse(message.created_at).toLocal().day !=
                          DateTime.parse(
                            controller.messages[index + 1].created_at,
                          ).toLocal().day;

                  return Column(
                    children: [
                      if (showDateHeader)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            DateFormat('MMMM d, y').format(
                              DateTime.parse(message.created_at).toLocal(),
                            ),
                            style: TextStyle(
                              color: Get.theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      Align(
                        alignment:
                            isSender
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          padding: EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color:
                                isSender
                                    ? Get.theme.colorScheme.primary
                                    : Get.theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: [
                              BoxShadow(
                                color: Get.theme.colorScheme.shadow.withOpacity(
                                  0.1,
                                ),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                    fontSize: 12,
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
                                          ? Get.theme.colorScheme.onPrimary
                                          : Get.theme.colorScheme.onSurface,
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
                                      DateTime.parse(
                                        message.created_at,
                                      ).toLocal(),
                                    ),
                                    style: TextStyle(
                                      color:
                                          isSender
                                              ? Get.theme.colorScheme.onPrimary
                                                  .withOpacity(0.7)
                                              : Get
                                                  .theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                      fontSize: 12,
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
                    ],
                  );
                },
              ),
    );
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
      color: Get.theme.colorScheme.surfaceVariant,
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
                                  DateFormat('MMM d at HH:mm').format(
                                    DateTime.parse(user.read_at).toLocal(),
                                  ),
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
                            color: Get.theme.colorScheme.primary,
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
            Icon(
              Icons.check,
              size: 16,
              color: Get.theme.colorScheme.onPrimary.withOpacity(0.7),
            )
          else if (readCount == 0)
            Icon(Icons.check, size: 16, color: Get.theme.colorScheme.onPrimary)
          else
            Icon(
              Icons.done_all,
              size: 16,
              color: Get.theme.colorScheme.onPrimary,
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
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Get.theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.messageController,
              decoration: InputDecoration(
                hintText: 'type_message'.tr,
                hintStyle: TextStyle(
                  color: Get.theme.colorScheme.onSurfaceVariant,
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
              style: TextStyle(color: Get.theme.colorScheme.onSurfaceVariant),
              cursorColor: Get.theme.colorScheme.primary,
              focusNode: controller.messageFocusNode,
            ),
          ),
          SizedBox(width: 8.0),
          IconButton(
            icon: Icon(Icons.send, color: Get.theme.colorScheme.primary),
            onPressed: () {
              if (controller.messageController.text.isNotEmpty) {
                controller.sendMessage();
                controller.messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
