import 'package:get/get.dart';
import '../controllers/task_calendar_controller.dart';

class TaskCalendarBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TaskCalendarController>(() => TaskCalendarController());
  }
}
