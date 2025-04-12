import 'package:get/get.dart';
import '../controllers/task_calendar_controller.dart';
import '../controllers/tasks_controller.dart'; // Убедись, что TasksController уже зарегистрирован

class TaskCalendarBinding extends Bindings {
  @override
  void dependencies() {
    // Регистрируем TaskCalendarController
    // Убедись, что TasksController уже зарегистрирован где-то выше (например, в TasksBinding)
    // Если TasksBinding не гарантированно загружен, возможно, придется его здесь найти или загрузить:
    // Get.lazyPut<TasksController>(() => TasksController(), fenix: true); // Пример, если нужно
    Get.lazyPut<TaskCalendarController>(() => TaskCalendarController());
  }
}
