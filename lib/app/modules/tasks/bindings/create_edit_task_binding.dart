import 'package:get/get.dart';
import '../controllers/create_edit_task_controller.dart';

class CreateEditTaskBinding extends Bindings {
  @override
  void dependencies() {
    // Регистрируем контроллер для страницы создания/редактирования
    // Не используем lazyPut, так как контроллер нужен сразу при открытии страницы
    Get.put<CreateEditTaskController>(CreateEditTaskController());
    // TasksController и TaskApiService уже должны быть зарегистрированы TasksBinding
  }
}
