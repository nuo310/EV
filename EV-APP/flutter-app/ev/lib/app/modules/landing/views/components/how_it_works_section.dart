import 'package:flutter/material.dart';
import 'package:ev/app/core/theme/app_colors.dart';
import 'package:ev/app/core/widgets/reusable_widgets.dart';

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        'num': '01',
        'title': 'LOCATE',
        'tag': 'SEARCHING...',
        'icon': Icons.satellite_alt_rounded,
        'desc': 'Find the best charging spots near you with real-time availability updates.'
      },
      {
        'num': '02',
        'title': 'SYNC',
        'tag': 'CONNECTING...',
        'icon': Icons.memory,
        'desc': 'Connect your vehicle to any charger instantly with our smart sync technology.'
      },
      {
        'num': '03',
        'title': 'STREAM',
        'tag': 'LIVE_DATA',
        'icon': Icons.equalizer_rounded,
        'desc': 'Track your charging speed and battery level in real-time on your dashboard.'
      },
      {
        'num': '04',
        'title': 'SETTLE',
        'tag': 'DONE',
        'icon': Icons.credit_card_rounded,
        'desc': "Pay automatically when you're finished and get back on the road in seconds."
      }
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Header Tag
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
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
              child: const Text(
                'ENGINEERING THE FUTURE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Main Title
          const Center(
            child: Text(
              'Designed To',
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
          Center(
            child: Text(
              'Work Silently.',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: -0.5,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1.0
                  ..color = AppColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'We removed the noise. The result is a radically minimal infrastructure that runs with technical precision.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 60),

          // Timeline List Structure
          Stack(
            children: [
              // Left track line
              Positioned(
                left: 14,
                top: 20,
                bottom: 20,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.85,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),

              // Timesteps list
              Column(
                children: List.generate(steps.length, (index) {
                  final step = steps[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Timeline indicator with breathing glow
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: TimelineNodeIndicator(num: step['num'] as String),
                        ),
                        const SizedBox(width: 20),

                        // Card Content
                        Expanded(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Wireframe text number in background
                              Positioned(
                                top: -25,
                                right: 10,
                                child: Text(
                                  step['num'] as String,
                                  style: TextStyle(
                                    fontFamily: 'Space Grotesk',
                                    fontSize: 90,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -2,
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 1.5
                                      ..color = AppColors.border.withAlpha(20),
                                  ),
                                ),
                              ),

                              // Main Card Widget
                              NeoCard(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Step Tag
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Text(
                                        '[${step['tag']}]',
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.gold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Custom icon
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.border,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        step['icon'] as IconData,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Title
                                    Text(
                                      step['title'] as String,
                                      style: const TextStyle(
                                        fontFamily: 'Space Grotesk',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // Description
                                    Text(
                                      step['desc'] as String,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMuted,
                                        height: 1.4,
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
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Breathing timeline dot widget
class TimelineNodeIndicator extends StatefulWidget {
  final String num;
  const TimelineNodeIndicator({super.key, required this.num});

  @override
  State<TimelineNodeIndicator> createState() => _TimelineNodeIndicatorState();
}

class _TimelineNodeIndicatorState extends State<TimelineNodeIndicator> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 1.0, end: 1.6).animate(_controller!);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Breathing Ring
          AnimatedBuilder(
            animation: _animation!,
            builder: (context, child) {
              return Transform.scale(
                scale: _animation!.value,
                child: Opacity(
                  opacity: ((1.6 - _animation!.value) / 0.6).clamp(0.0, 1.0),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
          // Inner Solid Circle
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 3.5),
            ),
          ),
        ],
      ),
    );
  }
}
