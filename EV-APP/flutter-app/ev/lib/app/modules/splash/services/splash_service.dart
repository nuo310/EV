import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';

class SplashService extends GetxService {
  /// Runs initialization checks and returns true if user is already authenticated
  Future<bool> runInitialChecks() async {
    final AuthController authController = Get.find<AuthController>();

    await Future.delayed(const Duration(seconds: 1));
    // Phase 1: Database config
    await Future.delayed(const Duration(seconds: 1));
    // Phase 2: Auth check
    await Future.delayed(const Duration(milliseconds: 800));

    return authController.isAuthenticated.value;
  }
}
