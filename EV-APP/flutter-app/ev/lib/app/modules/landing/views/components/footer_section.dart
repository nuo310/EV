import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'grid_lines_painter.dart';
import 'package:ev/app/core/theme/app_colors.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 2.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP METRIC DASHBOARD
          const TopMetricDashboardWidget(),

          // Background grid overlay
          CustomPaint(
            painter: const GridLinesPainter(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo block
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.border,
                            width: 2.0,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.border,
                              offset: Offset(3.0, 3.0),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bolt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'ChargeMap',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'High-performance EV charging infrastructure terminal. Real-time telemetry, smart routing, and global connectivity.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ISO Certified Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border, width: 2.0),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.border,
                          offset: Offset(4.0, 4.0),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ISO_15118_CERTIFIED',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text.withAlpha(220),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 2. NAV LINKS ACCORDIONS / LISTS
                  const Text(
                    'COMPLIANCE & LEGAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 14),

              
                  const SizedBox(height: 40),

                  // 3. BOTTOM FOOTNOTE & SOCIAL CHIPS
                  Container(color: const Color(0xFFE2E8F0), height: 1.0),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      const Icon(
                        Icons.terminal_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '© ${DateTime.now().year} ChargeMap Terminal Inc.\nSYNCING_GLOBAL_ACTIVE',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Social Boxes Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['X_SYS', 'IG_HLD', 'LI_CORP', 'GH_DEV'].map((
                      social,
                    ) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          social,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textLight,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

/// Top Metric Dashboard inside Footer
class TopMetricDashboardWidget extends StatefulWidget {
  const TopMetricDashboardWidget({super.key});

  @override
  State<TopMetricDashboardWidget> createState() =>
      _TopMetricDashboardWidgetState();
}

class _TopMetricDashboardWidgetState extends State<TopMetricDashboardWidget> {
  int _latency = 24;
  Timer? _latencyTimer;
  Timer? _clockTimer;
  String _timeString = '';

  @override
  void initState() {
    super.initState();
    _timeString = _formatDateTime(DateTime.now());
    _latencyTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _latency = 18 + Random().nextInt(15);
        });
      }
    });
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeString = _formatDateTime(DateTime.now());
        });
      }
    });
  }

  @override
  void dispose() {
    _latencyTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  String _formatDateTime(DateTime dateTime) {
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String second = dateTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _buildMetricItem('Server Hub', 'US-EAST-GLOBAL'),
            _buildMetricItem(
              'API Latency',
              '${_latency}ms',
              color: _latency > 28 ? AppColors.error : AppColors.primary,
            ),
            _buildMetricItem('Uptime', '99.998%'),
            _buildMetricItem('Version', 'v1.0.42_STABLE'),
            // Clock block
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: AppColors.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _timeString,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value, {
    Color color = AppColors.primary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '[$value]',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
