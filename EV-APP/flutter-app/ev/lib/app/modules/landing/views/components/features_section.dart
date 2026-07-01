import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'grid_lines_painter.dart';
import 'package:ev/app/core/theme/app_colors.dart';
import 'package:ev/app/core/widgets/reusable_widgets.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Tag
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.border, width: 2.0),
                boxShadow: const [
                  BoxShadow(
                color: AppColors.gold,
                offset: Offset(3.0, 3.0),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.memory, color: AppColors.primary, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'HARDWARE & PLATFORM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text.withAlpha(220),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

       
          const SizedBox(height: 48),

          // Bento Card 1: Universal Plug & Charge (Large Stack Card)
          NeoCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.battery_charging_full_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const Text(
                      '[HW_CORE_V2.1]',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Universal Plug & Charge',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Automated vehicle-to-grid handshakes. Secure, instant authentication across all major connector standards.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Blueprint Preview box
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 2.0),
                  ),
                  child: Stack(
                    children: [
                      const CustomPaint(
                        painter: GridLinesPainter(),
                        child: SizedBox.expand(),
                      ),
                      // Blueprint Graphic Painter
                      Center(
                        child: CustomPaint(
                          painter: BlueprintPainter(),
                          child: const SizedBox(width: 120, height: 120),
                        ),
                      ),
                      // Peak limit label
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border, width: 1.5),
                          ),
                          child: const Text(
                            '350kW_PEAK',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Tag Chips Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['AUTOAUTH', 'ISO_15118', 'PLUG_ONLY'].map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Bento Card 2: Live Ingestion (Dark theme widget)
          NeoCard(
            backgroundColor: AppColors.border,
            shadowColor: AppColors.gold.withAlpha(80),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withAlpha(40), width: 2.0),
                      ),
                      child: const Icon(
                        Icons.radio_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const Text(
                      '[DATA_LINK_V3]',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Live Ingestion',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We track charger health from 150+ networks in 5-second intervals. Guaranteed 99.9% terminal uptime.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Oscillating Real-time Bars Widget
                const LiveBarsWidget(),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Bento Card 3: Transparent Pricing (Dark/Gold theme widget)
          NeoCard(
            backgroundColor: AppColors.border,
            borderColor: AppColors.primary,
            shadowColor: AppColors.border,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gold, width: 2.0),
                      ),
                      child: const Icon(
                        Icons.credit_card_rounded,
                        color: AppColors.gold,
                        size: 20,
                      ),
                    ),
                    const Text(
                      '[LEDGER_STRICT]',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Transparent',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Real-time rate forecasting. See exactly what you pay before the cable is plugged.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Mock Billing Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gold, width: 2.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EST. RATE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textLight,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '₹25.00/kWh',
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.gold, width: 1.0),
                        ),
                        child: const Text(
                          '+0.2% AVG',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: AppColors.gold,
                          ),
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

/// Custom Blueprint Connector schematic drawer
class BlueprintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = AppColors.gold.withAlpha(20)
      ..style = PaintingStyle.fill;

    // Draw Connector Body Shield outline
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.25, size.height * 0.35, size.width * 0.5, size.height * 0.5),
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, fillPaint);
    canvas.drawRRect(rect, strokePaint);

    // Draw plug connector nodes (two circles)
    final greenFillPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.40, size.height * 0.45), 6, greenFillPaint);
    canvas.drawCircle(Offset(size.width * 0.60, size.height * 0.45), 6, greenFillPaint);
    canvas.drawCircle(Offset(size.width * 0.40, size.height * 0.45), 6, strokePaint);
    canvas.drawCircle(Offset(size.width * 0.60, size.height * 0.45), 6, strokePaint);

    // Draw top handle connection
    final path = Path()
      ..moveTo(size.width * 0.20, size.height * 0.20)
      ..lineTo(size.width * 0.80, size.height * 0.20)
      ..lineTo(size.width * 0.70, size.height * 0.35)
      ..lineTo(size.width * 0.30, size.height * 0.35)
      ..close();
    canvas.drawPath(path, strokePaint);

    // Draw power cord line
    final cordPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * 0.50, size.height * 0.85), Offset(size.width * 0.50, size.height), cordPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dynamic oscillating bar chart simulation
class LiveBarsWidget extends StatefulWidget {
  const LiveBarsWidget({super.key});

  @override
  State<LiveBarsWidget> createState() => _LiveBarsWidgetState();
}

class _LiveBarsWidgetState extends State<LiveBarsWidget> {
  final List<double> _barHeights = [0.3, 0.6, 0.4, 0.9, 0.5, 0.7, 0.4, 0.8, 1.0, 0.6, 0.4, 0.85];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (mounted) {
        setState(() {
          final random = Random();
          for (int i = 0; i < _barHeights.length; i++) {
            _barHeights[i] = 0.2 + random.nextDouble() * 0.8;
          }
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'STREAM_ACTIVE',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const Text(
                '426ms_LATENCY',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Row of bars
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_barHeights.length, (index) {
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    margin: const EdgeInsets.symmetric(horizontal: 2.0),
                    height: 60 * _barHeights[index],
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          )
        ],
      ),
    );
  }
}
