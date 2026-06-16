import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ev/app/core/theme/app_colors.dart';
import 'package:ev/app/core/widgets/reusable_widgets.dart';

class AppPreviewSection extends StatelessWidget {
  const AppPreviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Tag
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
                    offset: Offset(4.0, 4.0),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.show_chart_rounded, color: AppColors.primary, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE APP PREVIEW',
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

          // Title
          const Center(
            child: Text(
              'Total control.',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const Center(
            child: Text(
              'Bespoke telemetry.',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 60),

          // Mockup Phone Shell displaying Charging Dashboard
          Center(
            child: Container(
              width: 320,
              height: 620,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(48),
                border: Border.all(color: AppColors.border, width: 8.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    offset: Offset(16.0, 16.0),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Top statistics black banner
                      Container(
                        width: double.infinity,
                        height: 140,
                        color: AppColors.border,
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'CURRENT FLOW',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textLight.withAlpha(200),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Icon(Icons.online_prediction, color: AppColors.primary, size: 14),
                              ],
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: const TextSpan(
                                text: '120',
                                style: TextStyle(
                                  fontFamily: 'Space Grotesk',
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'kW/s',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'NJ Transit Hub // Port A4',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textLight.withAlpha(180),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Rest of mockup screen with circular fluid wave battery
                      Expanded(
                        child: Container(
                          color: const Color(0xFFF8FAFC),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Spacer(),
                              const LiquidBatteryWidget(level: 82),
                              const Spacer(),
                              
                              // Stats details grid row
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.border, width: 1.5),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x0F000000),
                                            offset: Offset(2.0, 2.0),
                                            blurRadius: 0,
                                          )
                                        ],
                                      ),
                                      child: const Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'TIME LEFT',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '14m',
                                            style: TextStyle(
                                              fontFamily: 'Space Grotesk',
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.text,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.border,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.border, width: 1.5),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: AppColors.primary,
                                            offset: Offset(2.0, 2.0),
                                            blurRadius: 0,
                                          )
                                        ],
                                      ),
                                      child: const Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'SECURE',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.textLight,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Active',
                                            style: TextStyle(
                                              fontFamily: 'Space Grotesk',
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Mock stop session button
                              Container(
                                width: double.infinity,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border, width: 2.0),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppColors.border,
                                      offset: Offset(4.0, 4.0),
                                      blurRadius: 0,
                                    )
                                  ]
                                ),
                                child: const Center(
                                  child: Text(
                                    'STOP SESSION',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: AppColors.text,
                                      letterSpacing: 0.5,
                                    ),
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
            ),
          ),
          const SizedBox(height: 48),

          // Floating Navigation Widget representation (horizontal stacks for mobile pages)
          NeoCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.near_me_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NAVIGATION',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textMuted,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'NJ Hub Alpha',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  '0.4 mi away',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Floating Green environmental impact widget card
          NeoCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL IMPACT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Carbon Offset',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Progress track line
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Container(
                          height: 4,
                          width: 120,
                          color: const Color(0xFFE2E8F0),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.64,
                            child: Container(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.gold, width: 1.0),
                  ),
                  child: const Text(
                    '+12.4kg',
                    style: TextStyle(
                      fontSize: 10,
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
    );
  }
}

/// Liquid Battery wave animation widget
class LiquidBatteryWidget extends StatefulWidget {
  final int level;
  const LiquidBatteryWidget({super.key, required this.level});

  @override
  State<LiquidBatteryWidget> createState() => _LiquidBatteryWidgetState();
}

class _LiquidBatteryWidgetState extends State<LiquidBatteryWidget> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 3.5),
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Wave background layer custom painter
            AnimatedBuilder(
              animation: _controller!,
              builder: (context, child) {
                return CustomPaint(
                  painter: LiquidWavePainter(
                    percent: widget.level / 100,
                    waveProgress: _controller!.value,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),

            // Text readout layer
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.level}%',
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'CHARGING',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Wave height and sine factor calculation custom painter
class LiquidWavePainter extends CustomPainter {
  final double percent;
  final double waveProgress;

  LiquidWavePainter({required this.percent, required this.waveProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withAlpha(45)
      ..style = PaintingStyle.fill;

    final path = Path();
    final double fillHeight = size.height * (1.0 - percent);
    
    // Wave sine parameters
    final double waveHeight = 6.0; // Height amplitude
    final double waveFrequency = 2 * pi / size.width;

    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final double y = fillHeight + sin((x * waveFrequency) + (waveProgress * 2 * pi)) * waveHeight;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Overlay second sine wave shifted by 180 deg for depth
    final paintAlt = Paint()
      ..color = AppColors.gold.withAlpha(35)
      ..style = PaintingStyle.fill;

    final pathAlt = Path();
    pathAlt.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final double y = fillHeight + sin((x * waveFrequency) - (waveProgress * 2 * pi) + pi) * waveHeight;
      pathAlt.lineTo(x, y);
    }
    pathAlt.lineTo(size.width, size.height);
    pathAlt.close();

    canvas.drawPath(pathAlt, paintAlt);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
