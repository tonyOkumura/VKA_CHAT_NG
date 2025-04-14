import 'package:get/get.dart';
import 'package:vka_chat_ng/app/data/services/task_api_service.dart';

import '../controllers/tasks_controller.dart';

class TasksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TaskApiService>(() => TaskApiService());
    Get.put<TasksController>(TasksController());
  }
}
