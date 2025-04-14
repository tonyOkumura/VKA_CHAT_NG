import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:vka_chat_ng/app/constants.dart'; // Для AppConstants и AppKeys
// Используем относительный путь для импорта модели
import '../models/task_model.dart';
import '../models/comment_model.dart';
import '../models/log_entry_model.dart';
import 'dart:io'; // <-- Add import for File
import '../models/file_model.dart'; // <-- Add import for FileModel

class TaskApiService extends GetxService {
  final _storage = const FlutterSecureStorage();
  late final Dio _dio;
  // Базовый URL для эндпоинтов задач (например, "/tasks")
  // Полный URL будет `${AppConstants.baseUrl}/tasks`
  final String _tasksEndpointPath = "/tasks";

  @override
  void onInit() {
    super.onInit();
    final options = BaseOptions(
      baseUrl:
          AppConstants
              .baseUrl, // Устанавливаем базовый URL для всех запросов Dio
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    _dio = Dio(options);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppKeys.token);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print(
              'Token added to request: Bearer ${token.substring(0, 10)}...',
            ); // Логгируем часть токена
          } else {
            print('No token found for request to ${options.path}');
          }
          print(
            'Sending ${options.method} request to: ${options.baseUrl}${options.path}',
          );
          print('Query params: ${options.queryParameters}');
          // print('Request data: ${options.data}'); // Раскомментируй для отладки тела запроса
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            'Received response: ${response.statusCode} from ${response.requestOptions.path}',
          );
          // print('Response data: ${response.data}'); // Раскомментируй для отладки ответа
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print("Dio Error on ${e.requestOptions.path}: ${e.message}");
          print("Dio Error Response Status: ${e.response?.statusCode}");
          print("Dio Error Response Data: ${e.response?.data}");
          if (e.response?.statusCode == 401) {
            print("Unauthorized access - Token might be invalid or expired.");
            // Можно добавить логику выхода или обновления токена
            // Get.offAllNamed(Routes.LOGIN);
          }
          return handler.next(e);
        },
      ),
    );
  }

  // --- Методы API ---

  Future<List<TaskModel>> getTasks({String? status, String? search}) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (status != null && status.isNotEmpty)
        queryParameters['status'] = status;
      if (search != null && search.isNotEmpty)
        queryParameters['search'] = search;

      final response = await _dio.get(
        _tasksEndpointPath,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map(
              (taskJson) =>
                  TaskModel.fromJson(taskJson as Map<String, dynamic>),
            )
            .toList();
      } else {
        print(
          "Failed to load tasks: Status ${response.statusCode}, Data: ${response.data}",
        );
        throw Exception(
          'Failed to load tasks: Invalid response format or status code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print(
        "Error fetching tasks: ${e.response?.statusCode} - ${e.response?.data ?? e.message}",
      );
      throw _handleDioError(e, 'fetch tasks');
    } catch (e) {
      print("Unexpected error fetching tasks: $e");
      throw Exception('An unexpected error occurred while fetching tasks.');
    }
  }

  Future<TaskModel> createTask(Map<String, dynamic> taskData) async {
    try {
      print(
        "[TaskApiService] Creating task with data: $taskData",
      ); // Лог для отладки
      final response = await _dio.post(_tasksEndpointPath, data: taskData);
      if (response.statusCode == 201 && response.data != null) {
        return TaskModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        print(
          "Failed to create task: Status ${response.statusCode}, Data: ${response.data}",
        );
        throw Exception(
          'Failed to create task: Invalid response or status code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print(
        "Error creating task: ${e.response?.statusCode} - ${e.response?.data ?? e.message}",
      );
      throw _handleDioError(e, 'create task');
    } catch (e) {
      print("Unexpected error creating task: $e");
      throw Exception('An unexpected error occurred while creating the task.');
    }
  }

  Future<TaskModel> getTaskById(String taskId) async {
    try {
      final response = await _dio.get('$_tasksEndpointPath/$taskId');
      if (response.statusCode == 200 && response.data != null) {
        return TaskModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        print(
          "Failed to load task $taskId: Status ${response.statusCode}, Data: ${response.data}",
        );
        throw Exception(
          'Failed to load task details: Invalid response or status code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print(
        "Error fetching task $taskId: ${e.response?.statusCode} - ${e.response?.data ?? e.message}",
      );
      throw _handleDioError(e, 'fetch task details');
    } catch (e) {
      print("Unexpected error fetching task $taskId: $e");
      throw Exception(
        'An unexpected error occurred while fetching task details.',
      );
    }
  }

  Future<TaskModel> updateTask(
    String taskId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      print(
        "[TaskApiService] Updating task $taskId with data: $updateData",
      ); // Лог для отладки
      final response = await _dio.put(
        '$_tasksEndpointPath/$taskId',
        data: updateData,
      );
      if (response.statusCode == 200 && response.data != null) {
        return TaskModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        print(
          "Failed to update task $taskId: Status ${response.statusCode}, Data: ${response.data}",
        );
        throw Exception(
          'Failed to update task: Invalid response or status code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print(
        "Error updating task $taskId: ${e.response?.statusCode} - ${e.response?.data ?? e.message}",
      );
      throw _handleDioError(e, 'update task');
    } catch (e) {
      print("Unexpected error updating task $taskId: $e");
      throw Exception('An unexpected error occurred while updating the task.');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final response = await _dio.delete('$_tasksEndpointPath/$taskId');
      if (response.statusCode != 204) {
        print(
          "Failed to delete task $taskId: Status ${response.statusCode}, Data: ${response.data}",
        );
        throw Exception(
          'Failed to delete task: Status code ${response.statusCode}',
        );
      }
      // Success (204 No Content)
    } on DioException catch (e) {
      print(
        "Error deleting task $taskId: ${e.response?.statusCode} - ${e.response?.data ?? e.message}",
      );
      throw _handleDioError(e, 'delete task');
    } catch (e) {
      print("Unexpected error deleting task $taskId: $e");
      throw Exception('An unexpected error occurred while deleting the task.');
    }
  }

  // --- КОММЕНТАРИИ ---

  Future<List<CommentModel>> getComments(String taskId) async {
    try {
      final response = await _dio.get('$_tasksEndpointPath/$taskId/comments');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map(
              (commentJson) =>
                  CommentModel.fromJson(commentJson as Map<String, dynamic>),
            )
            .toList();
      } else {
        print(
          "Failed to load comments for task $taskId: Status ${response.statusCode}, Data: ${response.data}",
        );
        throw Exception(
          'Failed to load comments: Invalid response or status code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print(
        "Error fetching comments for task $taskId: ${e.response?.statusCode} - ${e.response?.data ?? e.message}",
      );
      throw _handleDioError(e, 'fetch comments');
    } catch (e) {
      print("Unexpected error fetching comments for task $taskId: $e");
      throw Exception('An unexpected error occurred while fetching comments.');
    }
  }

  Future<CommentModel> addComment(String taskId, String commentText) async {
    if (commentText.trim().isEmpty) {
      throw ArgumentError('Comment text cannot be empty.');
    }
    try {
      final response = await _dio.post(
        '$_tasksEndpointPath/$taskId/comments',
        data: {'comment': commentText.trim()},
      );
      if (response.statusCode == 201 && response.data != null) {
        return CommentModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        print(
          "Failed to add comment to task $taskId: Status ${response.statusCode}, Data: ${response.data}",
        );
        throw Exception(
          'Failed to add comment: Invalid response or status code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print(
        "Error adding comment to task $taskId: ${e.response?.statusCode} - ${e.response?.data ?? e.message}",
      );
      throw _handleDioError(e, 'add comment');
    } catch (e) {
      print("Unexpected error adding comment to task $taskId: $e");
      throw Exception('An unexpected error occurred while adding the comment.');
    }
  }

  // ---------------------

  // --- ЛОГИ ИЗМЕНЕНИЙ ---
  Future<List<LogEntryModel>> getLogs(String taskId) async {
    try {
      final response = await _dio.get('$_tasksEndpointPath/$taskId/logs');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map(
              (logJson) =>
                  LogEntryModel.fromJson(logJson as Map<String, dynamic>),
            )
            .toList();
      } else {
        print(
          "Failed to load logs for task $taskId: Status ${response.statusCode}, Data: ${response.data}",
        );
        throw Exception(
          'Failed to load logs: Invalid response or status code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print(
        "Error fetching logs for task $taskId: ${e.response?.statusCode} - ${e.response?.data ?? e.message}",
      );
      throw _handleDioError(e, 'fetch logs');
    } catch (e) {
      print("Unexpected error fetching logs for task $taskId: $e");
      throw Exception('An unexpected error occurred while fetching logs.');
    }
  }
  // ----------------------

  // --- ВЛОЖЕНИЯ ---

  Future<List<FileModel>> getAttachments(String taskId) async {
    try {
      final response = await _dio.get(
        '$_tasksEndpointPath/$taskId/attachments',
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map(
              (fileJson) =>
                  FileModel.fromJson(fileJson as Map<String, dynamic>),
            )
            .toList();
      } else {
        print(
          "Failed to load attachments for task $taskId: Status ${response.statusCode}, Data: ${response.data}",
        );
        throw Exception(
          'Failed to load attachments: Invalid response or status code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print(
        "Error fetching attachments for task $taskId: ${e.response?.statusCode} - ${e.response?.data ?? e.message}",
      );
      throw _handleDioError(e, 'fetch attachments');
    } catch (e) {
      print("Unexpected error fetching attachments for task $taskId: $e");
      throw Exception(
        'An unexpected error occurred while fetching attachments.',
      );
    }
  }

  Future<FileModel> addAttachment(String taskId, File file) async {
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      print(
        "[TaskApiService] Uploading attachment '$fileName' for task $taskId...",
      );
      final response = await _dio.post(
        '$_tasksEndpointPath/$taskId/attachments',
        data: formData,
        options: Options(
          headers: {
            // Dio может автоматически установить Content-Type для FormData,
            // но можно и явно указать, если нужно
            // 'Content-Type': 'multipart/form-data',
          },
        ),
        onSendProgress: (int sent, int total) {
          print(
            'Upload progress: ${(sent / total * 100).toStringAsFixed(0)}% ($sent/$total bytes)',
          );
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        print("[TaskApiService] Attachment uploaded successfully.");
        return FileModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        print(
          "Failed to add attachment to task $taskId: Status ${response.statusCode}, Data: ${response.data}",
        );
        throw Exception(
          'Failed to add attachment: Invalid response or status code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print(
        "Error adding attachment to task $taskId: ${e.response?.statusCode} - ${e.response?.data ?? e.message}",
      );
      throw _handleDioError(e, 'add attachment');
    } catch (e) {
      print("Unexpected error adding attachment to task $taskId: $e");
      throw Exception(
        'An unexpected error occurred while adding the attachment.',
      );
    }
  }

  Future<void> deleteAttachment(String taskId, String attachmentId) async {
    try {
      final response = await _dio.delete(
        '$_tasksEndpointPath/$taskId/attachments/$attachmentId',
      );
      if (response.statusCode != 204) {
        print(
          "Failed to delete attachment $attachmentId for task $taskId: Status ${response.statusCode}, Data: ${response.data}",
        );
        throw Exception(
          'Failed to delete attachment: Status code ${response.statusCode}',
        );
      }
      print("[TaskApiService] Attachment $attachmentId deleted successfully.");
      // Success (204 No Content)
    } on DioException catch (e) {
      print(
        "Error deleting attachment $attachmentId for task $taskId: ${e.response?.statusCode} - ${e.response?.data ?? e.message}",
      );
      throw _handleDioError(e, 'delete attachment');
    } catch (e) {
      print(
        "Unexpected error deleting attachment $attachmentId for task $taskId: $e",
      );
      throw Exception(
        'An unexpected error occurred while deleting the attachment.',
      );
    }
  }

  // -------------------

  // Вспомогательный метод для обработки ошибок Dio
  Exception _handleDioError(DioException e, String operation) {
    if (e.response != null) {
      // Ошибка с ответом от сервера
      final statusCode = e.response!.statusCode;
      final responseData = e.response!.data;
      String message = 'Failed to $operation (Status $statusCode)';
      if (responseData is Map && responseData.containsKey('message')) {
        message += ': ${responseData['message']}';
      } else if (responseData != null) {
        message += ': ${responseData.toString()}';
      }

      if (statusCode == 404)
        return Exception('Resource not found during $operation.');
      if (statusCode == 403)
        return Exception('Permission denied during $operation.');
      if (statusCode == 401)
        return Exception('Authentication failed during $operation.');
      if (statusCode == 400)
        return Exception(
          'Bad request during $operation: ${responseData?.toString() ?? 'Invalid data'}',
        );

      return Exception(message);
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      // Ошибка таймаута
      return Exception('Network timeout during $operation.');
    } else if (e.type == DioExceptionType.cancel) {
      return Exception('Request cancelled during $operation.');
    } else {
      // Другие ошибки (нет соединения и т.д.)
      return Exception('Network error during $operation: ${e.message}');
    }
  }

  // TODO: Реализовать методы для комментариев, вложений, логов по аналогии
  // Future<List<CommentModel>> getComments(String taskId) async { ... }
  // Future<CommentModel> addComment(String taskId, Map<String, dynamic> commentData) async { ... }
  // Future<List<AttachmentModel>> getAttachments(String taskId) async { ... }
  // Future<AttachmentModel> addAttachment(String taskId, FormData formData) async { ... } // Нужен FormData для файла
  // Future<List<LogModel>> getLogs(String taskId) async { ... }
}
