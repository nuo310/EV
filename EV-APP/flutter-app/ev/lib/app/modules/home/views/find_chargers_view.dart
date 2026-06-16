import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ev/app/core/theme/app_colors.dart';
import 'package:ev/app/modules/home/controllers/home_controller.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FindChargersView extends GetView<HomeController> {
  const FindChargersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Content
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sub tabs navigation
              _buildSubTabHeader(
                tabs: ['Map View', 'Stations'],
                activeTabObs: controller.selectedMapTab,
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Obx(() {
                  if (controller.selectedMapTab.value == 'Map View') {
                    return _buildMapViewTab();
                  } else {
                    return _buildStationsListTab();
                  }
                }),
              ),
            ],
          ),
        ),

        // Overlays for Modals
        Obx(() {
          // Configure Charge Modal
          if (controller.kwhInputStationId.value != null) {
            return _buildConfigureChargeModal(context);
          }
          // Receipt Modal
          if (controller.receiptData.value != null) {
            return _buildReceiptModal(context);
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  // ==========================================
  // --- SUB-TAB HEADER
  // ==========================================
  Widget _buildSubTabHeader({
    required List<String> tabs,
    required RxString activeTabObs,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      ),
      child: Row(
        children: tabs.map((tab) {
          return Obx(() {
            final bool isActive = activeTabObs.value == tab;
            return GestureDetector(
              onTap: () => activeTabObs.value = tab,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? AppColors.primary : Colors.transparent,
                      width: 3.0,
                    ),
                  ),
                ),
                child: Text(
                  tab.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isActive ? AppColors.primary : AppColors.textLight,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            );
          });
        }).toList(),
      ),
    );
  }

  // ==========================================
  // --- MAP VIEW TAB
  // ==========================================
  Widget _buildMapViewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scanning Region Banner & Refresh Location Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 2.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() {
                    return _BlinkingDot(
                      color: controller.isFetchingLocation.value ? AppColors.accent : AppColors.primary,
                      size: 10,
                    );
                  }),
                  const SizedBox(width: 8),
                  Obx(() {
                    final lat = controller.userPosition.value.latitude.toStringAsFixed(4);
                    final lng = controller.userPosition.value.longitude.toStringAsFixed(4);
                    return Text(
                      controller.isFetchingLocation.value
                          ? 'GPS: RESOLVING COORDINATES...'
                          : 'GPS LOCK: [$lat, $lng]',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    );
                  }),
                ],
              ),
            ),
            // Location refresh action button
            GestureDetector(
              onTap: () => controller.determinePosition(),
              child: Obx(() {
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 2.0),
                    boxShadow: const [
                      BoxShadow(color: AppColors.border, offset: Offset(2.0, 2.0)),
                    ],
                  ),
                  child: controller.isFetchingLocation.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.border),
                          ),
                        )
                      : const Icon(Icons.my_location_rounded, size: 16, color: AppColors.border),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Interactive Map Graphics Box
        Container(
          height: 380,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 3.5),
            boxShadow: const [
              BoxShadow(color: Color(0x0F000000), offset: Offset(8, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Obx(() {
              var userPos = controller.userPosition.value;
              if (userPos.latitude.isNaN || userPos.longitude.isNaN) {
                userPos = const LatLng(23.0225, 72.5714);
              }
              final allStations = controller.stations;

              return FlutterMap(
                options: MapOptions(
                  initialCenter: userPos,
                  initialZoom: 13.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.gemini.ev',
                  ),
                  MarkerLayer(
                    markers: [
                      // User position marker (Blue)
                      Marker(
                        point: userPos,
                        width: 45,
                        height: 45,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.accent, // Blue
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Stations markers (Green)
                      ...allStations.map((station) {
                        final lat = (station['lat'] as num?)?.toDouble() ?? 0.0;
                        final lng = (station['lng'] as num?)?.toDouble() ?? 0.0;
                        final isAvailable = (station['status'] ?? '').toString().toLowerCase() == 'available';

                        return Marker(
                          point: LatLng(lat, lng),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () {
                              _showStationDetailsSheet(Get.context!, station);
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Marker pin shadow
                                const Positioned(
                                  bottom: 2,
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    size: 32,
                                    color: AppColors.border,
                                  ),
                                ),
                                // Marker pin colored
                                Positioned(
                                  bottom: 4,
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    size: 28,
                                    color: isAvailable ? AppColors.primary : AppColors.warning, // Green or Orange
                                  ),
                                ),
                                // Bolt symbol in center
                                const Positioned(
                                  bottom: 11,
                                  child: Icon(
                                    Icons.bolt_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  void _showStationDetailsSheet(BuildContext context, Map<String, dynamic> station) {
    final String id = station['id'] ?? '';
    final String name = station['name'] ?? 'Unknown';
    final String status = station['status'] ?? 'Available';
    final bool isOnline = station['isOnline'] as bool? ?? false;
    final String chargerType = station['chargerType'] ?? '--';
    final String vendor = station['vendor'] ?? '--';
    final String model = station['model'] ?? '--';
    final int availableSlots = station['availableSlots'] as int? ?? 0;
    final int ratePerKwh = station['ratePerKwh'] as int? ?? 12;
    final String distance = controller.getStationDistance(station);
    final bool isCharging = controller.isStationCharging(id);
    final bool canStart = isOnline && status.toLowerCase() == 'available' && availableSlots > 0 && !isCharging;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.close_rounded, color: AppColors.text),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusBadge(status),
                const SizedBox(width: 8),
                if (distance != '--')
                  Row(
                    children: [
                      const Icon(Icons.navigation_rounded, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        distance,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Hardware: $vendor $model • $chargerType',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            Text(
              'Available Slots: $availableSlots • Rate: \u20b9$ratePerKwh/kWh',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\u20b9$ratePerKwh/kWh',
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                Row(
                  children: [
                    if (!isCharging)
                      _buildActionButton(
                        text: 'Start charging',
                        enabled: canStart,
                        color: AppColors.primary,
                        onTap: () {
                          Get.back();
                          controller.openConfigureCharge(id);
                        },
                      ),
                    if (isCharging)
                      _buildActionButton(
                        text: 'Stop charging',
                        enabled: true,
                        color: AppColors.error,
                        isOutlined: true,
                        onTap: () {
                          Get.back();
                          controller.stopChargingSession(id);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ==========================================
  // --- STATIONS LIST TAB (replaces old _buildStationsTab)
  // ==========================================
  Widget _buildStationsListTab() {
    return Obx(() {
      final sortedStations = controller.sortedStations;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 2.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BlinkingDot(color: AppColors.primary, size: 10),
                const SizedBox(width: 8),
                Text(
                  'LIVE NETWORK STREAM · ${sortedStations.length} HUBS',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Station Cards
          ...sortedStations.map((station) => _buildStationCard(station)),
        ],
      );
    });
  }

  // ==========================================
  // --- STATION CARD (matches React card layout)
  // ==========================================
  Widget _buildStationCard(Map<String, dynamic> station) {
    final String id = station['id'] ?? '';
    final String name = station['name'] ?? 'Unknown';
    final String status = station['status'] ?? 'Available';
    final bool isOnline = station['isOnline'] as bool? ?? false;
    final String chargerType = station['chargerType'] ?? '--';
    final String vendor = station['vendor'] ?? '--';
    final String model = station['model'] ?? '--';
    final int connectorId = station['connectorId'] as int? ?? 1;
    final int availableSlots = station['availableSlots'] as int? ?? 0;
    final String errorCode = station['errorCode'] ?? 'NoError';
    final int ratePerKwh = station['ratePerKwh'] as int? ?? 12;
    final String distance = controller.getStationDistance(station);
    final bool isCharging = controller.isStationCharging(id);

    final bool canStart = isOnline && status.toLowerCase() == 'available' && availableSlots > 0 && !isCharging;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () {
          controller.selectedStationId.value = id;
        },
        child: Obx(() {
          final bool isSelected = controller.selectedStationId.value == id;
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isSelected || isCharging) ? AppColors.primary : const Color(0xFFE2E8F0),
                width: (isSelected || isCharging) ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSelected || isCharging)
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: (isSelected || isCharging) ? 16 : 8,
                  offset: (isSelected || isCharging) ? const Offset(0, 8) : const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Right Badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildBadge(status, const Color(0xFF1D4ED8), const Color(0xFFDBEAFE), const Color(0xFFBFDBFE), dotColor: const Color(0xFF3B82F6)),
                              const SizedBox(width: 8),
                              if (distance != '--')
                                Row(
                                  children: [
                                    const Icon(Icons.navigation_rounded, size: 12, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      distance,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Connector + Online badges
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'CONNECTOR (OCPP)',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildStatusBadge(status),
                            const SizedBox(width: 6),
                            isOnline
                                ? _buildBadge('ONLINE', const Color(0xFF15803D), const Color(0xFFDCFCE7), const Color(0xFF16A34A), dotColor: const Color(0xFF16A34A))
                                : _buildBadge('OFFLINE', const Color(0xFF991B1B), const Color(0xFFFEE2E2), const Color(0xFFDC2626), dotColor: const Color(0xFFEF4444)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Hardware + Diagnostics Grid
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HARDWARE',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$vendor $model',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                            Text(
                              'CID: $connectorId \u2022 $chargerType',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DIAGNOSTICS',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Slots: $availableSlots',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Row(
                              children: [
                                if (errorCode != 'NoError')
                                  const Icon(Icons.error_outline_rounded, size: 10, color: AppColors.error),
                                if (errorCode != 'NoError') const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    errorCode,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: errorCode == 'NoError' ? AppColors.textMuted : AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Divider
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),

                // Price + Actions Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '\u20b9$ratePerKwh',
                              style: const TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '/kWh',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SYNC: ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    // Action Buttons
                    Row(
                      children: [
                        if (!isCharging)
                          _buildActionButton(
                            text: 'Start charging',
                            enabled: canStart,
                            color: AppColors.primary,
                            onTap: canStart
                                ? () => controller.openConfigureCharge(id)
                                : null,
                          ),
                        if (isCharging)
                          _buildActionButton(
                            text: 'Stop charging',
                            enabled: true,
                            color: AppColors.error,
                            isOutlined: true,
                            onTap: () => controller.stopChargingSession(id),
                          ),
                      ],
                    ),
                  ],
                ),

                // Live Active Session UI (if this station is charging)
                if (isCharging)
                  Obx(() {
                    final elapsed = controller.formatElapsed(controller.chargingElapsedSeconds.value);
                    final energy = controller.chargingEnergyKwh.value.toStringAsFixed(2);
                    final cost = controller.chargingCost.value.toStringAsFixed(2);
                    return Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary, width: 2.0),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDCFCE7), Color(0xFFECFDF5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.battery_charging_full_rounded, size: 28, color: Color(0xFF15803D)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'YOUR SESSION \u00b7 LIVE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF15803D),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '\u20b9$cost',
                                      style: const TextStyle(
                                        fontFamily: 'Space Grotesk',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF14532D),
                                      ),
                                    ),
                                    Text(
                                      '$energy kWh',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF166534),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Duration: $elapsed',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        })),
    );
  }

  // ==========================================
  // --- CONFIGURE CHARGE MODAL (Dark themed)
  // ==========================================
  Widget _buildConfigureChargeModal(BuildContext context) {
    final stationId = controller.kwhInputStationId.value!;
    final station = controller.getStationById(stationId);
    if (station == null) return const SizedBox.shrink();

    final int rate = station['ratePerKwh'] as int? ?? 12;
    final String stationName = (station['name'] ?? 'Station').toString().toUpperCase();

    return GestureDetector(
      onTap: () => controller.closeConfigureCharge(),
      child: Container(
        color: const Color(0xA60F172A),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // prevent dismiss on card tap
            child: Container(
              margin: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF1E293B), width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x80000000),
                    blurRadius: 25,
                    offset: Offset(0, 20),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0x1A10B981),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0x3310B981)),
                          ),
                          child: const Icon(Icons.bolt_rounded, size: 22, color: Color(0xFF34D399)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Configure Charge',
                                style: TextStyle(
                                  fontFamily: 'Space Grotesk',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'STATION: $stationName',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => controller.closeConfigureCharge(),
                          child: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Specify the energy required for your vehicle. The system will calculate the reservation tariff and compile your secure invoice.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.5),
                    ),
                    const SizedBox(height: 20),

                    // kWh Label
                    const Text(
                      'TARGET CAPACITY (KILOWATT-HOURS)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // kWh Input + Unit
                    Obx(() {
                      final value = controller.kwhInputValue.value;
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF020617),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF1E293B), width: 2.0),
                                  ),
                                  child: Text(
                                    '$value',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'kWh',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF34D399),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Quick selectors
                          Row(
                            children: [10, 20, 30, 50].map((val) {
                              final isSelected = value == val;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => controller.kwhInputValue.value = val,
                                  child: Container(
                                    margin: EdgeInsets.only(right: val == 50 ? 0 : 8),
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0x1A10B981) : const Color(0xFF020617),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                                        width: 2.0,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$val kWh',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 24),

                    // Calculations Breakdown
                    Obx(() {
                      final value = controller.kwhInputValue.value;
                      final estimatedHours = (value / 7.4 * 10).round() / 10;
                      final subtotal = (value * rate * 100).round() / 100;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF020617),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            _buildCalcRow('Energy tariff', '\u20b9$rate / kWh'),
                            const SizedBox(height: 8),
                            _buildCalcRow('Estimated charge duration', '~$estimatedHours hours (at 7.4 kW)'),
                            const SizedBox(height: 8),
                            Container(height: 1, color: const Color(0xFF1E293B)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tariff Subtotal',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                                Text(
                                  '\u20b9$subtotal',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF34D399)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),

                    // Confirm Button
                    GestureDetector(
                      onTap: () => controller.startChargingSession(stationId),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x4D10B981),
                              blurRadius: 14,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Confirm & Start Charging',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF020617),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // --- RECEIPT / FINAL BILL MODAL
  // ==========================================
  Widget _buildReceiptModal(BuildContext context) {
    final receipt = controller.receiptData.value!;
    final String stationName = receipt['stationName'] ?? 'Station';
    final double energyKwh = (receipt['energyKwh'] as num?)?.toDouble() ?? 0;
    final int ratePerKwh = (receipt['ratePerKwh'] as num?)?.toInt() ?? 12;
    final double billTotal = (receipt['billTotal'] as num?)?.toDouble() ?? 0;
    final int meterStartWh = (receipt['meterStartWh'] as num?)?.toInt() ?? 0;
    final int meterEndWh = (receipt['meterEndWh'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: () => controller.closeReceipt(),
      child: Container(
        color: const Color(0x730F172A),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // prevent dismiss on card tap
            child: Container(
              margin: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 2.0),
                boxShadow: const [
                  BoxShadow(color: AppColors.primary, offset: Offset(8.0, 8.0)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header + Close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Final Bill',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => controller.closeReceipt(),
                        child: const Icon(Icons.close_rounded, size: 22, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stationName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),

                  // Bill Details Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF1F5F9), width: 2.0),
                    ),
                    child: Column(
                      children: [
                        _buildBillRow('Energy consumed', '${energyKwh.toStringAsFixed(2)} kWh'),
                        const SizedBox(height: 10),
                        _buildBillRow('Rate per kWh', '\u20b9$ratePerKwh'),
                        const SizedBox(height: 8),
                        Container(
                          height: 2,
                          color: AppColors.border,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Cost',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              '\u20b9${billTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Meter Reading (Wh): $meterStartWh \u2192 $meterEndWh.',
                          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Close button
                  GestureDetector(
                    onTap: () => controller.closeReceipt(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 2.0),
                      ),
                      child: const Center(
                        child: Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // --- HELPER BUILDERS
  // ==========================================

  Widget _buildActionButton({
    required String text,
    required bool enabled,
    required Color color,
    bool isOutlined = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isOutlined
              ? Colors.white
              : (enabled ? color : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(14),
          border: isOutlined
              ? Border.all(color: color, width: 1.5)
              : Border.all(color: enabled ? color : const Color(0xFFE2E8F0), width: 1.0),
          boxShadow: (enabled && !isOutlined)
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isOutlined
                ? color
                : (enabled ? Colors.white : const Color(0xFF94A3B8)),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final key = status.toLowerCase();
    Color bg, fg, border, dot;
    if (key == 'charging' || key == 'suspendedev') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
      border = const Color(0xFF16A34A);
      dot = const Color(0xFF16A34A);
    } else if (key == 'preparing' || key == 'finishing') {
      bg = const Color(0xFFDBEAFE);
      fg = const Color(0xFF1D4ED8);
      border = const Color(0xFF3B82F6);
      dot = const Color(0xFF3B82F6);
    } else if (key == 'available') {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF334155);
      border = const Color(0xFFCBD5E1);
      dot = const Color(0xFF94A3B8);
    } else {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF991B1B);
      border = const Color(0xFFDC2626);
      dot = const Color(0xFFEF4444);
    }
    return _buildBadge(status.toUpperCase(), fg, bg, border, dotColor: dot);
  }

  Widget _buildBadge(String text, Color fg, Color bg, Color border, {Color? dotColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFF8FAFC))),
      ],
    );
  }

  Widget _buildBillRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text)),
      ],
    );
  }
}

// ==========================================
// --- HELPER PAINTERS & WIDGETS
// ==========================================



class _BlinkingDot extends StatefulWidget {
  final Color color;
  final double size;
  const _BlinkingDot({required this.color, required this.size});

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.15, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
