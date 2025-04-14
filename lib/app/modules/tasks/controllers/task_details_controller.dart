import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/data/models/task_model.dart';
import 'package:vka_chat_ng/app/data/services/task_api_service.dart';

class TaskDetailsController extends GetxController {
  final TaskApiService _apiService = Get.find<TaskApiService>();

  // ID задачи, полученный из аргументов
  late final String taskId;

  // Состояние
  final Rxn<TaskModel> task = Rxn<TaskModel>(); // Nullable TaskModel
  final RxBool isLoading = true.obs; // Начинаем с загрузки
  final RxnString errorMessage = RxnString();

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
      // TODO: Запустить загрузку комментариев/вложений/логов
      // fetchComments();
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
    super.onClose();
  }
}
