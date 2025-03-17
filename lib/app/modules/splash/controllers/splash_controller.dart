import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:vka_chat_ng/app/routes/app_pages.dart';
import 'package:vka_chat_ng/app/services/socket_service.dart';

class SplashController extends GetxController {
  final _storage = FlutterSecureStorage();

  @override
  void onInit() {
    super.onInit();
    Future.delayed(const Duration(seconds: 2), () async {
      final token = await _storage.read(key: 'token');
      if (token != null) {
        if (!Get.isRegistered<SocketService>()) {
          await Get.putAsync(() => SocketService().init());
        }
        Get.offAllNamed(Routes.CHATS);
      } else {
        Get.offAllNamed(Routes.LOGIN);
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }
}
