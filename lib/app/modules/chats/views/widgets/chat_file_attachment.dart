import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/data/models/file_model.dart' as file_model;
import 'package:vka_chat_ng/app/modules/chats/controllers/chats_controller.dart';

class ChatFileAttachment extends StatelessWidget {
  final file_model.FileModel file;

  const ChatFileAttachment({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatsController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filePath =
        '${Platform.environment['USERPROFILE']}\\Downloads\\VKA_Chat\\${file.fileName}';
    final localFile = File(filePath);

    final fileExistsNotifier = ValueNotifier<bool>(false);
    localFile.exists().then((exists) => fileExistsNotifier.value = exists);

    return Container(
      margin: EdgeInsets.only(top: 6, bottom: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
        leading: _getFileIcon(file.fileType, colorScheme),
        title: Text(
          file.fileName,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatFileSize(file.fileSize),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Obx(() {
          final isDownloading = controller.downloadingFiles.contains(file.id);
          if (isDownloading) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
            );
          }

          return ValueListenableBuilder<bool>(
            valueListenable: fileExistsNotifier,
            builder: (context, fileExists, child) {
              return IconButton(
                icon: Icon(
                  fileExists
                      ? Icons.open_in_new_rounded
                      : Icons.download_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
                tooltip: fileExists ? 'Открыть файл' : 'Загрузить файл',
                onPressed: () async {
                  if (fileExists) {
                    _openFile(filePath);
                  } else {
                    final downloaded = await controller.downloadFile(file);
                    if (downloaded) {
                      fileExistsNotifier.value = true;
                    }
                  }
                },
              );
            },
          );
        }),
        onTap: () async {
          if (fileExistsNotifier.value) {
            _openFile(filePath);
          } else {
            Get.dialog(
              AlertDialog(
                surfaceTintColor: colorScheme.surfaceContainerHighest,
                title: Text('Загрузка файла'),
                content: Text(
                  'Файл "${file.fileName}" не найден локально. Хотите загрузить его?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Get.back();
                      final downloaded = await controller.downloadFile(file);
                      if (downloaded) {
                        fileExistsNotifier.value = true;
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
    );
  }

  Widget _getFileIcon(String fileType, ColorScheme colorScheme) {
    IconData iconData;
    Color iconColor = colorScheme.primary;

    if (fileType.startsWith('image/')) {
      iconData = Icons.image_outlined;
      iconColor = Colors.deepPurple.shade300;
    } else if (fileType.startsWith('video/')) {
      iconData = Icons.video_file_outlined;
      iconColor = Colors.orange.shade400;
    } else if (fileType.startsWith('audio/')) {
      iconData = Icons.audio_file_outlined;
      iconColor = Colors.lightBlue.shade300;
    } else if (fileType == 'application/pdf') {
      iconData = Icons.picture_as_pdf_outlined;
      iconColor = Colors.red.shade300;
    } else if (fileType.startsWith(
          'application/vnd.openxmlformats-officedocument.wordprocessingml',
        ) ||
        fileType == 'application/msword') {
      iconData = Icons.description_outlined;
      iconColor = Colors.blue.shade300;
    } else if (fileType.startsWith(
          'application/vnd.openxmlformats-officedocument.spreadsheetml',
        ) ||
        fileType == 'application/vnd.ms-excel') {
      iconData = Icons.table_chart_outlined;
      iconColor = Colors.green.shade400;
    } else if (fileType.startsWith(
          'application/vnd.openxmlformats-officedocument.presentationml',
        ) ||
        fileType == 'application/vnd.ms-powerpoint') {
      iconData = Icons.slideshow_outlined;
      iconColor = Colors.amber.shade400;
    } else if (fileType.contains('zip') ||
        fileType.contains('rar') ||
        fileType.contains('7z')) {
      iconData = Icons.archive_outlined;
      iconColor = Colors.brown.shade300;
    } else if (fileType.startsWith('text/')) {
      iconData = Icons.article_outlined;
      iconColor = colorScheme.secondary;
    } else {
      iconData = Icons.attach_file_outlined;
      iconColor = colorScheme.tertiary;
    }
    return Icon(iconData, color: iconColor, size: 28);
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (bytes == 0) ? 0 : (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> _openFile(String filePath) async {
    try {
      final result = await Process.run('cmd', [
        '/c',
        'start',
        '',
        '$filePath',
      ], runInShell: true);
      if (result.exitCode != 0) {
        print('Error opening file: ${result.stderr}');
        Get.snackbar(
          'Ошибка',
          'Не удалось открыть файл. Убедитесь, что приложение для этого типа файлов установлено.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Exception opening file: $e');
      Get.snackbar(
        'Ошибка',
        'Произошла ошибка при попытке открыть файл: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }
}
