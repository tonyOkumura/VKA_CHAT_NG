import 'dart:io';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:vka_chat_ng/app/constants.dart';
import 'package:vka_chat_ng/app/data/models/file_model.dart';
import 'package:vka_chat_ng/app/data/models/message_model.dart';

class FileService extends GetxService {
  final _storage = FlutterSecureStorage();
  final _baseUrl = AppConstants.baseUrl;

  Future<File?> findExistingFile(String fileName) async {
    try {
      // Получаем путь к папке Загрузки
      final downloadsPath = '${Platform.environment['USERPROFILE']}\\Downloads';
      final vkaChatPath = '$downloadsPath\\VKA Chat';
      final filePath = '$vkaChatPath\\$fileName';

      final file = File(filePath);
      if (await file.exists()) {
        print('File already exists at: $filePath');
        return file;
      }
      return null;
    } catch (e) {
      print('Error checking existing file: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> uploadFileWithMessage({
    required File file,
    required String conversationId,
    required String senderId,
    String content = '',
  }) async {
    try {
      print('=== Starting file upload in FileService ===');
      print('Checking token...');
      String token = await _storage.read(key: AppKeys.token) ?? '';
      if (token.isEmpty) {
        print('No token found');
        return null;
      }
      print('Token found');

      // Проверяем, существует ли файл в папке загрузок
      final existingFile = await findExistingFile(file.path.split('\\').last);
      if (existingFile != null) {
        print('Using existing file from downloads folder');
        file = existingFile;
      }

      print('Creating multipart request...');
      print('Upload URL: $_baseUrl/files/upload');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/files/upload'),
      );

      // Добавляем файл
      print('Adding file to request...');
      print('File path: ${file.path}');
      print('File size: ${await file.length()} bytes');
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      print('File added to request');

      // Добавляем данные сообщения
      print('Adding message data to request...');
      request.fields['conversation_id'] = conversationId;
      request.fields['sender_id'] = senderId;
      request.fields['content'] = content;
      print('Message data added: ${request.fields}');

      request.headers['Authorization'] = 'Bearer $token';
      print('Headers set: ${request.headers}');

      print('Sending request...');
      var response = await request.send();
      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = await response.stream.bytesToString();
        print('Response data received: $responseData');
        final jsonData = jsonDecode(responseData);
        print('JSON decoded successfully');
        return jsonData;
      } else {
        print('Failed to upload file: ${response.statusCode}');
        final responseData = await response.stream.bytesToString();
        print('Error response: $responseData');
        return null;
      }
    } catch (e) {
      print('Error uploading file: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  Future<FileModel?> getFileInfo(String fileId) async {
    try {
      String token = await _storage.read(key: AppKeys.token) ?? '';
      if (token.isEmpty) {
        print('No token found');
        return null;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/files/info/$fileId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return FileModel.fromJson(jsonData);
      } else {
        print('Failed to get file info: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting file info: $e');
      return null;
    }
  }

  Future<File?> downloadFile(String fileId) async {
    try {
      // Сначала получаем информацию о файле
      final fileInfo = await getFileInfo(fileId);
      if (fileInfo == null) {
        print('Failed to get file info');
        return null;
      }

      // Получаем путь к папке Загрузки
      final downloadsPath = '${Platform.environment['USERPROFILE']}\\Downloads';
      final vkaChatPath = '$downloadsPath\\VKA Chat';

      // Создаем папку VKA Chat, если она не существует
      final vkaChatDir = Directory(vkaChatPath);
      if (!await vkaChatDir.exists()) {
        await vkaChatDir.create(recursive: true);
        print('Created VKA Chat directory: $vkaChatPath');
      }

      // Если есть прямой URL для скачивания, используем его
      if (fileInfo.downloadUrl != null) {
        print('Using direct download URL: ${fileInfo.downloadUrl}');
        final response = await http.get(
          Uri.parse(fileInfo.downloadUrl!),
          headers: {
            'Authorization':
                'Bearer ${await _storage.read(key: AppKeys.token) ?? ''}',
          },
        );

        if (response.statusCode == 200) {
          final file = File('$vkaChatPath\\${fileInfo.fileName}');
          await file.writeAsBytes(response.bodyBytes);
          print('File saved to: ${file.path}');
          return file;
        }
      }

      // Если прямого URL нет, пробуем стандартный эндпоинт
      print('Using standard download endpoint');
      final response = await http.get(
        Uri.parse('$_baseUrl/files/download/$fileId'),
        headers: {
          'Authorization':
              'Bearer ${await _storage.read(key: AppKeys.token) ?? ''}',
        },
      );

      print('Download response status: ${response.statusCode}');
      print('Download response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final file = File('$vkaChatPath\\${fileInfo.fileName}');
        await file.writeAsBytes(response.bodyBytes);
        print('File saved to: ${file.path}');
        return file;
      } else {
        print('Failed to download file: ${response.statusCode}');
        print('Error response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error downloading file: $e');
      return null;
    }
  }

  Future<FilePickerResult?> pickFile() async {
    try {
      return await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          // Изображения
          'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tiff', 'svg',
          // Документы
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'txt',
          'csv',
          'rtf',
          // Архивы
          'zip', 'rar', '7z', 'tar', 'gz',
          // Аудио
          'mp3', 'wav', 'ogg', 'midi', 'm4a', 'aac',
          // Видео
          'mp4', 'mpeg', 'mov', 'avi', 'wmv', 'webm',
          // Другие
          'json', 'xml', 'js', 'css', 'html',
        ],
        withData: true,
        allowMultiple: false,
      );
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }
}
