import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/splash_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/reusable_widgets.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Card
              NeoCard(
                backgroundColor: AppColors.primary,
                borderRadius: 24,
                padding: const EdgeInsets.all(24),
                child: const Icon(
                  Icons.bolt_rounded,
                  size: 72,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 36),
              // App Title
              const Text(
                'ChargeMap Mobile',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              const Text(
                'Next-Gen EV Telemetry Client',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 48),
              // Loading status block
              NeoCard(
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                backgroundColor: Colors.white,
                shadowOffset: 4.0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Obx(
                      () => Text(
                        controller.statusText.value,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
