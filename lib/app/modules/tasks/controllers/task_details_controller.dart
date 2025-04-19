import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/data/models/task_model.dart';
import 'package:vka_chat_ng/app/data/services/task_api_service.dart';
import 'package:vka_chat_ng/app/data/models/comment_model.dart';
import 'package:vka_chat_ng/app/data/models/log_entry_model.dart';
import 'package:vka_chat_ng/app/data/models/file_model.dart';
import 'package:vka_chat_ng/app/services/file_service.dart';
import 'dart:io';
import 'package:vka_chat_ng/app/services/socket_service.dart';

class TaskDetailsController extends GetxController {
  final TaskApiService _apiService = Get.find<TaskApiService>();
  final FileService _fileService = Get.find<FileService>();
  final SocketService _socketService = Get.find<SocketService>();

  // ID задачи, полученный из аргументов (делаем nullable)
  String? taskId;

  // Состояние
  final Rxn<TaskModel> task = Rxn<TaskModel>(); // Nullable TaskModel
  final RxBool isLoading = true.obs; // Начинаем с загрузки
  final RxnString errorMessage = RxnString();

  // --- НОВОЕ: Состояние для комментариев ---
  final RxList<CommentModel> comments = <CommentModel>[].obs;
  final RxBool isLoadingComments = false.obs;
  final RxnString commentsErrorMessage = RxnString();
  final TextEditingController commentInputController = TextEditingController();
  final RxString commentText = ''.obs;
  final RxBool isSubmittingComment = false.obs;
  // ----------------------------------------

  // --- НОВОЕ: Состояние для логов ---
  final RxList<LogEntryModel> logs = <LogEntryModel>[].obs;
  final RxBool isLoadingLogs = false.obs;
  final RxnString logsErrorMessage = RxnString();
  // -----------------------------------

  // --- НОВОЕ: Состояние для вложений ---
  final RxList<FileModel> attachments = <FileModel>[].obs;
  final RxBool isLoadingAttachments = false.obs;
  final RxnString attachmentsErrorMessage = RxnString();
  final RxBool isUploadingAttachment = false.obs;
  // -------------------------------------

  // --- Добавляем опции приоритета для отображения ---
  final Map<int, String> priorityOptions = {
    1: 'Высокий',
    2: 'Средний',
    3: 'Низкий',
  };
  // ----------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is String) {
      taskId = Get.arguments as String;
      // Используем taskId! где он точно не null
      fetchTaskDetails();
      fetchComments();
      fetchLogs();
      fetchAttachments();
      _socketService.joinTaskRoom(taskId!);

