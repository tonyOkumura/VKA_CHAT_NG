import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:vka_chat_ng/app/constants.dart';
import 'package:vka_chat_ng/app/data/models/file_model.dart';
import 'package:slugify/slugify.dart';
import 'package:path/path.dart' as path;

class FileService extends GetxService {
  final _storage = FlutterSecureStorage();
  final _baseUrl = AppConstants.baseUrl;

  Future<File?> findExistingFile(String fileName) async {
    try {
      // Получаем путь к папке Загрузки
      final downloadsPath = '${Platform.environment['USERPROFILE']}\\Downloads';
      final vkaChatPath = '$downloadsPath\\VKA_Chat';
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

      // --- Get original and slugified filename ---
      String originalFileName = path.basename(
        file.path,
      ); // Get filename from path
      List<String> parts = originalFileName.split('.');
      String fileName = parts.sublist(0, parts.length - 1).join('.');
      String safeFileName = slugify(fileName, lowercase: false, delimiter: '_');
      // Ensure extension is preserved if slugify removes it
      if (originalFileName.contains('.') && !safeFileName.contains('.')) {
        final extension = originalFileName.substring(
          originalFileName.lastIndexOf('.'),
        );
        safeFileName += extension;
      }
      print(
        '[FileService.upload] Original filename: $originalFileName -> Slugified: $safeFileName',
      );
      // ------------------------------------------

      // Read file bytes
      print('[FileService.upload] Reading file bytes for: ${file.path}');
      List<int> fileBytes = await file.readAsBytes();
      print('[FileService.upload] File bytes read: ${fileBytes.length}');

      print('Creating multipart request...');
      print('Upload URL: $_baseUrl/files/upload');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/files/upload'),
      );

      // Create MultipartFile using fromBytes with the SLUGIFIED filename
      print('Adding file to request with slugified name: $safeFileName');
      request.files.add(
        http.MultipartFile.fromBytes(
          'file', // Field name expected by server
          fileBytes,
          filename: safeFileName, // Use the slugified filename
          // You might need to specify contentType explicitly if server relies on it
          // contentType: MediaType.parse(lookupMimeType(safeFileName) ?? 'application/octet-stream')
        ),
      );
      print('File added to request');

      // Add message data (unchanged)
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
    print('[FileService.getFileInfo] Getting file info for ID: $fileId');
    try {
      String token = await _storage.read(key: AppKeys.token) ?? '';
      if (token.isEmpty) {
        print('[FileService.getFileInfo] No token found');
        return null;
      }

      final String url = '$_baseUrl/files/info'; // URL without fileId
      final Map<String, String> headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json', // Add Content-Type
      };
      final String body = jsonEncode({'file_id': fileId}); // Create JSON body

      print('[FileService.getFileInfo] Requesting URL (POST): $url');
      print('[FileService.getFileInfo] Request Headers: $headers');
      print('[FileService.getFileInfo] Request Body: $body');

      // Change to http.post
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print(
        '[FileService.getFileInfo] Response Status Code: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('[FileService.getFileInfo] File info received successfully.');
        return FileModel.fromJson(jsonData);
      } else {
        print(
          '[FileService.getFileInfo] Failed to get file info. Status: ${response.statusCode}',
        );
        try {
          print(
            '[FileService.getFileInfo] Error Response Body: ${response.body}',
          );
        } catch (e) {
          print(
            '[FileService.getFileInfo] Could not decode error response body: $e',
          );
        }
        return null;
      }
    } catch (e, stackTrace) {
      print('[FileService.getFileInfo] Error getting file info ID $fileId: $e');
      print('[FileService.getFileInfo] StackTrace: $stackTrace');
      return null;
    }
  }

  Future<File?> downloadFile(String fileId) async {
    print('[FileService.downloadFile] Attempting to download file ID: $fileId');
    try {
      print('[FileService.downloadFile] Getting file info for ID: $fileId');
      final fileInfo = await getFileInfo(fileId);
      if (fileInfo == null) {
        print(
          '[FileService.downloadFile] Failed to get file info for ID: $fileId. Aborting download.',
        );
        return null;
      }
      print(
        '[FileService.downloadFile] Got file info: Name=${fileInfo.fileName}, Size=${fileInfo.fileSize}',
      );

      final downloadsPath = '${Platform.environment['USERPROFILE']}\\Downloads';
      final vkaChatPath = '$downloadsPath\\VKA_Chat';
      final vkaChatDir = Directory(vkaChatPath);
      if (!await vkaChatDir.exists()) {
        await vkaChatDir.create(recursive: true);
        print(
          '[FileService.downloadFile] Created VKA_Chat directory: $vkaChatPath',
        );
      }

      final String token = await _storage.read(key: AppKeys.token) ?? '';
      final Map<String, String> headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      final String body = jsonEncode({'file_id': fileId});

      final String downloadUrl = '$_baseUrl/files/download';

      print('[FileService.downloadFile] Requesting URL (POST): $downloadUrl');
      print('[FileService.downloadFile] Request Headers: $headers');
      print('[FileService.downloadFile] Request Body: $body');

      final response = await http.post(
        Uri.parse(downloadUrl),
        headers: headers,
        body: body,
      );

      print(
        '[FileService.downloadFile] Response Status Code: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        // --- Slugify the filename correctly before saving ---
        String originalFileName = fileInfo.fileName;
        String baseName = path.basenameWithoutExtension(originalFileName);
        String extension = path.extension(
          originalFileName,
        ); // Includes the dot, e.g., '.pdf'

        String slugifiedBaseName = slugify(
          baseName,
          lowercase: false,
          delimiter: '_',
        );

        // Combine slugified base name with the original extension
        String safeFileName = slugifiedBaseName + extension;

        print(
          '[FileService.downloadFile] Original: $originalFileName -> Base: $baseName, Ext: $extension -> Slugified: $safeFileName',
        );
        // -----------------------------------------------

        // Use the safe filename for the path
        final file = File('$vkaChatPath\\$safeFileName');
        await file.writeAsBytes(response.bodyBytes);
        print('[FileService.downloadFile] File saved to: ${file.path}');
        return file;
      } else {
        print(
          '[FileService.downloadFile] Failed to download file. Status: ${response.statusCode}',
        );
        try {
          print(
            '[FileService.downloadFile] Error Response Body: ${response.body}',
          );
        } catch (e) {
          print(
            '[FileService.downloadFile] Could not decode error response body: $e',
          );
        }
        return null;
      }
    } catch (e, stackTrace) {
      print('[FileService.downloadFile] Error downloading file ID $fileId: $e');
      print('[FileService.downloadFile] StackTrace: $stackTrace');
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
        allowMultiple: true,
      );
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }
}
