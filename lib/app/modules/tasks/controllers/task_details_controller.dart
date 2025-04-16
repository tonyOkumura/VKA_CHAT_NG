import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/data/models/task_model.dart';
import 'package:vka_chat_ng/app/data/services/task_api_service.dart';
import 'package:vka_chat_ng/app/data/models/comment_model.dart';
import 'package:vka_chat_ng/app/data/models/log_entry_model.dart';
import 'package:vka_chat_ng/app/data/models/file_model.dart';
import 'package:vka_chat_ng/app/services/file_service.dart';
import 'dart:io';

class TaskDetailsController extends GetxController {
  final TaskApiService _apiService = Get.find<TaskApiService>();
  final FileService _fileService = Get.find<FileService>();

  // ID задачи, полученный из аргументов
  late final String taskId;

  // Состояние
  final Rxn<TaskModel> task = Rxn<TaskModel>(); // Nullable TaskModel
  final RxBool isLoading = true.obs; // Начинаем с загрузки
  final RxnString errorMessage = RxnString();

  // --- НОВОЕ: Состояние для комментариев ---
  final RxList<CommentModel> comments = <CommentModel>[].obs;
  final RxBool isLoadingComments = false.obs;
  final RxnString commentsErrorMessage = RxnString();
  final TextEditingController commentInputController = TextEditingController();
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

  // TODO: Добавить RxList для комментариев, вложений, логов
  // final RxList<CommentModel> comments = <CommentModel>[].obs;
  // final RxList<AttachmentModel> attachments = <AttachmentModel>[].obs;
  // final RxList<LogModel> logs = <LogModel>[].obs;
  // final RxBool isLoadingComments = false.obs; // и т.д. для других разделов

  @override
  void onInit() {
    super.onInit();
    // Получаем ID задачи из аргументов навигации
    if (Get.arguments != null && Get.arguments is String) {
      taskId = Get.arguments as String;
      fetchTaskDetails();
      // --- НОВОЕ: Загружаем комментарии при инициализации ---
      fetchComments();
      fetchLogs();
      // --- НОВОЕ: Загружаем вложения при инициализации ---
      fetchAttachments();
      // ----------------------------------------------------
    } else {
      // Обработка ошибки: ID задачи не передан
      print(
        "Error: Task ID not provided in arguments for TaskDetailsController.",
      );
      errorMessage.value = "Ошибка: ID задачи не был передан.";
      isLoading.value = false;
      // Можно автоматически закрыть экран
      // Future.delayed(Duration(seconds: 1), () => Get.back());
    }
  }

  // Загрузка деталей задачи
  Future<void> fetchTaskDetails() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final taskDetails = await _apiService.getTaskById(taskId);
      task.value = taskDetails;
    } catch (e) {
      print("Error fetching task details for $taskId: $e");
      errorMessage.value =
          "Не удалось загрузить детали задачи: ${e.toString()}";
      task.value = null; // Очищаем задачу в случае ошибки
    } finally {
      isLoading.value = false;
    }
  }

  // --- НОВЫЕ МЕТОДЫ: Загрузка и отправка комментариев ---
  Future<void> fetchComments() async {
    isLoadingComments.value = true;
    commentsErrorMessage.value = null;
    try {
      final fetchedComments = await _apiService.getComments(taskId);
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
    final commentText = commentInputController.text.trim();
    if (commentText.isEmpty) return;

    isSubmittingComment.value = true;
    commentsErrorMessage.value = null; // Сбрасываем предыдущую ошибку

    try {
      final newComment = await _apiService.addComment(taskId, commentText);
      comments.insert(0, newComment); // Добавляем новый коммент в начало списка
      commentInputController.clear(); // Очищаем поле ввода
    } catch (e) {
      print("Error submitting comment for task $taskId: $e");
      // Отображаем ошибку рядом с полем ввода или через SnackBar
      Get.snackbar(
        'Ошибка',
        'Не удалось отправить комментарий: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      // Можно также установить commentsErrorMessage.value
    } finally {
      isSubmittingComment.value = false;
    }
  }
  // -----------------------------------------------------

  // --- НОВОЕ: Метод для загрузки логов ---
  Future<void> fetchLogs() async {
    isLoadingLogs.value = true;
    logsErrorMessage.value = null;
    try {
      final fetchedLogs = await _apiService.getLogs(taskId);
      // API возвращает в порядке убывания, сохраняем так же
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
    isLoadingAttachments.value = true;
    attachmentsErrorMessage.value = null;
    try {
      final fetchedAttachments = await _apiService.getAttachments(taskId);
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
    final pickedResult = await _fileService.pickFile();
    if (pickedResult != null && pickedResult.files.single.path != null) {
      final file = File(pickedResult.files.single.path!);
      isUploadingAttachment.value = true;
      attachmentsErrorMessage.value = null; // Сбрасываем предыдущую ошибку
      try {
        final newAttachment = await _apiService.addAttachment(taskId, file);
        attachments.add(newAttachment); // Добавляем в конец списка
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
      // Пользователь отменил выбор файла или произошла ошибка
    }
  }

  Future<void> downloadAttachment(String fileId, String fileName) async {
    // Показываем SnackBar о начале загрузки
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
        throw Exception(
          'Download function returned null',
        ); // Генерируем исключение для catch
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
    // Показываем диалог подтверждения
    Get.dialog(
      AlertDialog(
        title: const Text('Удалить вложение?'),
        content: Text(
          'Вы уверены, что хотите удалить файл "$fileName"? Это действие необратимо.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Отмена')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Get.back(); // Закрываем диалог
              _performDeleteAttachment(
                attachmentId,
                fileName,
              ); // Вызываем фактическое удаление
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  // Приватный метод для фактического выполнения удаления после подтверждения
  Future<void> _performDeleteAttachment(
    String attachmentId,
    String fileName,
  ) async {
    // Можно показать индикатор на конкретном элементе или глобальный
    // attachments.firstWhereOrNull((att) => att.id == attachmentId)?.isLoadingDelete = true; // Пример
    attachmentsErrorMessage.value = null;
    try {
      await _apiService.deleteAttachment(taskId, attachmentId);
      attachments.removeWhere((att) => att.id == attachmentId);
      Get.snackbar(
        'Успех',
        'Файл "$fileName" удален.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print("Error deleting attachment $attachmentId: $e");
      Get.snackbar(
        'Ошибка',
        'Не удалось удалить файл "$fileName": ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      attachmentsErrorMessage.value = "Ошибка удаления файла.";
    } finally {
      // Снять индикатор, если используется
      // attachments.firstWhereOrNull((att) => att.id == attachmentId)?.isLoadingDelete = false;
    }
  }

  Color getUserColor(String userId) {
    // Генерируем цвет на основе ID пользователя
    final hash = userId.hashCode;
    final hue = (hash % 360).abs();
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.7, 0.5).toColor();
  }

  @override
  void onClose() {
    task.close();
    isLoading.close();
    errorMessage.close();
    // --- НОВОЕ: Закрываем ресурсы комментариев ---
    comments.close();
    isLoadingComments.close();
    commentsErrorMessage.close();
    commentInputController.dispose();
    isSubmittingComment.close();
    // ------------------------------------------
    // --- НОВОЕ: Закрываем ресурсы логов ---
    logs.close();
    isLoadingLogs.close();
    logsErrorMessage.close();
    // -------------------------------------
    // --- НОВОЕ: Закрываем ресурсы вложений ---
    attachments.close();
    isLoadingAttachments.close();
    attachmentsErrorMessage.close();
    isUploadingAttachment.close();
    // ----------------------------------------
    super.onClose();
  }
}
