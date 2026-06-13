import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ev/app/modules/auth/controllers/auth_controller.dart';
import 'package:ev/main.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    Get.put(AuthController());
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    // Verify that the MaterialApp structure builds
    expect(find.byType(GetMaterialApp), findsOneWidget);
    
    // Resolve pending splash screen timers by pumping the duration
    await tester.pump(const Duration(seconds: 3));
  });
}
