import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ev/app/core/theme/app_colors.dart';
import 'package:ev/app/core/widgets/reusable_widgets.dart';
import 'package:ev/app/modules/home/controllers/home_controller.dart';

class DashboardView extends GetView<HomeController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TELEMETRY LIVE indicator with pulsing dot animation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.border, width: 2.0),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PulsingDot(),
                  SizedBox(width: 8),
                  Text(
                    'TELEMETRY LIVE',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'My Bookings',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    height: 1.0,
                  ),
                ),
                Text(
                  'Dashboard',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    height: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Row of 4 stats cards (2x2 Grid)
            Obx(() {
              final tripsCount = controller.bookings.length;
              final spent = controller.totalSpent;
              final activeCount = controller.activeBookingsCount;
              final completedCount = controller.completedBookingsCount;

              return Column(
                children: [
                  Row(
                    children: [
                      _buildStatCard(
                        icon: Icons.trending_up_rounded,
                        label: 'Total Trips',
                        value: tripsCount.toString(),
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        icon: Icons.bolt_rounded,
                        label: 'Credits Spent',
                        value: '\u20b9$spent',
                        accent: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(
                        icon: Icons.radio_button_checked_rounded,
                        label: 'Active Now',
                        value: activeCount.toString(),
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        icon: Icons.memory_rounded,
                        label: 'Completed',
                        value: completedCount.toString(),
                      ),
                    ],
                  ),
                ],
              );
            }),
            const SizedBox(height: 32),

            // Recent Activity Container Card
            NeoCard(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                      Obx(() {
                        final count = controller.bookings.length;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: AppColors.border, width: 2.0),
                          ),
                          child: Text(
                            '$count RECORDS',
                            style: const TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 2.0,
                    color: const Color(0xFFF1F5F9),
                  ),
                  const SizedBox(height: 20),

                  // Bookings List or Empty State
                  Obx(() {
                    if (controller.bookings.isEmpty) {
                      return _buildEmptyState();
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.bookings.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final booking = controller.bookings[index];
                        return _buildBookingCard(booking, index);
                      },
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildTerminalConsole(),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalConsole() {
    final firebaseApp = Firebase.app();
    final projectId = firebaseApp.options.projectId;
    final User? user = FirebaseAuth.instance.currentUser;

    return NeoCard(
      backgroundColor: const Color(0xFF0F172A),
      shadowColor: AppColors.primary.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal_rounded, color: Color(0xFF4ADE80), size: 18),
              const SizedBox(width: 8),
              const Text(
                'SYSTEM TELEMETRY CONSOLE',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4ADE80),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF4ADE80),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConsoleMetaRow('PROJECT_ID', projectId),
                const SizedBox(height: 4),
                _buildConsoleMetaRow('USER_UID', user?.uid ?? 'NULL'),
                const SizedBox(height: 4),
                _buildConsoleMetaRow('USER_EMAIL', user?.email ?? 'NULL'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'CONSOLE OUTPUT:',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 180,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Obx(() {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: controller.logs.length,
                itemBuilder: (context, index) {
                  final log = controller.logs[index];
                  Color logColor = const Color(0xFFF1F5F9);
                  if (log.contains('[ERROR]')) {
                    logColor = const Color(0xFFF87171);
                  } else if (log.contains('[WARNING]')) {
                    logColor = const Color(0xFFFBBF24);
                  } else if (log.contains('[SYSTEM]')) {
                    logColor = const Color(0xFF60A5FA);
                  } else if (log.contains('[DEBUG]')) {
                    logColor = const Color(0xFFC084FC);
                  } else if (log.contains('[API]')) {
                    logColor = const Color(0xFF2DD4BF);
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      log,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: logColor,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleMetaRow(String key, String val) {
    return Row(
      children: [
        Text(
          '$key: ',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF38BDF8),
          ),
        ),
        Expanded(
          child: Text(
            val,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF1F5F9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    bool accent = false,
  }) {
    return Expanded(
      child: NeoCard(
        backgroundColor: accent ? AppColors.border : Colors.white,
        shadowColor: accent ? AppColors.primary.withValues(alpha: 0.25) : AppColors.border.withValues(alpha: 0.08),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent ? AppColors.primary : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accent ? AppColors.primary : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: accent ? Colors.white : AppColors.text,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: accent ? const Color(0xFF94A3B8) : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: accent ? Colors.white : AppColors.text,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, int index) {
    final String status = booking['status'] ?? 'Pending';
    final String stationName = booking['stationName'] ?? 'Unknown Station';
    final int amount = booking['amount'] ?? 0;
    final String id = booking['id'] ?? '';
    final DateTime createdAt = booking['createdAt'] ?? DateTime.now();

    Color statusColor;
    Color statusBg;
    switch (status.toLowerCase()) {
      case 'active':
      case 'completed':
      case 'confirmed':
        statusColor = const Color(0xFF16A34A);
        statusBg = const Color(0xFFF0FDF4);
        break;
      case 'pending':
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFFFBEB);
        break;
      case 'cancelled':
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEF2F2);
        break;
      default:
        statusColor = const Color(0xFF64748B);
        statusBg = const Color(0xFFF8FAFC);
    }

    final String dateStr = _formatDateTime(createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            offset: Offset(4.0, 4.0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stationName,
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\u20b9$amount',
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1.0,
            color: const Color(0xFFF1F5F9),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TXN ID',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    id.length > 16 ? id.substring(0, 16) : id,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: statusColor, width: 1.5),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFCBD5E1),
              width: 2.0,
            ),
          ),
          child: const Icon(
            Icons.eco_rounded,
            color: Color(0xFFCBD5E1),
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No Bookings Found',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Head to Find Chargers to book an EV charging slot',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 20),
        NeoButton(
          text: 'Find Charging Hubs',
          icon: Icons.arrow_forward_rounded,
          onPressed: () {
            controller.currentMenuIndex.value = 1;
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hourVal = dt.hour;
    final ampm = hourVal >= 12 ? 'PM' : 'AM';
    final displayHour = hourVal % 12 == 0 ? 12 : hourVal % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, ${displayHour.toString().padLeft(2, '0')}:$minute $ampm';
  }
}

// ==========================================
// --- HELPER WIDGET: PULSING DOT
// ==========================================
class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
