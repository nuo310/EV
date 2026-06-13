import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ev/app/core/theme/app_colors.dart';
import 'package:ev/app/core/widgets/reusable_widgets.dart';
import '../controllers/admin_controller.dart';
import 'dashboard_view.dart'; // For PulsingDot

class AdminDashboardView extends GetView<AdminController> {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller inputs
    final connectorIdController = TextEditingController(
      text: controller.connectorIdInput.value.toString(),
    );
    final idTagController = TextEditingController(
      text: controller.idTagInput.value,
    );

    // Sync input fields with controller
    connectorIdController.addListener(() {
      final val = int.tryParse(connectorIdController.text);
      if (val != null) {
        controller.connectorIdInput.value = val;
      }
    });

    idTagController.addListener(() {
      controller.idTagInput.value = idTagController.text;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live websocket status bar ticker
        Obx(() {
          final isConnected = controller.wsConnected.value;
          return MarqueeTicker(
            text: isConnected
                ? '• SYSTEM LIVE • TELEMETRY SOCKET CONNECTED • STREAMING OCPP MESSAGES IN REAL-TIME • SYSTEM STABLE •'
                : '• SYSTEM OFFLINE • TELEMETRY DISCONNECTED • RECONNECTING TO OCPP BACKEND SERVER... •',
            backgroundColor: isConnected
                ? const Color(0xFFDCFCE7)
                : const Color(0xFFFEE2E2),
            textColor: isConnected
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626),
          );
        }),

        // Tab Selector Navigation (Neo-Brutalist horizontal scroll)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Obx(
            () => Row(
              children: [
                _buildTabButton(
                  'overview',
                  Icons.analytics_rounded,
                  'Overview',
                ),
                const SizedBox(width: 12),
                _buildTabButton(
                  'stations',
                  Icons.ev_station_rounded,
                  'Stations',
                ),
                const SizedBox(width: 12),
                _buildTabButton('users', Icons.people_rounded, 'Users'),
                // const SizedBox(width: 12),
                // _buildTabButton(
                //   'commands',
                //   Icons.terminal_rounded,
                //   'OCPP Commands',
                // ),
                // const SizedBox(width: 12),
                // _buildTabButton('logs', Icons.receipt_long_rounded, 'WS Logs'),
              ],
            ),
          ),
        ),

        // Main Tab Contents
        Expanded(
          child: Obx(() {
            switch (controller.activeTab.value) {
              case 'overview':
                return _buildOverviewTab();
              case 'stations':
                return _buildStationsTab();
              case 'users':
                return _buildUsersTab();
              // case 'commands':
              //   return _buildCommandsTab(
              //     connectorIdController,
              //     idTagController,
              //   );
              // case 'logs':
              //   return _buildLogsTab();
              default:
                return _buildOverviewTab();
            }
          }),
        ),
      ],
    );
  }

  // --- TAB SELECTOR BUTTON BUILDER ---
  Widget _buildTabButton(String tab, IconData icon, String label) {
    final bool isActive = controller.activeTab.value == tab;
    return GestureDetector(
      onTap: () => controller.activeTab.value = tab,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 2.0),
          boxShadow: isActive
              ? []
              : const [
                  BoxShadow(color: AppColors.border, offset: Offset(3.0, 3.0)),
                ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : AppColors.text,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isActive ? Colors.white : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. OVERVIEW TAB
  // ==========================================
  Widget _buildOverviewTab() {
    final double revenue = controller.totalRevenue.value;
    final double energy = controller.totalEnergykWh.value;
    final int users = controller.totalUsersCount.value;
    final int chargersOnline = controller.chargersOnlineCount.value;
    final int totalChargers = controller.allStations.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SYSTEM METRICS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                icon: Icons.currency_rupee_rounded,
                label: 'Total Revenue',
                value: '₹${revenue.toStringAsFixed(2)}',
                accent: true,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                icon: Icons.electric_bolt_rounded,
                label: 'Energy Supplied',
                value: '${energy.toStringAsFixed(1)} kWh',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                icon: Icons.people_rounded,
                label: 'Registered Users',
                value: users.toString(),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                icon: Icons.power_rounded,
                label: 'Chargers Online',
                value: '$chargersOnline / $totalChargers',
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Chargers Online Status List
          // const Text(
          //   'PHYSICAL CONNECTIVITY STATUS (OCPP)',
          //   style: TextStyle(
          //     fontSize: 10,
          //     fontWeight: FontWeight.w900,
          //     color: AppColors.textMuted,
          //     letterSpacing: 1.0,
          //   ),
          // ),
          // const SizedBox(height: 12),
          // if (controller.liveChargers.isEmpty)
          //   NeoCard(
          //     padding: const EdgeInsets.all(24),
          //     child: const Center(
          //       child: Text(
          //         'No active OCPP chargers registered on telemetry.',
          //         style: TextStyle(
          //           fontFamily: 'Space Grotesk',
          //           fontWeight: FontWeight.w700,
          //           color: AppColors.textMuted,
          //         ),
          //       ),
          //     ),
          //   )
          // else
          //   ListView.separated(
          //     shrinkWrap: true,
          //     physics: const NeverScrollableScrollPhysics(),
          //     itemCount: controller.liveChargers.length,
          //     separatorBuilder: (context, index) => const SizedBox(height: 12),
          //     itemBuilder: (context, index) {
          //       final charger = controller.liveChargers[index];
          //       final String chargerId = charger['id'] ?? 'Unknown';
          //       final bool isConnected = charger['connected'] ?? false;
          //       final String status = charger['status'] ?? 'Offline';

          //       Color statusColor;
          //       Color statusBg;
          //       switch (status.toLowerCase()) {
          //         case 'available':
          //           statusColor = const Color(0xFF16A34A);
          //           statusBg = const Color(0xFFF0FDF4);
          //           break;
          //         case 'charging':
          //           statusColor = AppColors.primary;
          //           statusBg = AppColors.primary.withValues(alpha: 0.1);
          //           break;
          //         case 'faulted':
          //           statusColor = AppColors.error;
          //           statusBg = const Color(0xFFFEF2F2);
          //           break;
          //         default:
          //           statusColor = const Color(0xFF64748B);
          //           statusBg = const Color(0xFFF8FAFC);
          //       }

          //       return NeoCard(
          //         padding: const EdgeInsets.symmetric(
          //           horizontal: 16,
          //           vertical: 12,
          //         ),
          //         child: Row(
          //           children: [
          //             Container(
          //               width: 8,
          //               height: 8,
          //               decoration: BoxDecoration(
          //                 color: isConnected
          //                     ? const Color(0xFF4ADE80)
          //                     : const Color(0xFF94A3B8),
          //                 shape: BoxShape.circle,
          //               ),
          //             ),
          //             const SizedBox(width: 12),
          //             Expanded(
          //               child: Text(
          //                 chargerId.toUpperCase(),
          //                 style: const TextStyle(
          //                   fontFamily: 'Space Grotesk',
          //                   fontWeight: FontWeight.w900,
          //                   fontSize: 14,
          //                   color: AppColors.text,
          //                 ),
          //               ),
          //             ),
          //             Container(
          //               padding: const EdgeInsets.symmetric(
          //                 horizontal: 8,
          //                 vertical: 4,
          //               ),
          //               decoration: BoxDecoration(
          //                 color: statusBg,
          //                 borderRadius: BorderRadius.circular(6),
          //                 border: Border.all(color: statusColor, width: 1.5),
          //               ),
          //               child: Text(
          //                 status.toUpperCase(),
          //                 style: TextStyle(
          //                   fontSize: 8,
          //                   fontWeight: FontWeight.w900,
          //                   color: statusColor,
          //                   letterSpacing: 0.5,
          //                 ),
          //               ),
          //             ),
          //           ],
          //         ),
          //       );
          //     },
          //   ),
        ],
      ),
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
        shadowColor: accent
            ? AppColors.primary.withValues(alpha: 0.2)
            : AppColors.border.withValues(alpha: 0.08),
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
                      color: accent
                          ? AppColors.primary
                          : const Color(0xFFE2E8F0),
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
                      color: accent
                          ? const Color(0xFF94A3B8)
                          : AppColors.textMuted,
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
                fontSize: 20,
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

  // ==========================================
  // 2. STATIONS TAB (CRUD)
  // ==========================================
  Widget _buildStationsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar and Add Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: NeoTextField(
                  label: 'Search Stations',
                  hintText: 'Search by ID or name...',
                  prefixIcon: Icons.search_rounded,
                  controller:
                      TextEditingController(
                        text: controller.stationSearchQuery.value,
                      )..addListener(() {
                        controller.stationSearchQuery.value =
                            controller.stationSearchQuery.value;
                      }),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  const SizedBox(height: 18), // Align with textfield
                  GestureDetector(
                    onTap: () => _showStationDialog(),
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 2.0),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.border,
                            offset: Offset(3.0, 3.0),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_rounded, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'ADD NEW',
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Stations list
        Expanded(
          child: Obx(() {
            final list = controller.filteredStations;
            if (list.isEmpty) {
              return const Center(
                child: Text(
                  'No stations match the search query.',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    color: AppColors.textMuted,
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              itemCount: list.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final station = list[index];
                return _buildStationCard(station);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStationCard(Map<String, dynamic> station) {
    final String sId = station['id'] ?? station['stationId'] ?? '';
    final String name = station['name'] ?? 'No Name';
    final String address = station['address'] ?? 'No Address';
    final double cost =
        (station['costPerKwh'] ?? station['pricePerHour'])?.toDouble() ?? 15.0;
    final String connector =
        station['connectorType'] ?? station['chargerType'] ?? 'CCS2';
    final bool isPublished = station['published'] ?? false;

    // Check if currently online in socket state
    final liveCharger = controller.liveChargers.firstWhereOrNull(
      (c) => c['id'] == sId,
    );
    final bool isOnline =
        liveCharger != null && (liveCharger['connected'] == true);

    return NeoCard(
      padding: const EdgeInsets.all(16),
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
                  color: isOnline
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 2.0),
                ),
                child: Icon(
                  Icons.ev_station_rounded,
                  color: isOnline
                      ? const Color(0xFF16A34A)
                      : AppColors.textLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: $sId',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: AppColors.textLight,
                      ),
                    ),
                    if (station['websocketUrl'] != null &&
                        (station['websocketUrl'] as String).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'URL: ${station['websocketUrl']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹$cost/kWh',
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  connector.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPublished
                      ? const Color(0xFFE0F2FE)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isPublished
                        ? const Color(0xFF0284C7)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Text(
                  isPublished ? 'PUBLISHED' : 'DRAFT',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: isPublished
                        ? const Color(0xFF0284C7)
                        : AppColors.textMuted,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: AppColors.text),
                    onPressed: () => _showStationDialog(station: station),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_rounded,
                      color: AppColors.error,
                    ),
                    onPressed: () {
                      Get.defaultDialog(
                        title: 'Confirm Delete',
                        titleStyle: const TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontWeight: FontWeight.w900,
                        ),
                        middleText:
                            'Are you sure you want to delete station $sId?',
                        middleTextStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: Colors.white,
                        radius: 12,
                        textCancel: 'CANCEL',
                        textConfirm: 'DELETE',
                        confirmTextColor: Colors.white,
                        buttonColor: AppColors.error,
                        onConfirm: () {
                          Get.back();
                          controller.deleteStation(sId);
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStationDialog({Map<String, dynamic>? station}) {
    final isEdit = station != null;
    final stationIdController = TextEditingController(
      text: station?['stationId'] ?? station?['id'] ?? '',
    );
    final nameController = TextEditingController(text: station?['name'] ?? '');
    final websocketUrlController = TextEditingController(
      text: station?['websocketUrl'] ?? '',
    );
    final latController = TextEditingController(
      text:
          station?['latitude']?.toString() ?? station?['lat']?.toString() ?? '',
    );
    final lngController = TextEditingController(
      text:
          station?['longitude']?.toString() ??
          station?['lng']?.toString() ??
          '',
    );
    final addressController = TextEditingController(
      text: station?['address'] ?? '',
    );
    final costController = TextEditingController(
      text:
          station?['costPerKwh']?.toString() ??
          station?['pricePerHour']?.toString() ??
          '15.0',
    );
    final connectorController = TextEditingController(
      text: station?['connectorType'] ?? station?['chargerType'] ?? 'CCS2',
    );
    bool published = station?['published'] ?? true;

    // If it's a new station, typing in websocketUrl can auto-fill stationId
    if (!isEdit) {
      websocketUrlController.addListener(() {
        final url = websocketUrlController.text.trim();
        if (url.isNotEmpty) {
          String extractedId = url;
          if (url.contains('://') || url.startsWith('/')) {
            try {
              final parts = url.split('/');
              final lastPart = parts.isNotEmpty ? parts.last : '';
              if (lastPart.isNotEmpty) {
                extractedId = lastPart.replaceAll(
                  RegExp(r'[^a-zA-Z0-9_-]'),
                  '',
                );
              }
            } catch (e) {
              // ignore
            }
          }
          if (extractedId.isNotEmpty) {
            stationIdController.text = extractedId;
          }
        }
      });
    }

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.border, width: 3.0),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEdit ? 'EDIT STATION DETAILS' : 'ADD NEW CHARGER HUB',
                    style: const TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 20),
                  NeoTextField(
                    label: 'Station Name',
                    hintText: 'e.g. Connaught Place Hub',
                    controller: nameController,
                  ),
                  const SizedBox(height: 16),
                  NeoTextField(
                    label: 'WebSocket Connection URL',
                    hintText: 'e.g. ws://51.20.41.4:9221/ocpp/mgch001',
                    controller: websocketUrlController,
                    enabled: !isEdit,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Paste the charger\'s WebSocket URL. We\'ll extract the OCPP ID automatically.',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isEdit) ...[
                    NeoTextField(
                      label: 'Station ID',
                      hintText: 'e.g. mgch003',
                      controller: stationIdController,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: NeoTextField(
                          label: 'Latitude',
                          hintText: 'e.g. 28.6139',
                          controller: latController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NeoTextField(
                          label: 'Longitude',
                          hintText: 'e.g. 77.2090',
                          controller: lngController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  NeoTextField(
                    label: 'Address',
                    hintText: 'e.g. G-Block, CP, New Delhi',
                    controller: addressController,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: NeoTextField(
                          label: 'Cost / kWh (\u20b9)',
                          hintText: 'e.g. 18.5',
                          controller: costController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NeoTextField(
                          label: 'Connector Type',
                          hintText: 'e.g. CCS2',
                          controller: connectorController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PUBLISHED STATUS',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                      Switch(
                        value: published,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            published = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.border,
                                width: 2.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'CANCEL',
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NeoButton(
                          text: 'SAVE',
                          onPressed: () {
                            final name = nameController.text.trim();
                            final address = addressController.text.trim();
                            final wsUrl = websocketUrlController.text.trim();
                            final lat =
                                double.tryParse(latController.text.trim()) ??
                                0.0;
                            final lng =
                                double.tryParse(lngController.text.trim()) ??
                                0.0;
                            final cost =
                                double.tryParse(costController.text.trim()) ??
                                15.0;
                            final conn = connectorController.text.trim();
                            final sId = stationIdController.text.trim();

                            if (name.isEmpty ||
                                address.isEmpty ||
                                conn.isEmpty ||
                                (!isEdit && sId.isEmpty)) {
                              Get.snackbar(
                                'Input Error',
                                'Please fill in all fields',
                              );
                              return;
                            }

                            final data = {
                              if (!isEdit) 'stationId': sId,
                              'name': name,
                              'websocketUrl': wsUrl,
                              'lat': lat,
                              'lng': lng,
                              'latitude': lat,
                              'longitude': lng,
                              'address': address,
                              'costPerKwh': cost,
                              'pricePerHour': cost,
                              'connectorType': conn,
                              'chargerType': conn,
                              'published': published,
                            };

                            Get.back();
                            if (isEdit) {
                              controller.updateStation(station['id'], data);
                            } else {
                              controller.saveStation(data);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // 3. USERS TAB (LIST & RECHARGE)
  // ==========================================
  Widget _buildUsersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User search query input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: NeoTextField(
                  label: 'Search Users',
                  hintText: 'Search by name or email...',
                  prefixIcon: Icons.search_rounded,
                  controller:
                      TextEditingController(
                        text: controller.userSearchQuery.value,
                      )..addListener(() {
                        controller.userSearchQuery.value =
                            controller.userSearchQuery.value;
                      }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // User filter type segmented controls
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _buildFilterChip('all', 'All Users'),
              const SizedBox(width: 8),
              _buildFilterChip('active', 'Active (with trips)'),
              const SizedBox(width: 8),
              _buildFilterChip('inactive', 'Inactive (0 trips)'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // User records list
        Expanded(
          child: Obx(() {
            final list = controller.filteredUsers;
            if (list.isEmpty) {
              return const Center(
                child: Text(
                  'No matching user accounts found.',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    color: AppColors.textMuted,
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              itemCount: list.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final user = list[index];
                return _buildUserCard(user);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String filterType, String label) {
    final bool isSelected = controller.userFilterType.value == filterType;
    return GestureDetector(
      onTap: () => controller.userFilterType.value = filterType,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.text : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 2.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: isSelected ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final String name = user['name'] ?? 'No Name';
    final String email = user['email'] ?? 'No Email';
    final double wallet = (user['walletBalance'] as num?)?.toDouble() ?? 0.0;
    final int bookingsCount = user['totalBookings'] ?? 0;
    final String uid = user['id'] ?? '';

    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Text(
                  '₹${wallet.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                size: 14,
                color: AppColors.textLight,
              ),
              const SizedBox(width: 6),
              Text(
                'Bookings: $bookingsCount slots booked',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                child: Container(
                  width: 180, // fixed width
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    'UID: $uid',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              NeoButton(
                text: 'CREDIT ₹200',
                backgroundColor: AppColors.accent,
                textColor: AppColors.text,
                icon: Icons.add_card_rounded,
                width: 130,
                height: 36, // smaller height
                shadowOffset: 2.0,
                textStyle: const TextStyle(fontSize: 12),
                onPressed: () => controller.rechargeUserWallet(uid),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. OCPP COMMANDS TAB
  // ==========================================
  // Widget _buildCommandsTab(
  //   TextEditingController connectorIdController,
  //   TextEditingController idTagController,
  // ) {
  //   return SingleChildScrollView(
  //     padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           'SELECT OCPP CHARGING STATION',
  //           style: TextStyle(
  //             fontSize: 10,
  //             fontWeight: FontWeight.w900,
  //             color: AppColors.textMuted,
  //             letterSpacing: 1.0,
  //           ),
  //         ),
  //         const SizedBox(height: 8),

  //         // Station selector dropdown
  //         Obx(() {
  //           final stations = controller.allStations;
  //           if (stations.isEmpty) {
  //             return const Text('No stations available to command');
  //           }
  //           return Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 12),
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(12),
  //               border: Border.all(color: AppColors.border, width: 2.0),
  //             ),
  //             child: DropdownButtonHideUnderline(
  //               child: DropdownButton<String>(
  //                 value: controller.selectedStationId.value.isEmpty
  //                     ? null
  //                     : controller.selectedStationId.value,
  //                 hint: const Text(
  //                   'Select Target Station ID',
  //                   style: TextStyle(
  //                     fontFamily: 'Space Grotesk',
  //                     fontWeight: FontWeight.w700,
  //                     color: AppColors.textLight,
  //                   ),
  //                 ),
  //                 isExpanded: true,
  //                 dropdownColor: Colors.white,
  //                 items: stations.map((s) {
  //                   final id = s['id'] ?? '';
  //                   final name = s['name'] ?? id;
  //                   return DropdownMenuItem<String>(
  //                     value: id,
  //                     child: Text(
  //                       '$name ($id)',
  //                       style: const TextStyle(
  //                         fontFamily: 'Space Grotesk',
  //                         fontWeight: FontWeight.w800,
  //                         color: AppColors.text,
  //                       ),
  //                     ),
  //                   );
  //                 }).toList(),
  //                 onChanged: (val) {
  //                   if (val != null) {
  //                     controller.selectedStationId.value = val;
  //                   }
  //                 },
  //               ),
  //             ),
  //           );
  //         }),
  //         const SizedBox(height: 16),

  //         Row(
  //           children: [
  //             Expanded(
  //               child: NeoTextField(
  //                 label: 'Connector ID',
  //                 hintText: 'e.g. 1',
  //                 controller: connectorIdController,
  //                 keyboardType: TextInputType.number,
  //               ),
  //             ),
  //             const SizedBox(width: 16),
  //             Expanded(
  //               child: NeoTextField(
  //                 label: 'RFID ID Tag',
  //                 hintText: 'e.g. ADMIN_TEST',
  //                 controller: idTagController,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 24),

  //         // Action Buttons
  //         Row(
  //           children: [
  //             Expanded(
  //               child: Obx(() {
  //                 final isLoading =
  //                     controller.activeCommandLoading.value ==
  //                     'RemoteStartTransaction';
  //                 return NeoButton(
  //                   text: isLoading ? 'STARTING...' : 'REMOTE START',
  //                   backgroundColor: AppColors.primary,
  //                   icon: Icons.play_arrow_rounded,
  //                   onPressed: isLoading
  //                       ? null
  //                       : () => controller.sendOcppCommand(
  //                           'RemoteStartTransaction',
  //                         ),
  //                 );
  //               }),
  //             ),
  //             const SizedBox(width: 16),
  //             Expanded(
  //               child: Obx(() {
  //                 final isLoading =
  //                     controller.activeCommandLoading.value ==
  //                     'RemoteStopTransaction';
  //                 return NeoButton(
  //                   text: isLoading ? 'STOPPING...' : 'REMOTE STOP',
  //                   backgroundColor: AppColors.error,
  //                   icon: Icons.stop_rounded,
  //                   onPressed: isLoading
  //                       ? null
  //                       : () => controller.sendOcppCommand(
  //                           'RemoteStopTransaction',
  //                         ),
  //                 );
  //               }),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 28),

  //         // Command execution results CLI terminal
  //         NeoCard(
  //           backgroundColor: const Color(0xFF0F172A),
  //           padding: const EdgeInsets.all(16),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   const Text(
  //                     'REMOTE EXECUTION HISTORY',
  //                     style: TextStyle(
  //                       fontFamily: 'monospace',
  //                       fontSize: 11,
  //                       fontWeight: FontWeight.w900,
  //                       color: Color(0xFF38BDF8),
  //                     ),
  //                   ),
  //                   IconButton(
  //                     icon: const Icon(
  //                       Icons.delete_sweep_rounded,
  //                       color: Colors.white70,
  //                       size: 20,
  //                     ),
  //                     onPressed: () => controller.clearCommandLogs(),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 8),
  //               Container(
  //                 height: 200,
  //                 width: double.infinity,
  //                 padding: const EdgeInsets.all(12),
  //                 decoration: BoxDecoration(
  //                   color: const Color(0xFF1E293B),
  //                   borderRadius: BorderRadius.circular(8),
  //                   border: Border.all(color: const Color(0xFF334155)),
  //                 ),
  //                 child: Obx(() {
  //                   if (controller.commandTerminalLogs.isEmpty) {
  //                     return const Center(
  //                       child: Text(
  //                         'No command telemetry events dispatched.',
  //                         style: TextStyle(
  //                           fontFamily: 'monospace',
  //                           color: Colors.white38,
  //                           fontSize: 11,
  //                         ),
  //                       ),
  //                     );
  //                   }
  //                   return ListView.builder(
  //                     itemCount: controller.commandTerminalLogs.length,
  //                     itemBuilder: (context, index) {
  //                       final log = controller.commandTerminalLogs[index];
  //                       final type = log['type'];
  //                       final time = log['at'];
  //                       final msg = log['message'];

  //                       Color color = Colors.white;
  //                       if (type == 'success') {
  //                         color = const Color(0xFF4ADE80);
  //                       } else if (type == 'error') {
  //                         color = const Color(0xFFF87171);
  //                       } else {
  //                         color = const Color(0xFFFBBF24);
  //                       }

  //                       return Padding(
  //                         padding: const EdgeInsets.only(bottom: 6),
  //                         child: Text(
  //                           '[$time] $msg',
  //                           style: TextStyle(
  //                             fontFamily: 'monospace',
  //                             fontSize: 10.5,
  //                             color: color,
  //                           ),
  //                         ),
  //                       );
  //                     },
  //                   );
  //                 }),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ==========================================
  // 5. LIVE WEBSOCKET LOGS TAB
  // ==========================================
  // Widget _buildLogsTab() {
  //   return Padding(
  //     padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
  //     child: NeoCard(
  //       backgroundColor: const Color(0xFF0F172A),
  //       padding: const EdgeInsets.all(20),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             children: [
  //               const PulsingDot(),
  //               const SizedBox(width: 8),
  //               const Text(
  //                 'TELEMETRY DATA PACKETS',
  //                 style: TextStyle(
  //                   fontFamily: 'Space Grotesk',
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.w900,
  //                   color: Color(0xFF4ADE80),
  //                 ),
  //               ),
  //               const Spacer(),
  //               IconButton(
  //                 icon: const Icon(
  //                   Icons.delete_sweep_rounded,
  //                   color: Colors.white70,
  //                 ),
  //                 onPressed: () => controller.clearLiveLogs(),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 12),
  //           Expanded(
  //             child: Container(
  //               width: double.infinity,
  //               padding: const EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 color: const Color(0xFF1E293B),
  //                 borderRadius: BorderRadius.circular(8),
  //                 border: Border.all(color: const Color(0xFF334155)),
  //               ),
  //               child: Obx(() {
  //                 final logs = controller.wsLogs;
  //                 if (logs.isEmpty) {
  //                   return const Center(
  //                     child: Text(
  //                       'Waiting for telemetry data packet stream...',
  //                       style: TextStyle(
  //                         fontFamily: 'monospace',
  //                         color: Colors.white38,
  //                         fontSize: 11,
  //                       ),
  //                     ),
  //                   );
  //                 }
  //                 return ListView.builder(
  //                   itemCount: logs.length,
  //                   itemBuilder: (context, index) {
  //                     // Show newest logs at top
  //                     final log = logs[logs.length - 1 - index];
  //                     Color color = Colors.white;
  //                     if (log.contains('[ERROR]')) {
  //                       color = const Color(0xFFF87171);
  //                     } else if (log.contains('[WARNING]')) {
  //                       color = const Color(0xFFFBBF24);
  //                     } else if (log.contains('[SYSTEM]')) {
  //                       color = const Color(0xFF60A5FA);
  //                     } else if (log.contains('charger_connected')) {
  //                       color = const Color(0xFF34D399);
  //                     } else if (log.contains('status_notification')) {
  //                       color = const Color(0xFFFBCFE8);
  //                     }

  //                     return Padding(
  //                       padding: const EdgeInsets.only(bottom: 6),
  //                       child: Text(
  //                         log,
  //                         style: TextStyle(
  //                           fontFamily: 'monospace',
  //                           fontSize: 10,
  //                           color: color,
  //                         ),
  //                       ),
  //                     );
  //                   },
  //                 );
  //               }),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}

// ==========================================
// --- MARQUEE TICKER HELPER WIDGET ---
// ==========================================
class MarqueeTicker extends StatefulWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const MarqueeTicker({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  State<MarqueeTicker> createState() => _MarqueeTickerState();
}

class _MarqueeTickerState extends State<MarqueeTicker> {
  late ScrollController _scrollController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double currentScroll = _scrollController.offset;
        double delta = 1.0; // speed
        if (currentScroll >= maxScroll) {
          _scrollController.jumpTo(0.0);
        } else {
          _scrollController.jumpTo(currentScroll + delta);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: widget.backgroundColor,
      alignment: Alignment.centerLeft,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                widget.text,
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: widget.textColor,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