      commentInputController.addListener(() {
        commentText.value = commentInputController.text;
      });
    } else {
      // Обработка ошибки: ID задачи не передан
      print(
        "Error: Task ID not provided in arguments for TaskDetailsController.",
      );
      errorMessage.value = "Ошибка: ID задачи не был передан.";
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    commentInputController.dispose();
    // Проверяем taskId на null
    if (taskId != null) {
      _socketService.leaveTaskRoom(taskId!);
    }
    super.onClose();
  }

  // Загрузка деталей задачи
  Future<void> fetchTaskDetails() async {
    if (taskId == null) return; // Доп. проверка
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final taskDetails = await _apiService.getTaskById(
        taskId!,
      ); // Используем taskId!
      task.value = taskDetails;
    } catch (e) {
      print("Error fetching task details for $taskId: $e");
      errorMessage.value =
          "Не удалось загрузить детали задачи: ${e.toString()}";
      task.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  // --- НОВЫЕ МЕТОДЫ: Загрузка и отправка комментариев ---
  Future<void> fetchComments() async {
    if (taskId == null) return;
    isLoadingComments.value = true;
    commentsErrorMessage.value = null;
    try {
      final fetchedComments = await _apiService.getComments(
        taskId!,
      ); // Используем taskId!
      comments.assignAll(fetchedComments);
    } catch (e) {
      print("Error fetching comments for task $taskId: $e");
      commentsErrorMessage.value =
          "Не удалось загрузить комментарии: ${e.toString()}";
    } finally {
      isLoadingComments.value = false;
    }
  }

  Future<void> submitComment() async {
    if (taskId == null) return;
    final currentCommentText = commentText.value.trim();
    if (currentCommentText.isEmpty) return;

    isSubmittingComment.value = true;
    commentsErrorMessage.value = null;

    try {
      final newComment = await _apiService.addComment(
        taskId!, // Используем taskId!
        currentCommentText,
      );
      commentInputController.clear();
    } catch (e) {
      print("Error submitting comment for task $taskId: $e");
      Get.snackbar(
        'Ошибка',
        'Не удалось отправить комментарий: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSubmittingComment.value = false;
    }
  }
  // -----------------------------------------------------

  // --- НОВОЕ: Метод для загрузки логов ---
  Future<void> fetchLogs() async {
    if (taskId == null) return;
    isLoadingLogs.value = true;
    logsErrorMessage.value = null;
    try {
      final fetchedLogs = await _apiService.getLogs(
        taskId!,
      ); // Используем taskId!
      logs.assignAll(fetchedLogs);
    } catch (e) {
      print("Error fetching logs for task $taskId: $e");
      logsErrorMessage.value = "Не удалось загрузить историю: ${e.toString()}";
    } finally {
      isLoadingLogs.value = false;
    }
  }
  // --------------------------------------

  // --- НОВЫЕ МЕТОДЫ: Работа с вложениями ---

  Future<void> fetchAttachments() async {
    if (taskId == null) return;
    isLoadingAttachments.value = true;
    attachmentsErrorMessage.value = null;
    try {
      final fetchedAttachments = await _apiService.getAttachments(
        taskId!,
      ); // Используем taskId!
      attachments.assignAll(fetchedAttachments);
    } catch (e) {
      print("Error fetching attachments for task $taskId: $e");
      attachmentsErrorMessage.value =
          "Не удалось загрузить вложения: ${e.toString()}";
    } finally {
      isLoadingAttachments.value = false;
    }
  }

  Future<void> pickAndUploadAttachment() async {
    if (taskId == null) return;
    final pickedResult = await _fileService.pickFile();
    if (pickedResult != null && pickedResult.files.single.path != null) {
      final file = File(pickedResult.files.single.path!);
      isUploadingAttachment.value = true;
      attachmentsErrorMessage.value = null;
      try {
        final newAttachment = await _apiService.addAttachment(
          taskId!,
          file,
        ); // Используем taskId!
        Get.snackbar(
          'Успех',
          'Файл "${newAttachment.fileName}" успешно загружен.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        print("Error uploading attachment for task $taskId: $e");
        Get.snackbar(
          'Ошибка',
          'Не удалось загрузить файл: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        attachmentsErrorMessage.value = "Ошибка загрузки файла.";
      } finally {
        isUploadingAttachment.value = false;
      }
    } else {
      print("File picking cancelled or failed.");
    }
  }

  Future<void> downloadAttachment(String fileId, String fileName) async {
    Get.showSnackbar(
      GetSnackBar(
        message: 'Загрузка "$fileName"...',
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
      ),
    );
    try {
      final downloadedFile = await _fileService.downloadFile(fileId);
      if (downloadedFile != null) {
        Get.snackbar(
          'Успех',
          'Файл "$fileName" сохранен в Загрузки/VKA_Chat.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      } else {
        throw Exception('Download function returned null');
      }
    } catch (e) {
      print("Error downloading attachment $fileId: $e");
      Get.snackbar(
        'Ошибка',
        'Не удалось скачать файл "$fileName": ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteAttachment(String attachmentId, String fileName) async {
    if (taskId == null) return;
    Get.dialog(
      AlertDialog(
        title: const Text('Удалить вложение?'),
        content: Text('Вы уверены, что хотите удалить файл "$fileName"?'),
        actions: [
          TextButton(child: const Text('Отмена'), onPressed: () => Get.back()),
          TextButton(
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Get.back();
              Get.dialog(
                Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
              );
              try {
                await _apiService.deleteAttachment(
                  taskId!,
                  attachmentId,
                ); // Используем taskId!
                Get.back();
                Get.snackbar(
                  'Успех',
                  'Вложение "$fileName" удалено.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.back();
                print("Error deleting attachment $attachmentId: $e");
                Get.snackbar(
                  'Ошибка',
                  'Не удалось удалить вложение: ${e.toString()}',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Color getUserColor(String userId) {
    // Генерируем цвет на основе ID пользователя
    final hash = userId.hashCode;
    final hue = (hash % 360).abs();
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.7, 0.5).toColor();
  }

  void handleTaskUpdated(dynamic data) {
    print("[WebSocket TaskDetails] Received taskUpdated: $data");
    try {
      final updatedTaskId = data['id'] as String?;
      if (updatedTaskId == taskId) {
        final updatedTask = TaskModel.fromJson(data as Map<String, dynamic>);
        task.value = updatedTask;
        print("  Task details updated via WebSocket.");
      }
    } catch (e) {
      print("Error processing taskUpdated event in TaskDetails: $e");
    }
  }

  void handleNewTaskComment(dynamic data) {
    print("[WebSocket TaskDetails] Received newTaskComment: $data");
    try {
      final commentTaskId = data['task_id'] as String?;
      if (commentTaskId == taskId) {
        final newComment = CommentModel.fromJson(data as Map<String, dynamic>);
        // Добавляем комментарий, если его еще нет
        if (!comments.any((c) => c.id == newComment.id)) {
          comments.insert(0, newComment);
          print("  New comment added via WebSocket.");
        }
      }
    } catch (e) {
      print("Error processing newTaskComment event in TaskDetails: $e");
    }
  }

  void handleNewTaskAttachment(dynamic data) {
    print("[WebSocket TaskDetails] Received newTaskAttachment: $data");
    try {
      final attachmentTaskId = data['task_id'] as String?;
      if (attachmentTaskId == taskId) {
        final newAttachment = FileModel.fromJson(data as Map<String, dynamic>);
        // Добавляем вложение, если его еще нет
        if (!attachments.any((a) => a.id == newAttachment.id)) {
          attachments.add(newAttachment);
          print("  New attachment added via WebSocket.");
        }
      }
    } catch (e) {
      print("Error processing newTaskAttachment event in TaskDetails: $e");
    }
  }

  void handleTaskAttachmentDeleted(dynamic data) {
    print("[WebSocket TaskDetails] Received taskAttachmentDeleted: $data");
    try {
      final eventTaskId = data['taskId'] as String?;
      final attachmentId = data['attachmentId'] as String?;
      if (eventTaskId == taskId && attachmentId != null) {
        // Просто удаляем, без проверки возвращаемого значения
        attachments.removeWhere((att) => att.id == attachmentId);
        print("  Attachment $attachmentId removed via WebSocket (if existed).");
      }
    } catch (e) {
      print("Error processing taskAttachmentDeleted event in TaskDetails: $e");
    }
  }

  void handleNewLogEntry(dynamic data) {
    print("[WebSocket TaskDetails] Received newLogEntry: $data");
    try {
      final logTaskId = data['task_id'] as String?;
      if (logTaskId == taskId) {
        final newLog = LogEntryModel.fromJson(data as Map<String, dynamic>);
        // Используем logId для проверки уникальности
        if (!logs.any((l) => l.logId == newLog.logId)) {
          logs.insert(0, newLog); // Вставляем в начало
          print("  New log entry added via WebSocket.");
        }
      }
    } catch (e) {
      print("Error processing newLogEntry event in TaskDetails: $e");
    }
  }
}
