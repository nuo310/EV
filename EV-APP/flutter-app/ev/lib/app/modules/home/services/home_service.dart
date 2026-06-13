import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/api_service.dart';

class HomeService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Dashboard Stats
  final RxDouble walletBalance = 0.0.obs;
  final RxInt activeSessions = 0.obs;
  final RxString chargerStatus = 'Available'.obs;

  // Live Telemetry Streams
  final RxString latency = '42ms'.obs;
  final RxDouble latencyPercent = 0.42.obs;
  final RxString throughput = '8.4 GB/s'.obs;
  final RxDouble throughputPercent = 0.68.obs;
  final RxString syncStatus = 'ESTABLISHED'.obs;
  final RxDouble syncPercent = 0.95.obs;
  final RxString authHandshakes = '1,204'.obs;
  final RxDouble authPercent = 0.55.obs;

  // Live Terminal Logs
  final RxList<String> logs = <String>[
    '> Initiating secure handshake...',
    '> AUTH SUCCESSFUL [ID_38592]',
    '> Polling local hubs [Zip: 90210]',
    '> Received telemetry: Station 04',
    '> Load balancing active...',
    '[SYSTEM] Refresh triggered (200ms)',
  ].obs;

  // Live Bookings list syncing from Firestore
  final RxList<Map<String, dynamic>> bookings = <Map<String, dynamic>>[].obs;

  int get totalSpent => bookings
      .where((b) => b['status'].toString().toLowerCase() == 'completed' || b['status'].toString().toLowerCase() == 'active')
      .fold<int>(0, (total, b) => total + ((b['amount'] as num?)?.toInt() ?? 0));

  int get activeBookingsCount => bookings.where((b) => b['status'].toString().toLowerCase() == 'active').length;

  int get completedBookingsCount => bookings.where((b) => b['status'].toString().toLowerCase() == 'completed').length;

  // Reactive user position (Ahmedabad center as default fallback)
  final Rx<LatLng> userPosition = const LatLng(23.0225, 72.5714).obs;
  final RxBool isFetchingLocation = false.obs;

  // Active Stations list syncing from Firestore
  final RxList<Map<String, dynamic>> stations = <Map<String, dynamic>>[].obs;

  // Find Chargers Modal / Selection State
  final Rx<String?> selectedStationId = Rx<String?>(null);
  final Rx<String?> kwhInputStationId = Rx<String?>(null);
  final RxInt kwhInputValue = 20.obs;
  final Rx<Map<String, dynamic>?> receiptData = Rx<Map<String, dynamic>?>(null);
  final RxBool isBookingLoading = false.obs;

  // Active Charging Session Timer
  Timer? _chargingTimer;
  final Rx<String?> chargingStationId = Rx<String?>(null);
  final RxInt chargingElapsedSeconds = 0.obs;
  final RxDouble chargingEnergyKwh = 0.0.obs;
  final RxDouble chargingCost = 0.0.obs;

  Timer? _telemetryTimer;
  Timer? _logTimer;
  final Random _random = Random();

  StreamSubscription? _authSub;
  StreamSubscription? _userProfileSub;
  StreamSubscription? _stationsSub;
  StreamSubscription? _bookingsSub;
  StreamSubscription? _webBookingsSub;

  String? _lastActiveTransactionId;

  void startServices() {
    _startSimulations();
    determinePosition();
    _listenToStations();
    _initAuthListener();
    _listenToActiveChargingSession();
  }

  void stopServices() {
    _telemetryTimer?.cancel();
    _logTimer?.cancel();
    _chargingTimer?.cancel();
    _authSub?.cancel();
    _userProfileSub?.cancel();
    _stationsSub?.cancel();
    _bookingsSub?.cancel();
    _webBookingsSub?.cancel();
  }

  /// OCR / User tag identity helper (20-chars max for physical OCPP compatibility)
  String get _ocppIdTag {
    final email = _auth.currentUser?.email ?? 'USER_001';
    return email.length > 20 ? email.substring(0, 20) : email;
  }

  /// Initialise auth change listener to subscribe to user data and bookings
  void _initAuthListener() {
    _authSub?.cancel();
    _authSub = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _listenToUserProfile();
        _listenToBookings();
      } else {
        _userProfileSub?.cancel();
        _bookingsSub?.cancel();
        _webBookingsSub?.cancel();
        bookings.clear();
        walletBalance.value = 0.0;
      }
    });
  }

  /// Listen to user profile for real-time wallet updates
  void _listenToUserProfile() {
    _userProfileSub?.cancel();
    final user = _auth.currentUser;
    if (user != null) {
      _userProfileSub = _firestore.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            walletBalance.value = (data['walletBalance'] as num?)?.toDouble() ?? 0.0;
          }
        }
      });
    }
  }

  /// Listen to stations collection in Firestore
  void _listenToStations() {
    _stationsSub?.cancel();
    _stationsSub = _firestore
        .collection('stations')
        .where('published', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      stations.value = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'status': data['status'] ?? 'Unavailable',
          'connectorId': data['connectorId'] ?? 1,
          'chargerType': data['chargerType'] ?? 'Unknown',
          'vendor': data['vendor'] ?? '',
          'model': data['model'] ?? '',
          'availableSlots': data['availableSlots'] ?? 0,
          'errorCode': data['errorCode'] ?? 'NoError',
          'isOnline': data['isOnline'] ?? false,
          'lat': (data['lat'] as num?)?.toDouble() ?? 0.0,
          'lng': (data['lng'] as num?)?.toDouble() ?? 0.0,
          'ratePerKwh': (data['energyRatePerKwh'] as num?)?.toInt() ?? 12,
          'pricePerHour': (data['pricePerHour'] as num?)?.toInt() ?? 15,
        };
      }).toList();
      logs.add('> [SYSTEM] Synced ${stations.length} stations from database');
    });
  }

  List<Map<String, dynamic>> _ocppTransactionsList = [];
  List<Map<String, dynamic>> _webBookingsList = [];

  /// Listen to transactions and bookings collection in Firestore for real-time synchronization
  void _listenToBookings() {
    _bookingsSub?.cancel();
    _webBookingsSub?.cancel();
    
    final idTag = _ocppIdTag;
    final uid = _auth.currentUser?.uid ?? '';
    final email = _auth.currentUser?.email ?? '';

    logs.add('> [DEBUG] listenToBookings: idTag=$idTag');
    logs.add('> [DEBUG] UID: $uid');
    logs.add('> [DEBUG] Email: $email');
    print('[DEBUG] listenToBookings: idTag=$idTag, uid=$uid, email=$email');

    // 1. Listen to OCPP Transactions (transactions collection)
    _bookingsSub = _firestore
        .collection('transactions')
        .where('userId', isEqualTo: idTag)
        .snapshots()
        .listen((snapshot) {
      _ocppTransactionsList = snapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final endedAt = (data['endedAt'] as Timestamp?)?.toDate();
        final String stationId = data['stationId'] ?? '';
        final station = getStationById(stationId);
        final String stationName = station?['name'] ?? 'Station $stationId';
        final int rate = station?['ratePerKwh'] ?? 12;

        double amount = 0.0;
        if (data['status'] == 'completed') {
          final double energy = (((data['meterStop'] as num?) ?? 0) - ((data['meterStart'] as num?) ?? 0)) / 1000.0;
          amount = double.parse((energy * rate).toStringAsFixed(2));
        } else if (data['status'] == 'active') {
          final double elapsedSec = DateTime.now().difference(timestamp).inSeconds.toDouble();
          final double energy = elapsedSec * 0.00206;
          amount = double.parse((energy * rate).toStringAsFixed(2));
        }

        return {
          'id': doc.id,
          'stationName': stationName,
          'stationId': stationId,
          'createdAt': timestamp,
          'endedAt': endedAt,
          'amount': amount.round(),
          'status': (data['status'] ?? '').toString().capitalizeFirst ?? 'Active',
          'meterStart': data['meterStart'] ?? 0,
          'meterStop': data['meterStop'] ?? 0,
          'ocppTransactionId': data['ocppTransactionId'],
        };
      }).toList();
      logs.add('> [DEBUG] Synced ${_ocppTransactionsList.length} transactions');
      _mergeAndSortBookings();
    }, onError: (e) {
      logs.add('> [ERROR] Transactions query failed: $e');
      print('[ERROR] Transactions query failed: $e');
    });

    // 2. Listen to Web Bookings (bookings collection)
    if (uid.isNotEmpty) {
      _webBookingsSub = _firestore
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .snapshots()
          .listen((snapshot) {
        _webBookingsList = snapshot.docs.map((doc) {
          final data = doc.data();
          final timestamp = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final endedAt = (data['completedAt'] as Timestamp? ?? data['endedAt'] as Timestamp?)?.toDate();
          final String stationId = data['stationId'] ?? '';
          final String stationName = data['stationName'] ?? 'Station $stationId';
          final int amount = (data['paidAmount'] as num?)?.toInt() ?? 0;

          return {
            'id': doc.id,
            'stationName': stationName,
            'stationId': stationId,
            'createdAt': timestamp,
            'endedAt': endedAt,
            'amount': amount,
            'status': (data['status'] ?? '').toString().capitalizeFirst ?? 'Completed',
            'meterStart': data['meterStartWh'] ?? 0,
            'meterStop': data['meterStopWh'] ?? data['meterEndWh'] ?? 0,
          };
        }).toList();
        logs.add('> [DEBUG] Synced ${_webBookingsList.length} bookings');
        _mergeAndSortBookings();
      }, onError: (e) {
        logs.add('> [ERROR] Bookings query failed: $e');
        print('[ERROR] Bookings query failed: $e');
      });
    }
  }

  void _mergeAndSortBookings() {
    final List<Map<String, dynamic>> merged = [];
    merged.addAll(_ocppTransactionsList);

    // Merge in Web bookings avoiding duplicate transaction entries
    for (var webB in _webBookingsList) {
      final exists = merged.any((ocppT) => 
        ocppT['id'] == webB['id'] || 
        ocppT['id'] == webB['paymentOrderId']
      );
      if (!exists) {
        merged.add(webB);
      }
    }

    merged.sort((a, b) => (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));
    bookings.value = merged;

    activeSessions.value = bookings.where((b) => b['status'].toString().toLowerCase() == 'active').length;
  }

  /// Live Active Session UI and Timer Controller
  void _listenToActiveChargingSession() {
    ever(bookings, (List<Map<String, dynamic>> currentBookings) {
      final activeBooking = currentBookings.firstWhereOrNull((b) => b['status'].toString().toLowerCase() == 'active');
      if (activeBooking != null) {
        final String activeStationId = activeBooking['stationId'];
        _lastActiveTransactionId = activeBooking['id'];

        if (chargingStationId.value != activeStationId) {
          chargingStationId.value = activeStationId;
          chargerStatus.value = 'Charging';
          
          final DateTime start = activeBooking['createdAt'] as DateTime;
          final int elapsedSeconds = DateTime.now().difference(start).inSeconds;
          chargingElapsedSeconds.value = elapsedSeconds >= 0 ? elapsedSeconds : 0;
          
          final int rate = getStationById(activeStationId)?['ratePerKwh'] ?? 12;
          
          _chargingTimer?.cancel();
          _chargingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            chargingElapsedSeconds.value++;
            // Power rate: ~7.4 kW = ~0.00206 kWh per second
            chargingEnergyKwh.value = chargingElapsedSeconds.value * 0.00206;
            chargingCost.value = double.parse((chargingEnergyKwh.value * rate).toStringAsFixed(2));
          });
        }
      } else {
        if (_lastActiveTransactionId != null) {
          // Find the completed transaction matching _lastActiveTransactionId
          final completedTx = currentBookings.firstWhereOrNull((b) => b['id'] == _lastActiveTransactionId && b['status'].toString().toLowerCase() == 'completed');
          if (completedTx != null) {
            final rate = getStationById(completedTx['stationId'])?['ratePerKwh'] ?? 12;
            final double energy = (((completedTx['meterStop'] as num?) ?? 0.0) - ((completedTx['meterStart'] as num?) ?? 0.0)) / 1000.0;
            final double cost = double.parse((energy * rate).toStringAsFixed(2));
            
            receiptData.value = {
              'stationName': completedTx['stationName'],
              'energyKwh': double.parse(energy.toStringAsFixed(2)),
              'ratePerKwh': rate,
              'energyCharge': cost,
              'billTotal': cost,
              'meterStartWh': completedTx['meterStart'],
              'meterEndWh': completedTx['meterStop'],
            };

            // Deduct cost from wallet in Firestore
            final user = _auth.currentUser;
            if (user != null) {
              _firestore.collection('users').doc(user.uid).update({
                'walletBalance': FieldValue.increment(-cost),
              });
              logs.add('> [SYSTEM] Deducted \u20b9$cost for completed session on ${completedTx['stationName']}');
            }
          }
          _lastActiveTransactionId = null;
        }

        if (chargingStationId.value != null) {
          _chargingTimer?.cancel();
          _chargingTimer = null;
          chargingStationId.value = null;
          chargerStatus.value = 'Available';
        }
      }
    });
  }

  /// Calculates distance between two lat/lng points using Haversine formula
  String? calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Earth radius in km
    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double d = R * c;
    return d.toStringAsFixed(1);
  }

  double _degToRad(double deg) => deg * (pi / 180);

  /// Get station distance from user position
  String getStationDistance(Map<String, dynamic> station) {
    final lat = station['lat'] as double?;
    final lng = station['lng'] as double?;
    if (lat == null || lng == null) return '--';
    return '${calculateDistance(userPosition.value.latitude, userPosition.value.longitude, lat, lng)} km';
  }

  /// Get stations sorted by distance from user
  List<Map<String, dynamic>> get sortedStations {
    final List<Map<String, dynamic>> sorted = List.from(stations);
    sorted.sort((a, b) {
      final distA = calculateDistance(userPosition.value.latitude, userPosition.value.longitude, (a['lat'] as double?) ?? 0, (a['lng'] as double?) ?? 0);
      final distB = calculateDistance(userPosition.value.latitude, userPosition.value.longitude, (b['lat'] as double?) ?? 0, (b['lng'] as double?) ?? 0);
      return (double.tryParse(distA ?? '999') ?? 999).compareTo(double.tryParse(distB ?? '999') ?? 999);
    });
    return sorted;
  }

  /// Get a station by ID
  Map<String, dynamic>? getStationById(String id) {
    try {
      return stations.firstWhere((s) => s['id'] == id);
    } catch (_) {
      return null;
    }
  }

  /// Open the Configure Charge modal for a station
  void openConfigureCharge(String stationId) {
    kwhInputStationId.value = stationId;
    kwhInputValue.value = 20;
  }

  /// Close the Configure Charge modal
  void closeConfigureCharge() {
    kwhInputStationId.value = null;
  }

  /// Start a charging session with the configured kWh (REST integration + local simulation)
  Future<void> startChargingSession(String stationId) async {
    final station = getStationById(stationId);
    if (station == null) return;

    isBookingLoading.value = true;
    try {
      // Dispatch API request to AWS backend
      await _apiService.remoteStartCharging(
        stationId: stationId,
        idTag: _ocppIdTag,
      );

      logs.add('> [API] START CHARGING sent to ${station['name']}');

      // Close the modal
      kwhInputStationId.value = null;
    } catch (e) {
      logs.add('[ERROR] API Failed: $e');
      Get.snackbar('Error', 'Failed to start charging session: $e');
    } finally {
      isBookingLoading.value = false;
    }
  }

  /// Stop the active charging session for a station
  Future<void> stopChargingSession(String stationId) async {
    final station = getStationById(stationId);
    if (station == null) return;

    // Try to find matching active transaction to pass transaction ID
    final activeBooking = bookings.firstWhereOrNull(
      (b) => b['stationId'] == stationId && b['status'].toString().toLowerCase() == 'active'
    );
    final int? ocppTxId = activeBooking?['ocppTransactionId'] != null 
        ? (activeBooking!['ocppTransactionId'] as num).toInt()
        : null;

    try {
      // Dispatch API request to backend
      await _apiService.remoteStopCharging(stationId: stationId, transactionId: ocppTxId);
      logs.add('> [API] STOP CHARGING sent to ${station['name']} (TxId: $ocppTxId)');
    } catch (e) {
      logs.add('[ERROR] API Failed: $e');
      Get.snackbar('Error', 'Failed to stop charging session: $e');
    }
  }

  /// Close the receipt modal
  void closeReceipt() {
    receiptData.value = null;
  }

  /// Check if a station has an active charging session
  bool isStationCharging(String stationId) {
    return chargingStationId.value == stationId;
  }

  /// Format elapsed seconds to mm:ss or hh:mm:ss
  String formatElapsed(int totalSeconds) {
    final int h = totalSeconds ~/ 3600;
    final int m = (totalSeconds % 3600) ~/ 60;
    final int s = totalSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    return '${m}m ${s}s';
  }

  Future<void> determinePosition() async {
    isFetchingLocation.value = true;
    logs.add('> [SYSTEM] Requesting geolocation permission...');
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        logs.add('[WARNING] Location services are disabled.');
        isFetchingLocation.value = false;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          logs.add('[WARNING] Location permissions are denied.');
          isFetchingLocation.value = false;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        logs.add('[WARNING] Location permissions are permanently denied.');
        isFetchingLocation.value = false;
        return;
      }

      logs.add('> [SYSTEM] Resolving current GPS coordinates...');
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
      
      if (position.latitude.isNaN || position.longitude.isNaN) {
        logs.add('[WARNING] GPS resolved NaN coordinates. Using default.');
      } else {
        userPosition.value = LatLng(position.latitude, position.longitude);
        logs.add('> [SYSTEM] Location locked: [${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}]');
      }
    } catch (e) {
      logs.add('[ERROR] Geolocation error: $e');
    } finally {
      isFetchingLocation.value = false;
    }
  }

  void _startSimulations() {
    // Latency & Telemetry fluctuate every 2 seconds
    _telemetryTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final int lat = 35 + _random.nextInt(15);
      latency.value = '${lat}ms';
      latencyPercent.value = lat / 100;

      final double tp = 7.5 + _random.nextDouble() * 2.0;
      throughput.value = '${tp.toStringAsFixed(1)} GB/s';
      throughputPercent.value = (tp - 5) / 5;

      final int handshakes = 1180 + _random.nextInt(50);
      authHandshakes.value = handshakes.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
      authPercent.value = (handshakes - 1000) / 400;
    });

    // Mock logs added every 3.5 seconds
    _logTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      final mockMessages = [
        '> Sync check: US-EAST-GLOBAL [OK]',
        '> Packet route optimized via node SYD_NORTH',
        '> Active bays capacity: 1,048 available',
        '[SYSTEM] OCPP heartbeat received',
        '> Latency correction applied: -2ms',
        '> Telemetry stream verified: node 04',
        '[WARNING] Transient load fluctuation on plaza NJ_A4',
      ];
      final newLog = mockMessages[_random.nextInt(mockMessages.length)];
      
      logs.add(newLog);
      if (logs.length > 15) {
        logs.removeAt(0);
      }
    });
  }

  void addCredits() {
    final user = _auth.currentUser;
    if (user != null) {
      _firestore.collection('users').doc(user.uid).update({
        'walletBalance': FieldValue.increment(50.0),
      });
      logs.add('> [SYSTEM] Added 50.0 credits to wallet');
    }
  }

  void toggleCharging() {
    // Left as simulator command log toggle
    if (activeSessions.value == 0) {
      logs.add('> [USER] SIMULATION: Start charging request triggered');
    } else {
      logs.add('> [USER] SIMULATION: Stop charging request triggered');
    }
  }
}

