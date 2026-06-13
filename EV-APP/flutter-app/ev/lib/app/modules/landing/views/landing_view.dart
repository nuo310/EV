import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/landing_controller.dart';
import 'package:ev/app/core/theme/app_colors.dart';
import 'package:ev/app/routes/app_pages.dart';

// Import newly created sub-components
import 'components/hero_section.dart';
import 'components/features_section.dart';
import 'components/how_it_works_section.dart';
import 'components/app_preview_section.dart';
import 'components/download_section.dart';
import 'components/footer_section.dart';

class LandingView extends GetView<LandingController> {
  const LandingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text(
              'EV Charge',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Get.toNamed(Routes.LOGIN),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(color: AppColors.border, height: 2.0),
        ),
      ),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            HeroSection(),
            FeaturesSection(),
            HowItWorksSection(),
            AppPreviewSection(),
            DownloadSection(),
            FooterSection(),
          ],
        ),
      ),
    );
  }
}
