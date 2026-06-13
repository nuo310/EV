import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/api_service.dart';
import '../services/admin_socket_service.dart';

class AdminController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final AdminSocketService _socketService = Get.find<AdminSocketService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Active tab selection
  final RxString activeTab = 'overview'.obs; // overview, stations, users, commands, logs

  // Stats variables
  final RxDouble totalRevenue = 0.0.obs;
  final RxDouble totalEnergykWh = 0.0.obs;
  final RxInt totalUsersCount = 0.obs;
  final RxInt chargersOnlineCount = 0.obs;

  // Firestore collections
  final RxList<Map<String, dynamic>> allUsers = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> allStations = <Map<String, dynamic>>[].obs;
  
  // Telemetry state
  RxBool get wsConnected => _socketService.connected;
  RxList<String> get wsLogs => _socketService.rawLogs;
  final RxList<Map<String, dynamic>> liveChargers = <Map<String, dynamic>>[].obs;

  // OCPP command inputs
  final RxString selectedStationId = ''.obs;
  final RxInt connectorIdInput = 1.obs;
  final RxString idTagInput = 'ADMIN_TEST'.obs;
  final RxList<Map<String, dynamic>> commandTerminalLogs = <Map<String, dynamic>>[].obs;
  final RxString activeCommandLoading = ''.obs; // 'RemoteStartTransaction' or 'RemoteStopTransaction' or ''

  // Stations List Search
  final RxString stationSearchQuery = ''.obs;
  final RxString userSearchQuery = ''.obs;
  final RxString userFilterType = 'all'.obs; // all, active, inactive

  StreamSubscription? _wsSubscription;
  StreamSubscription? _stationsSubscription;
  StreamSubscription? _bookingsSubscription;
  StreamSubscription? _usersSubscription;

  @override
  void onInit() {
    super.onInit();
    _socketService.start();
    _subscribeToSocketEvents();
    _subscribeToStations();
    _subscribeToUsersAndBookings();
  }

  @override
  void onClose() {
    _wsSubscription?.cancel();
    _stationsSubscription?.cancel();
    _bookingsSubscription?.cancel();
    _usersSubscription?.cancel();
    _socketService.stop();
    super.onClose();
  }

  /// Refreshes all Firestore data manually
  Future<void> refreshData() async {
    await _fetchUsersAndBookingsOnce();
  }

  void clearLiveLogs() {
    _socketService.rawLogs.clear();
  }

  void clearCommandLogs() {
    commandTerminalLogs.clear();
  }

  /// Listen to WebSocket telemetry events from the server
  void _subscribeToSocketEvents() {
    _wsSubscription?.cancel();
    _wsSubscription = _socketService.eventStream.listen((event) {
      final type = event['type'];
      final Map<String, dynamic> data = event['data'] ?? {};

      if (type == 'initial_snapshot') {
        final List chargers = data['chargers'] ?? [];
        liveChargers.value = chargers.map((c) => Map<String, dynamic>.from(c)).toList();
        _updateOnlineCount();
      } else if (type == 'charger_connected') {
        final stationId = data['stationId'];
        final existing = liveChargers.firstWhereOrNull((c) => c['id'] == stationId);
        if (existing != null) {
          existing['connected'] = true;
          existing['websocketUrl'] = data['websocketUrl'];
          liveChargers.refresh();
        } else {
          liveChargers.add({
            'id': stationId,
            'connected': true,
            'websocketUrl': data['websocketUrl'],
            'latitude': data['latitude'],
            'longitude': data['longitude'],
            'status': 'Available',
          });
        }
        _updateOnlineCount();
      } else if (type == 'charger_disconnected') {
        final stationId = data['stationId'];
        final existing = liveChargers.firstWhereOrNull((c) => c['id'] == stationId);
        if (existing != null) {
          existing['connected'] = false;
          liveChargers.refresh();
        }
        _updateOnlineCount();
      } else if (type == 'status_notification') {
        final stationId = data['stationId'];
        final status = data['status'];
        final existing = liveChargers.firstWhereOrNull((c) => c['id'] == stationId);
        if (existing != null) {
          existing['status'] = status;
          liveChargers.refresh();
        }
      }
    });
  }

  void _updateOnlineCount() {
    chargersOnlineCount.value = liveChargers.where((c) => c['connected'] == true).length;
  }

  /// Listen to Firestore stations collection
  void _subscribeToStations() {
    _stationsSubscription?.cancel();
    _stationsSubscription = _firestore.collection('stations').snapshots().listen((snap) {
      allStations.value = snap.docs.map((doc) => {
        'id': doc.id,
        ...doc.data()
      }).toList();
      allStations.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    });
  }

  /// Real-time subscription to users and bookings
  void _subscribeToUsersAndBookings() {
    _usersSubscription?.cancel();
    _usersSubscription = _firestore.collection('users').snapshots().listen((userSnap) {
      _bookingsSubscription?.cancel();
      _bookingsSubscription = _firestore.collection('bookings').snapshots().listen((bookingSnap) {
        final List<Map<String, dynamic>> usersList = userSnap.docs.map((d) => {
          'id': d.id,
          ...d.data()
        }).toList();

        double revenue = 0.0;
        double energy = 0.0;
        final List<Map<String, dynamic>> bookingsList = [];

        for (var doc in bookingSnap.docs) {
          final data = doc.data();
          revenue += (data['paidAmount'] as num?)?.toDouble() ?? 0.0;
          energy += (data['energyKwh'] as num?)?.toDouble() ?? 5.5; // fallback defaults
          bookingsList.add({
            'id': doc.id,
            ...data
          });
        }

        final enrichedUsers = usersList.map((user) {
          final userBookings = bookingsList.where((b) => b['userId'] == user['id']).toList();
          userBookings.sort((a, b) {
            final tA = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final tB = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            return tB.compareTo(tA);
          });
          return {
            ...user,
            'totalBookings': userBookings.length,
            'latestBooking': userBookings.isNotEmpty ? userBookings.first : null,
          };
        }).toList();

        totalRevenue.value = revenue;
        totalEnergykWh.value = energy;
        totalUsersCount.value = enrichedUsers.where((u) => u['role'] != 'admin').length;
        allUsers.value = enrichedUsers;
      });
    });
  }

  /// Helper to force fetch once
  Future<void> _fetchUsersAndBookingsOnce() async {
    final userSnap = await _firestore.collection('users').get();
    final bookingSnap = await _firestore.collection('bookings').get();
    
    final List<Map<String, dynamic>> usersList = userSnap.docs.map((d) => {
      'id': d.id,
      ...d.data()
    }).toList();

    double revenue = 0.0;
    double energy = 0.0;
    final List<Map<String, dynamic>> bookingsList = [];

    for (var doc in bookingSnap.docs) {
      final data = doc.data();
      revenue += (data['paidAmount'] as num?)?.toDouble() ?? 0.0;
      energy += (data['energyKwh'] as num?)?.toDouble() ?? 5.5;
      bookingsList.add({
        'id': doc.id,
        ...data
      });
    }

    final enrichedUsers = usersList.map((user) {
      final userBookings = bookingsList.where((b) => b['userId'] == user['id']).toList();
      return {
        ...user,
        'totalBookings': userBookings.length,
        'latestBooking': userBookings.isNotEmpty ? userBookings.first : null,
      };
    }).toList();

    totalRevenue.value = revenue;
    totalEnergykWh.value = energy;
    allUsers.value = enrichedUsers;
  }

  /// --- STATION CRUD ACTIONS ---
  Future<void> saveStation(Map<String, dynamic> station) async {
    try {
      await _apiService.addStation(station);
      Get.snackbar('Success', 'Station ${station['stationId']} added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add station: $e');
    }
  }

  Future<void> updateStation(String stationId, Map<String, dynamic> station) async {
    try {
      await _apiService.updateStation(stationId, station);
      Get.snackbar('Success', 'Station $stationId updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update station: $e');
    }
  }

  Future<void> deleteStation(String stationId) async {
    try {
      await _apiService.deleteStation(stationId);
      Get.snackbar('Success', 'Station $stationId deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete station: $e');
    }
  }

  Future<void> togglePublishStation(Map<String, dynamic> station) async {
    final id = station['id'];
    final currentlyPublished = station['published'] ?? false;
    try {
      await _apiService.updateStation(id, {'published': !currentlyPublished});
    } catch (e) {
      Get.snackbar('Error', 'Failed to update publish state: $e');
    }
  }

  /// --- WALLET MANAGEMENT ---
  Future<void> rechargeUserWallet(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'walletBalance': FieldValue.increment(200.0)
      });
      Get.snackbar('Recharge Success', 'Credited \u20b9200.00 to user wallet');
    } catch (e) {
      Get.snackbar('Error', 'Failed to adjust user wallet: $e');
    }
  }

  /// --- OCPP TEST COMMANDS ---
  Future<void> sendOcppCommand(String action) async {
    final stationId = selectedStationId.value;
    if (stationId.isEmpty) {
      Get.snackbar('Warning', 'Please select a target station');
      return;
    }
    
    activeCommandLoading.value = action;
    _addCommandLog('sent', action, '> Sending $action to $stationId...');

    try {
      if (action == 'RemoteStartTransaction') {
        final response = await _apiService.remoteStartCharging(
          stationId: stationId,
          connectorId: connectorIdInput.value,
          idTag: idTagInput.value,
        );
        _addCommandLog('success', action, '$action \u2192 ${json.encode(response)}');
      } else {
        int? activeTxId;
        try {
          final txSnap = await _firestore.collection('transactions')
              .where('stationId', isEqualTo: stationId)
              .where('status', isEqualTo: 'active')
              .limit(1)
              .get();
          if (txSnap.docs.isNotEmpty) {
            activeTxId = (txSnap.docs.first.data()['ocppTransactionId'] as num?)?.toInt();
          }
        } catch (dbErr) {
          print('Failed to lookup active transaction ID in AdminController: $dbErr');
        }

        final response = await _apiService.remoteStopCharging(
          stationId: stationId,
          transactionId: activeTxId,
        );
        _addCommandLog('success', action, '$action (TxId: $activeTxId) \u2192 ${json.encode(response)}');
      }
    } catch (e) {
      _addCommandLog('error', action, 'Error executing command: $e');
    } finally {
      activeCommandLoading.value = '';
    }
  }

  void _addCommandLog(String type, String action, String message) {
    commandTerminalLogs.insert(0, {
      'type': type,
      'action': action,
      'message': message,
      'at': DateTime.now().toLocal().toString().split(' ')[1].substring(0, 8)
    });
    if (commandTerminalLogs.length > 50) {
      commandTerminalLogs.removeLast();
    }
  }

  // --- FILTERED DATA GETTERS ---
  List<Map<String, dynamic>> get filteredStations {
    final q = stationSearchQuery.value.toLowerCase().trim();
    if (q.isEmpty) return allStations;
    return allStations.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      final id = (s['id'] ?? '').toString().toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get filteredUsers {
    final q = userSearchQuery.value.toLowerCase().trim();
    final filter = userFilterType.value;
    final List<Map<String, dynamic>> nonAdmins = allUsers.where((u) => u['role'] != 'admin').toList();

    List<Map<String, dynamic>> filtered = nonAdmins;
    
    // Apply role-based filter type
    if (filter == 'active') {
      filtered = filtered.where((u) => (u['totalBookings'] ?? 0) > 0).toList();
    } else if (filter == 'inactive') {
      filtered = filtered.where((u) => (u['totalBookings'] ?? 0) == 0).toList();
    }

    if (q.isNotEmpty) {
      filtered = filtered.where((u) {
        final name = (u['name'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    }
    
    return filtered;
  }
}
