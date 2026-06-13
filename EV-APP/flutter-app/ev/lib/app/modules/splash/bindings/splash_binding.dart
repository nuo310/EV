import 'package:get/get.dart';
import '../controllers/splash_controller.dart';
import '../services/splash_service.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashService>(
      () => SplashService(),
    );
    Get.lazyPut<SplashController>(
      () => SplashController(),
    );
  }
}
