import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ev/app/modules/auth/controllers/auth_controller.dart';
import 'package:ev/app/modules/home/controllers/home_controller.dart';
import 'package:ev/app/modules/home/views/home_view.dart';

void main() {
  testWidgets('HomeView build and render test', (WidgetTester tester) async {
    final authController = Get.put(AuthController());
    final homeController = Get.put(HomeController());

    authController.userName.value = 'John Doe';
    authController.userEmail.value = 'john@example.com';
    authController.isAuthenticated.value = true;

    await tester.pumpWidget(
      GetMaterialApp(
        home: const HomeView(),
      ),
    );
    await tester.pump();

    // 1. Test Dashboard Screen (My Bookings Dashboard)
    homeController.currentMenuIndex.value = 0;
    await tester.pump();

    expect(find.textContaining('My Bookings'), findsOneWidget);
    expect(find.textContaining('Dashboard'), findsNWidgets(2));
    expect(find.text('TOTAL CHARGE'), findsOneWidget);
    expect(find.text('CREDITS SPENT'), findsOneWidget);
    expect(find.text('ACTIVE NOW'), findsOneWidget);
    expect(find.text('COMPLETED'), findsNWidgets(3));

    // Verify recent activity station names and transaction IDs
    expect(find.text('NYC 5th Ave Hub'), findsOneWidget);
    expect(find.text('NJ Turnpike Plaza'), findsOneWidget);
    expect(find.text('TXN_983748291048'), findsOneWidget);

    // Open Drawer to force drawer build
    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();
    await tester.pump();

    // Close Drawer
    state.closeDrawer();
    await tester.pump();

    // 3. Test Find Chargers - Map View Tab
    homeController.currentMenuIndex.value = 1;
    homeController.selectedMapTab.value = 'Map View';
    await tester.pump();

    // 4. Test Find Chargers - Stations Tab
    homeController.selectedMapTab.value = 'Stations';
    await tester.pump();

    // 5. Test Profile Info
    homeController.currentMenuIndex.value = 2;
    await tester.pump();

    // Delete controllers to stop periodic timers and cleanup
    Get.delete<HomeController>();
    Get.delete<AuthController>();
  });
}
