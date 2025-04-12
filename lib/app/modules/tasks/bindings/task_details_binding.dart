import 'package:get/get.dart';
import '../controllers/task_details_controller.dart';

class TaskDetailsBinding extends Bindings {
  @override
  void dependencies() {
    // Регистрируем контроллер деталей задачи
    // Не lazy, так как он нужен сразу при открытии
    Get.put<TaskDetailsController>(TaskDetailsController());
    // TaskApiService уже должен быть зарегистрирован
  }
}
