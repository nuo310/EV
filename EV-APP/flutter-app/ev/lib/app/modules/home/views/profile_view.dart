import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ev/app/core/theme/app_colors.dart';
import 'package:ev/app/core/widgets/reusable_widgets.dart';
import 'package:ev/app/modules/auth/controllers/auth_controller.dart';
import 'package:ev/app/modules/home/controllers/home_controller.dart';

class ProfileView extends GetView<HomeController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final TextEditingController targetKwhController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Details Card
          NeoCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.badge_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Account Details',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Obx(() => _buildProfileDetailRow('Full Name', authController.userName.value)),
                const Divider(color: Color(0xFFE2E8F0), height: 20),
                Obx(() => _buildProfileDetailRow('Email ID', authController.userEmail.value)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Charge Limit Control Card
          const Text(
            'CHARGING PROFILE SETTINGS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),

          NeoCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeoTextField(
                  label: 'Target Limit (kWh)',
                  hintText: 'Enter target charging limit (e.g. 45)',
                  controller: targetKwhController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.electric_car_rounded,
                ),
                const SizedBox(height: 20),
                NeoButton(
                  text: 'UPDATE TARGET LIMIT',
                  onPressed: () {
                    final String val = targetKwhController.text.trim();
                    if (val.isNotEmpty) {
                      Get.snackbar(
                        'Target Updated',
                        'Set target charging limit to $val kWh successfully.',
                        backgroundColor: Colors.white,
                        colorText: AppColors.text,
                        borderColor: AppColors.border,
                        borderWidth: 2,
                        borderRadius: 14,
                        snackPosition: SnackPosition.BOTTOM,
                        margin: const EdgeInsets.all(16),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Recharger Card
          const Text(
            'WALLET BALANCES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),

          NeoCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'WALLET BALANCE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textMuted),
                    ),
                    Obx(
                      () => Text(
                        '\u20b9${controller.walletBalance.value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                NeoButton(
                  text: 'RECHARGE WALLET (\u20b950.00)',
                  backgroundColor: AppColors.accent,
                  icon: Icons.wallet_rounded,
                  onPressed: () => controller.addCredits(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textLight, letterSpacing: 0.5),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text),
          ),
        ),
      ],
    );
  }
}
