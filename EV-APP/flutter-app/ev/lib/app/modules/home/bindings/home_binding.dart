import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../services/home_service.dart';
import '../services/admin_socket_service.dart';
import '../controllers/admin_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeService>(
      () => HomeService(),
    );
    Get.lazyPut<HomeController>(
      () => HomeController(),
    );
    Get.lazyPut<AdminSocketService>(
      () => AdminSocketService(),
    );
    Get.lazyPut<AdminController>(
      () => AdminController(),
    );
  }
}

