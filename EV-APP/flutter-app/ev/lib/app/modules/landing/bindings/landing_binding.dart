import 'package:get/get.dart';
import '../controllers/landing_controller.dart';
import '../services/landing_service.dart';

class LandingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LandingService>(
      () => LandingService(),
    );
    Get.lazyPut<LandingController>(
      () => LandingController(),
    );
  }
}
