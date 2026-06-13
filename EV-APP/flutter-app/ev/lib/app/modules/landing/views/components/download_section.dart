import 'dart:async';
import 'package:flutter/material.dart';
import 'grid_lines_painter.dart';
import 'package:ev/app/core/theme/app_colors.dart';

class DownloadSection extends StatelessWidget {
  const DownloadSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.border, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.primary,
                  offset: Offset(4.0, 4.0),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Text(
              'TERMINAL AVAILABLE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'System Terminal',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const Text(
            'In Your Pocket.',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Connect instantly, monitor precisely, and pay without friction. The entire infrastructure is localized for your mobile experience.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 36),

          

          // Real-time active users counter widget
          const LiveDriverCounterWidget(),
          const SizedBox(height: 48),

          // Core phone released representation container card
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border, width: 2.0),
            ),
            child: Stack(
              children: [
                const Opacity(
                  opacity: 0.15,
                  child: CustomPaint(
                    painter: GridLinesPainter(),
                    child: SizedBox.expand(),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 2.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(4, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bolt,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ChargeMap Terminal',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'v1.0.42 STABLE_RELEASE',
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
          ),
        ],
      ),
    );
  }
}

/// Live incrementing active driver count ticker
class LiveDriverCounterWidget extends StatefulWidget {
  const LiveDriverCounterWidget({super.key});

  @override
  State<LiveDriverCounterWidget> createState() =>
      _LiveDriverCounterWidgetState();
}

class _LiveDriverCounterWidgetState extends State<LiveDriverCounterWidget> {
  int _count = 52431;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _count += (1 + (timer.tick % 3));
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${_count.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ACTIVE_DRIVERS',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
