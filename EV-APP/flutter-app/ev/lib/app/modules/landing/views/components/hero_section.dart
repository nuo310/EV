import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'grid_lines_painter.dart';
import 'package:ev/app/core/theme/app_colors.dart';
import 'package:ev/app/core/widgets/reusable_widgets.dart';
import 'package:ev/app/routes/app_pages.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const GridLinesPainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 2.0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Ring Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.border, width: 2.0),
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
                  const SizedBox(width: 8),
                  const Text(
                    'TERMINAL READY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Header Title with Typewriter Animation
            const Text(
              'Built To',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
                height: 1.0,
                letterSpacing: -1.0,
              ),
            ),
            const TypewriterText(
              words: ['Charge.', 'Sync.', 'Route.', 'Connect.'],
            ),
            const SizedBox(height: 24),

            // Description
            const Text(
              'The most advanced EV charging infrastructure terminal. Real-time telemetry, smart routing, and global connectivity.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),

            // Hero CTA Buttons
            // Row(
            //   children: [
            //     Expanded(
            //       child: NeoButton(
            //         text: 'Get Started',
            //         onPressed: () => Get.toNamed(Routes.SIGNUP),
            //       ),
            //     ),
            //     const SizedBox(width: 14),
            //     Expanded(
            //       child: GestureDetector(
            //         onTap: () => Get.toNamed(Routes.LOGIN),
            //         child: Container(
            //           padding: const EdgeInsets.symmetric(vertical: 16),
            //           decoration: BoxDecoration(
            //             color: Colors.transparent,
            //             borderRadius: BorderRadius.circular(12),
            //             border: Border.all(color: AppColors.border, width: 2.0),
            //           ),
            //           child: const Center(
            //             child: Text(
            //               'Watch System',
            //               style: TextStyle(
            //                 color: AppColors.text,
            //                 fontWeight: FontWeight.w900,
            //                 fontSize: 16,
            //               ),
            //             ),
            //           ),
            //         ),
            //       ),
            //     ),
            //   ],
            // ),

            // Search Hub Widget
            const SearchHubWidget(),
            const SizedBox(height: 52),

            // Phone Mockup & Telemetry Stack
            Center(
              child: SizedBox(
                width: 320,
                height: 560,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Mock Phone Shell
                    const PhoneShellWidget(),
                    // Floating Telemetry Overlay Card (Offset to left)
                    Positioned(
                      left: -20,
                      top: 40,
                      child: Container(
                        width: 180,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(235),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border, width: 2.0),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.border,
                              offset: Offset(4.0, 4.0),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                  'TELEMETRY',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.text,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const TelemetryRow(label: 'Network Load', value: '94%', percent: 0.94),
                            const SizedBox(height: 10),
                            const TelemetryRow(label: 'Data Flow', value: '12GB/s', percent: 0.60),
                          ],
                        ),
                      ),
                    ),
                    // Floating Node Indicator Badge (Offset to right-bottom)
                    Positioned(
                      right: -10,
                      bottom: 80,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border, width: 2.0),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.border,
                              offset: Offset(4.0, 4.0),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.public, color: AppColors.primary, size: 16),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CONNECTED TO',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textMuted.withAlpha(200),
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'SYD_NORTH_HUB',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.text,
                                  ),
                                ),
                              ],
                            )
                          ],
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
    );
  }
}

/// Typewriter Text Animation Widget
class TypewriterText extends StatefulWidget {
  final List<String> words;
  const TypewriterText({super.key, required this.words});

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  int _wordIndex = 0;
  String _currentText = '';
  bool _isDeleting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTypewriter();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTypewriter() {
    _timer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      final String fullWord = widget.words[_wordIndex];

      if (_isDeleting) {
        if (_currentText.isNotEmpty) {
          setState(() {
            _currentText = fullWord.substring(0, _currentText.length - 1);
          });
        } else {
          setState(() {
            _isDeleting = false;
            _wordIndex = (_wordIndex + 1) % widget.words.length;
          });
        }
      } else {
        if (_currentText.length < fullWord.length) {
          setState(() {
            _currentText = fullWord.substring(0, _currentText.length + 1);
          });
        } else {
          // Pause before deleting
          _timer?.cancel();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _isDeleting = true;
              _startTypewriter();
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _currentText,
      style: const TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: 52,
        fontWeight: FontWeight.w900,
        color: AppColors.primary,
        height: 1.0,
        letterSpacing: -1.0,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.primary,
        decorationThickness: 2.0,
      ),
    );
  }
}

/// Search Hub Widget inside HeroSection
class SearchHubWidget extends StatelessWidget {
  const SearchHubWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: AppColors.border,
            offset: Offset(4.0, 4.0),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: const Icon(Icons.gps_fixed_rounded, color: AppColors.text, size: 18),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SMART ROUTING',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textLight,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Scanning for hubs...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.toNamed(Routes.LOGIN),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.border,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
            child: const Text('Find Hubs'),
          ),
        ],
      ),
    );
  }
}

/// Phone shell graphic mockup
class PhoneShellWidget extends StatelessWidget {
  const PhoneShellWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(44),
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
        borderRadius: BorderRadius.circular(36),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Top Mockup Map Area
              Expanded(
                flex: 3,
                child: Container(
                  color: const Color(0xFFF8FAFC),
                  child: Stack(
                    children: [
                      const CustomPaint(
                        painter: GridLinesPainter(),
                        child: SizedBox.expand(),
                      ),
                      // Mock Line Path SVG represented as CustomPaint
                      CustomPaint(
                        painter: PathMockPainter(),
                        child: const SizedBox.expand(),
                      ),
                      // User Indicator Dot (Blue)
                      Positioned(
                        left: 40,
                        bottom: 40,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.0),
                            boxShadow: [
                              BoxShadow(color: Colors.blueAccent.withAlpha(100), blurRadius: 8, spreadRadius: 2),
                            ],
                          ),
                        ),
                      ),
                      // Station indicator (Green)
                      Positioned(
                        right: 40,
                        top: 60,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3.0),
                            boxShadow: [
                              BoxShadow(color: AppColors.primary.withAlpha(150), blurRadius: 12, spreadRadius: 4),
                            ],
                          ),
                          child: const Icon(Icons.bolt, color: Colors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Separator line
              Container(color: AppColors.border, height: 2.0),
              // Bottom Mock Card Detail Area
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'EV Fast Hub',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '1.2 mi away • Open Now',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => Get.toNamed(Routes.LOGIN),
                          icon: const Icon(Icons.navigation_rounded, size: 16),
                          label: const Text('GO'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.border,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    );
  }
}

/// Simulated Map Path Drawing inside PhoneShell
class PathMockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(48, size.height - 48)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.7, size.width - 52, 72);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Telemetry Row with Progress Anim inside HeroSection
class TelemetryRow extends StatelessWidget {
  final String label;
  final String value;
  final double percent;

  const TelemetryRow({
    super.key,
    required this.label,
    required this.value,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percent,
              child: Container(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
