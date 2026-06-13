import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../services/splash_service.dart';

class SplashController extends GetxController {
  final SplashService _splashService = Get.find<SplashService>();
  final RxString statusText = 'Initializing system...'.obs;

  @override
  void onReady() {
    super.onReady();
    _startInitialChecks();
  }

  Future<void> _startInitialChecks() async {
    statusText.value = 'Initializing system...';

    await Future.delayed(const Duration(seconds: 1));
    statusText.value = 'Configuring local database...';

    await Future.delayed(const Duration(seconds: 1));
    statusText.value = 'Checking authentication status...';

    final bool isAuthenticated = await _splashService.runInitialChecks();

    statusText.value = 'Ready!';

    if (isAuthenticated) {
      Get.offAllNamed(Routes.DASHBOARD);
    } else {
      Get.offAllNamed(Routes.LANDING);
    }
  }
}
