import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' hide Response;
import 'package:vka_chat_ng/app/constants.dart'; // Для AppConstants и AppKeys
// Используем относительный путь для импорта модели
import '../models/task_model.dart';

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
