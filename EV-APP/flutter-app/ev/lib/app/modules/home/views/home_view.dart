import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ev/app/core/theme/app_colors.dart';
import 'package:ev/app/core/widgets/reusable_widgets.dart';
import 'package:ev/app/modules/auth/controllers/auth_controller.dart';
import 'package:ev/app/modules/home/controllers/home_controller.dart';
import 'package:ev/app/modules/home/views/dashboard_view.dart';
import 'package:ev/app/modules/home/views/find_chargers_view.dart';
import 'package:ev/app/modules/home/views/profile_view.dart';
import 'package:ev/app/modules/home/views/admin_dashboard_view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    // Map screen index to title
    final List<String> screenTitles = [
      'Dashboard',
      'Find Chargers',
      'Account Profile',
      'Admin Panel',
    ];
  
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.text, size: 28),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Obx(
              () => Text(
                screenTitles[controller.currentMenuIndex.value],
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            color: AppColors.border,
            height: 2.0,
          ),
        ),
      ),
      drawer: _buildDrawer(context, authController),
      body: Obx(() {
        final isAdmin = authController.userRole.value == 'admin';
        final idx = controller.currentMenuIndex.value;

        // Redirect admin away from user-only screens
        if (isAdmin && (idx == 0 || idx == 1)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.currentMenuIndex.value = 3;
          });
          return const AdminDashboardView();
        }

        switch (idx) {
          case 0:
            return const DashboardView();
          case 1:
            return const FindChargersView();
          case 2:
            return const ProfileView();
          case 3:
            return const AdminDashboardView();
          default:
            return const DashboardView();
        }
      }),
    );
  }

  // --- DRAWER (HAMBURGER MENU) BUILDER ---
  Widget _buildDrawer(BuildContext context, AuthController authController) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 2.0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 2.0),
                        boxShadow: const [
                          BoxShadow(color: AppColors.border, offset: Offset(3.0, 3.0)),
                        ],
                      ),
                      child: const Icon(Icons.bolt, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'EV Charge',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Obx(
                  () => Text(
                    authController.userName.value.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Obx(
                  () => Text(
                    authController.userEmail.value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Security Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    '[PRIVILEGE_SUPERADMIN]',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Drawer Menu List Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Dashboard & Find Chargers hidden for admin accounts
                  Obx(() {
                    if (authController.userRole.value == 'admin') {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        _buildDrawerItem(
                          label: 'Dashboard',
                          icon: Icons.trending_up_rounded,
                          index: 0,
                        ),
                        const SizedBox(height: 12),
                        _buildDrawerItem(
                          label: 'Find Chargers',
                          icon: Icons.map_rounded,
                          index: 1,
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }),
                  _buildDrawerItem(
                    label: 'Profile Info',
                    icon: Icons.person_outline_rounded,
                    index: 2,
                  ),
                  Obx(() {
                    if (authController.userRole.value == 'admin') {
                      return Column(
                        children: [
                          const SizedBox(height: 12),
                          _buildDrawerItem(
                            label: 'Admin Panel',
                            icon: Icons.admin_panel_settings_rounded,
                            index: 3,
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  const SizedBox(height: 20),
                  // Separator line
                  Container(color: const Color(0xFFE2E8F0), height: 2.0),
                  const SizedBox(height: 20),
                  
                  // Hardware Simulator Card in Drawer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 2.0),
                      boxShadow: const [
                        BoxShadow(color: AppColors.border, offset: Offset(4.0, 4.0)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.terminal, color: AppColors.primary, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'HARDWARE SIMULATOR',
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Status:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textLight,
                              ),
                            ),
                            Obx(() {
                              final isCharging = controller.activeSessions.value > 0;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCharging ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isCharging ? AppColors.primary : AppColors.textLight,
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  controller.chargerStatus.value.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: isCharging ? AppColors.primary : AppColors.textMuted,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Obx(() {
                          final isCharging = controller.activeSessions.value > 0;
                          return NeoButton(
                            text: isCharging ? 'STOP CHARGE' : 'START CHARGE',
                            backgroundColor: isCharging ? AppColors.error : AppColors.primary,
                            icon: isCharging ? Icons.stop_rounded : Icons.play_arrow_rounded,
                            onPressed: () => controller.toggleCharging(),
                            shadowOffset: 2.0,
                          );
                        }),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  // Separator line
                  Container(color: const Color(0xFFE2E8F0), height: 2.0),
                  const SizedBox(height: 20),
                  // Logout Button
                  GestureDetector(
                    onTap: () {
                      Get.back(); // Close Drawer
                      authController.logout();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error, width: 2.0),
                        boxShadow: const [
                          BoxShadow(color: AppColors.error, offset: Offset(4.0, 4.0)),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                          SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'LOGOUT SESSION',
                              style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Drawer Footer Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.terminal, color: AppColors.textLight, size: 14),
                SizedBox(width: 8),
                Text(
                  'SYNC_SYS_ACTIVE v1.0.4',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required String label,
    required IconData icon,
    required int index,
  }) {
    return Obx(() {
      final bool isActive = controller.currentMenuIndex.value == index;
      return GestureDetector(
        onTap: () {
          controller.currentMenuIndex.value = index;
          Get.back(); // Close Drawer
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            color: isActive ? AppColors.border : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 2.0),
            boxShadow: isActive
                ? []
                : const [
                    BoxShadow(color: AppColors.border, offset: Offset(4.0, 4.0)),
                  ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : AppColors.text,
                size: 20,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    color: isActive ? Colors.white : AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
