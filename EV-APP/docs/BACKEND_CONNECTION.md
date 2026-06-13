# Backend Connection Documentation

This document describes how to connect the Flutter EV App to the backend server, similar to how the OCPP Backend communicates with charging stations and stores data in Firebase.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP (ev)                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │   Views     │  │ Controllers │  │   API Service Layer     │ │
│  │ (UI Layer)  │◄─┤ (Business   │◄─┤   (HTTP/JSON Client)    │ │
│  │             │  │   Logic)    │  │                         │ │
│  └─────────────┘  └─────────────┘  └───────────┬─────────────┘ │
└─────────────────────────────────────────────────┼───────────────┘
                                                  │
                                                  │ HTTP/HTTPS
                                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                      OCPP BACKEND (Node.js)                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │  WebSocket  │  │   Express   │  │   Firebase Firestore    │ │
│  │  (OCPP 1.6) │  │   REST API  │  │   (Database)            │ │
│  │             │◄─┤             │◄─┤                         │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 1. Backend API Endpoints

The OCPP Backend exposes the following HTTP endpoints for the Flutter app:

### Base URL
```
Production: https://your-backend-url.up.railway.app
Development: http://localhost:3000
```

### Available Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Health check - returns "Railway backend alive" |
| GET | `/ws-info` | Get WebSocket connection info for chargers |
| GET | `/stations/:stationId/status` | Get charger station status |
| POST | `/remote-start` | Start a charging session |
| POST | `/remote-stop` | Stop a charging session |
| GET | `/debug/chargers` | Debug: List connected chargers |

### API Response Format

All API responses follow this structure:

**Success Response:**
```json
{
  "field1": "value1",
  "field2": "value2"
}
```

**Error Response:**
```json
{
  "error": "Error message description"
}
```

---

## 2. Firebase Database Schema

The backend uses Firebase Firestore with the following collections:

### Collection: `stations`

Stores information about charging stations.

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Station name |
| `ocppStationId` | string | Unique OCPP charger ID |
| `lat` | number | Latitude coordinate |
| `lng` | number | Longitude coordinate |
| `availableSlots` | number | Number of available charging slots |
| `pricePerHour` | number | Price per hour |
| `energyRatePerKwh` | number | Energy rate per kWh |
| `chargerType` | string | Charger type (e.g., "Type 2 AC") |
| `connectorId` | number | Connector ID |
| `vendor` | string | Charger vendor |
| `model` | string | Charger model |
| `status` | string | Current status (Available, Charging, Preparing, Maintenance) |
| `errorCode` | string | Error code (NoError, GroundFailure, etc.) |
| `isOnline` | boolean | Online status |
| `published` | boolean | Published status |
| `lastSeen` | timestamp | Last time the station was seen |
| `websocketUrl` | string | WebSocket connection URL |

**Example document:**
```json
{
  "name": "Ahmedabad SG Highway Hub",
  "ocppStationId": "STN_001",
  "lat": 23.0300,
  "lng": 72.5100,
  "availableSlots": 3,
  "pricePerHour": 15,
  "energyRatePerKwh": 12,
  "chargerType": "Type 2 AC",
  "connectorId": 1,
  "vendor": "ABB",
  "model": "Terra 54",
  "status": "Available",
  "errorCode": "NoError",
  "isOnline": true,
  "published": true,
  "lastSeen": "2024-01-15T10:30:00.000Z",
  "websocketUrl": "wss://example.com/ocpp/STN_001"
}
```

### Collection: `transactions`

Stores charging transaction records.

| Field | Type | Description |
|-------|------|-------------|
| `stationId` | string | Station ID |
| `ocppTransactionId` | number | OCPP transaction ID |
| `connectorId` | number | Connector ID |
| `userId` | string | User ID (idTag) |
| `meterStart` | number | Meter start value (Wh) |
| `meterStop` | number | Meter stop value (Wh) |
| `status` | string | Transaction status (active, completed) |
| `timestamp` | timestamp | Transaction start time |
| `endedAt` | timestamp | Transaction end time |

### Collection: `meterValues`

Stores real-time meter values from charging stations.

| Field | Type | Description |
|-------|------|-------------|
| `stationId` | string | Station ID |
| `data` | map | Meter values data |
| `timestamp` | timestamp | Reading timestamp |

---

## 3. Flutter App Integration

### Step 1: Add Required Dependencies

Add `http` and `cloud_firestore` packages to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  get: ^4.6.6
  google_fonts: ^6.2.1
  flutter_map: ^8.3.0
  latlong2: ^0.9.1
  geolocator: ^14.0.2
  http: ^1.2.0          # Add this for HTTP requests
  cloud_firestore: ^4.15.0  # Add this for Firestore (optional, for direct DB access)
  firebase_core: ^2.27.0    # Add this for Firebase initialization
```

### Step 2: Create API Service Layer

Create a new service file at `lib/app/core/services/api_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Update this to your backend URL
  static const String baseUrl = 'https://your-backend-url.up.railway.app';
  
  final http.Client _client;
  
  ApiService({http.Client? client}) : _client = client ?? http.Client();
  
  // Get station status
  Future<Map<String, dynamic>> getStationStatus(String stationId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/stations/$stationId/status'),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get station status: ${response.statusCode}');
    }
  }
  
  // Get all stations (from Firestore via backend proxy or directly)
  Future<List<Map<String, dynamic>>> getAllStations() async {
    // Option 1: If backend provides this endpoint
    // final response = await _client.get(Uri.parse('$baseUrl/stations'));
    
    // Option 2: Use Firebase directly (see Step 4)
    throw UnimplementedError('Use Firebase Firestore for getting all stations');
  }
  
  // Remote start charging
  Future<Map<String, dynamic>> remoteStartCharging({
    required String stationId,
    int connectorId = 1,
    String idTag = 'WEB_APP',
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/remote-start'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'stationId': stationId,
        'connectorId': connectorId,
        'idTag': idTag,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to start charging');
    }
  }
  
  // Remote stop charging
  Future<Map<String, dynamic>> remoteStopCharging({
    required String stationId,
    int? transactionId,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/remote-stop'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'stationId': stationId,
        'transactionId': transactionId,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to stop charging');
    }
  }
  
  // Get connected chargers (debug)
  Future<List<Map<String, dynamic>>> getConnectedChargers() async {
    final response = await _client.get(Uri.parse('$baseUrl/debug/chargers'));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['chargers'] ?? []);
    } else {
      throw Exception('Failed to get connected chargers');
    }
  }
  
  void dispose() {
    _client.close();
  }
}
```

### Step 3: Update Home Controller

Modify `lib/app/modules/home/controllers/home_controller.dart` to use real data:

```dart
import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/api_service.dart';

class HomeController extends GetxController {
  final ApiService _apiService = ApiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Navigation & Tabs state
  final RxInt currentMenuIndex = 0.obs;
  final RxString selectedDashboardTab = 'Overview'.obs;
  final RxString selectedMapTab = 'Map View'.obs;
  
  // Dashboard Stats - Now reactive to real data
  final RxDouble walletBalance = 0.0.obs;
  final RxInt activeSessions = 0.obs;
  final RxString chargerStatus = 'Unavailable'.obs;
  
  // Live Telemetry Streams
  final RxString latency = '0ms'.obs;
  final RxDouble latencyPercent = 0.0.obs;
  final RxString throughput = '0 GB/s'.obs;
  final RxDouble throughputPercent = 0.0.obs;
  final RxString syncStatus = 'DISCONNECTED'.obs;
  final RxDouble syncPercent = 0.0.obs;
  final RxString authHandshakes = '0'.obs;
  final RxDouble authPercent = 0.0.obs;
  
  // Live Terminal Logs
  final RxList<String> logs = <String>[].obs;
  
  // Bookings from Firestore
  final RxList<Map<String, dynamic>> bookings = <Map<String, dynamic>>[].obs;
  
  // Stations from Firestore - Now populated from database
  final Rx<LatLng> userPosition = const LatLng(23.0225, 72.5714).obs;
  final RxBool isFetchingLocation = false.obs;
  final RxList<Map<String, dynamic>> stations = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingStations = false.obs;
  
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
  
  // Timer for polling station status
  Timer? _statusPollingTimer;
  
  @override
  void onInit() {
    super.onInit();
    _startSimulations();
    determinePosition();
    loadStationsFromFirestore();
    loadBookingsFromFirestore();
    _startStatusPolling();
  }
  
  /// Load stations from Firebase Firestore
  Future<void> loadStationsFromFirestore() async {
    isLoadingStations.value = true;
    try {
      final snapshot = await _firestore
          .collection('stations')
          .where('published', isEqualTo: true)
          .get();
      
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
          'lat': data['lat'] ?? 0.0,
          'lng': data['lng'] ?? 0.0,
          'ratePerKwh': data['energyRatePerKwh'] ?? 12,
          'pricePerHour': data['pricePerHour'] ?? 15,
        };
      }).toList();
      
      logs.add('> [SYSTEM] Loaded ${stations.length} stations from database');
    } catch (e) {
      logs.add('[ERROR] Failed to load stations: $e');
    } finally {
      isLoadingStations.value = false;
    }
  }
  
  /// Load bookings/transactions from Firebase Firestore
  Future<void> loadBookingsFromFirestore() async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();
      
      bookings.value = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'stationId': data['stationId'] ?? '',
          'status': data['status'] ?? 'unknown',
          'amount': 0,
          'createdAt': data['timestamp']?.toDate() ?? DateTime.now(),
          'meterStart': data['meterStart'] ?? 0,
          'meterStop': data['meterStop'] ?? 0,
        };
      }).toList();
      
      // Calculate active sessions
      activeSessions.value = bookings.where((b) => b['status'] == 'active').length;
      
      logs.add('> [SYSTEM] Loaded ${bookings.length} transactions from database');
    } catch (e) {
      logs.add('[ERROR] Failed to load bookings: $e');
    }
  }
  
  /// Start periodic polling for station status updates
  void _startStatusPolling() {
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshStationStatuses();
    });
  }
  
  /// Refresh station statuses from backend
  Future<void> _refreshStationStatuses() async {
    for (var station in stations) {
      try {
        final status = await _apiService.getStationStatus(station['id']);
        final idx = stations.indexWhere((s) => s['id'] == station['id']);
        if (idx != -1) {
          stations[idx] = {
            ...stations[idx],
            'status': status['status'] ?? 'Unknown',
            'isOnline': status['connected'] ?? false,
          };
        }
      } catch (e) {
        // Silently handle individual station errors
      }
    }
  }
  
  /// Calculate distance between two lat/lng points
  String? calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371;
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
  
  /// Get stations sorted by distance
  List<Map<String, dynamic>> get sortedStations {
    final List<Map<String, dynamic>> sorted = List.from(stations);
    sorted.sort((a, b) {
      final distA = calculateDistance(
        userPosition.value.latitude, 
        userPosition.value.longitude, 
        (a['lat'] as double?) ?? 0, 
        (a['lng'] as double?) ?? 0
      );
      final distB = calculateDistance(
        userPosition.value.latitude, 
        userPosition.value.longitude, 
        (b['lat'] as double?) ?? 0, 
        (b['lng'] as double?) ?? 0
      );
      return (double.tryParse(distA ?? '999') ?? 999)
          .compareTo(double.tryParse(distB ?? '999') ?? 999);
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
  
  /// Open the Configure Charge modal
  void openConfigureCharge(String stationId) {
    kwhInputStationId.value = stationId;
    kwhInputValue.value = 20;
  }
  
  /// Close the Configure Charge modal
  void closeConfigureCharge() {
    kwhInputStationId.value = null;
  }
  
  /// Start a charging session - Now calls real backend API
  Future<void> startChargingSession(String stationId) async {
    final station = getStationById(stationId);
    if (station == null) return;
    
    isBookingLoading.value = true;
    final int rate = station['ratePerKwh'] as int? ?? 12;
    final int targetKwh = kwhInputValue.value;
    final int estimatedAmount = targetKwh * rate;
    
    try {
      // Call backend API to start charging
      await _apiService.remoteStartCharging(
        stationId: stationId,
        idTag: 'USER_001', // Replace with actual user ID
      );
      
      // Update local state
      final stIdx = stations.indexWhere((s) => s['id'] == stationId);
      if (stIdx != -1) {
        stations[stIdx] = {...stations[stIdx], 'status': 'Preparing'};
      }
      
      // Create booking locally
      final newBooking = {
        'id': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        'stationName': station['name'],
        'stationId': stationId,
        'createdAt': DateTime.now(),
        'amount': estimatedAmount,
        'status': 'active',
        'meterStartWh': 0,
        'kwhRequested': targetKwh,
        'ratePerKwh': rate,
      };
      bookings.insert(0, newBooking);
      
      activeSessions.value = 1;
      chargerStatus.value = 'Charging';
      chargingStationId.value = stationId;
      chargingElapsedSeconds.value = 0;
      chargingEnergyKwh.value = 0.0;
      chargingCost.value = 0.0;
      
      logs.add('> [API] START CHARGING sent to ${station['name']}');
      
      // Start energy accumulation timer (for display purposes)
      _chargingTimer?.cancel();
      _chargingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        chargingElapsedSeconds.value++;
        chargingEnergyKwh.value += 0.00206;
        chargingCost.value = double.parse((chargingEnergyKwh.value * rate).toStringAsFixed(2));
      });
      
      kwhInputStationId.value = null;
      currentMenuIndex.value = 0;
    } catch (e) {
      logs.add('[ERROR] Failed to start charging: $e');
      Get.snackbar('Error', 'Failed to start charging: $e');
    } finally {
      isBookingLoading.value = false;
    }
  }
  
  /// Stop the active charging session
  Future<void> stopChargingSession(String stationId) async {
    final station = getStationById(stationId);
    if (station == null) return;
    
    try {
      // Call backend API to stop charging
      await _apiService.remoteStopCharging(stationId: stationId);
      
      _chargingTimer?.cancel();
      _chargingTimer = null;
      
      // Update local state
      final stIdx = stations.indexWhere((s) => s['id'] == stationId);
      if (stIdx != -1) {
        stations[stIdx] = {...stations[stIdx], 'status': 'Available'};
      }
      
      // Complete the booking
      final bkIdx = bookings.indexWhere(
        (b) => b['status'] == 'active' && b['stationId'] == stationId
      );
      final int rate = station['ratePerKwh'] as int? ?? 12;
      final double finalEnergy = chargingEnergyKwh.value;
      final double finalCost = double.parse((finalEnergy * rate).toStringAsFixed(2));
      
      if (bkIdx != -1) {
        bookings[bkIdx] = {
          ...bookings[bkIdx],
          'status': 'completed',
          'amount': finalCost.round(),
        };
      }
      
      activeSessions.value = 0;
      chargerStatus.value = 'Available';
      chargingStationId.value = null;
      logs.add('> [API] STOP CHARGING sent to ${station['name']}');
      
      // Populate receipt
      receiptData.value = {
        'stationName': station['name'],
        'energyKwh': double.parse(finalEnergy.toStringAsFixed(2)),
        'ratePerKwh': rate,
        'energyCharge': finalCost,
        'billTotal': finalCost,
      };
    } catch (e) {
      logs.add('[ERROR] Failed to stop charging: $e');
      Get.snackbar('Error', 'Failed to stop charging: $e');
    }
  }
  
  /// Close receipt modal
  void closeReceipt() {
    receiptData.value = null;
  }
  
  /// Check if station is charging
  bool isStationCharging(String stationId) {
    return chargingStationId.value == stationId;
  }
  
  /// Format elapsed time
  String formatElapsed(int totalSeconds) {
    final int h = totalSeconds ~/ 3600;
    final int m = (totalSeconds % 3600) ~/ 60;
    final int s = totalSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    return '${m}m ${s}s';
  }
  
  Timer? _telemetryTimer;
  Timer? _logTimer;
  final Random _random = Random();
  
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
        logs.add(
          '> [SYSTEM] Location locked: [${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}]'
        );
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
    walletBalance.value += 50.0;
  }
  
  @override
  void onClose() {
    _telemetryTimer?.cancel();
    _logTimer?.cancel();
    _chargingTimer?.cancel();
    _statusPollingTimer?.cancel();
    _apiService.dispose();
    super.onClose();
  }
}
```

### Step 4: Firebase Configuration (Optional)

If you want direct Firestore access, initialize Firebase in `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'EV Charging App',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.SPLASH,
      getPages: AppPages.routes,
    );
  }
}
```

---

## 4. Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                              FLUTTER APP                                     │
│                                                                              │
│  ┌──────────────┐     ┌──────────────┐     ┌────────────────────────────┐  │
│  │   HomeView   │────►│HomeController│────►│     ApiService /           │  │
│  │   (UI)       │◄────│  (Logic)     │◄────│     Firestore Client       │  │
│  └──────────────┘     └──────────────┘     └────────────┬───────────────┘  │
│                                                         │                   │
│                                                         │ HTTP / SDK        │
└─────────────────────────────────────────────────────────┼───────────────────┘
                                                          │
                                                          ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                              OCPP BACKEND                                    │
│                                                                              │
│  ┌──────────────────────────┐     ┌─────────────────────────────────────┐  │
│  │    Express REST API      │     │      Firebase Firestore             │  │
│  │  /remote-start           │────►│  collections:                       │  │
│  │  /remote-stop            │     │    - stations                       │  │
│  │  /stations/:id/status    │     │    - transactions                   │  │
│  └──────────────────────────┘     │    - meterValues                    │  │
│                                   └─────────────────────────────────────┘  │
│                                         ▲                                    │
│                                         │                                    │
│  ┌─────────────────────────────────────┴─────────────────────────────────┐  │
│  │                    WebSocket Server (OCPP 1.6)                       │  │
│  │  /ocpp/{CHARGER_ID}  ──►  Handles BootNotification, Heartbeat,     │  │
│  │                              StatusNotification, StartTransaction,   │  │
│  │                              StopTransaction, MeterValues             │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. API Request/Response Examples

### Get Station Status

**Request:**
```
GET /stations/STN_001/status
```

**Response:**
```json
{
  "stationId": "STN_001",
  "connected": true,
  "status": "Available",
  "telemetry": {
    "lastSeenAt": "2024-01-15T10:30:00.000Z",
    "lastHeartbeatAt": "2024-01-15T10:30:00.000Z",
    "lastStatusNotification": {
      "at": "2024-01-15T10:29:55.000Z",
      "status": "Available"
    }
  }
}
```

### Start Charging

**Request:**
```
POST /remote-start
Content-Type: application/json

{
  "stationId": "STN_001",
  "connectorId": 1,
  "idTag": "USER_001"
}
```

**Response:**
```json
{
  "status": "Accepted"
}
```

### Stop Charging

**Request:**
```
POST /remote-stop
Content-Type: application/json

{
  "stationId": "STN_001",
  "transactionId": 1001
}
```

**Response:**
```json
{
  "status": "Accepted"
}
```

---

## 6. Configuration Checklist

Before running the Flutter app:

- [ ] Update `baseUrl` in `ApiService` to your backend URL
- [ ] Configure Firebase project with your `google-services.json` (Android) / `GoogleService-Info.plist` (iOS)
- [ ] Ensure Firestore security rules allow read/write for your app
- [ ] Update `idTag` in `startChargingSession` to use actual user authentication
- [ ] Add internet permission to Android manifest: `<uses-permission android:name="android.permission.INTERNET"/>`

---

## 7. Error Handling

Common errors and how to handle them:

| Error | Cause | Solution |
|-------|-------|----------|
| `Charger not connected` | Station offline | Check station is online and WebSocket connected |
| `timeout` | Network latency | Increase timeout in `sendCallAndAwaitResult` |
| `Firestore permission denied` | Security rules | Update Firestore rules or check authentication |
| `Network error` | No internet | Check device connectivity |

---

## 8. Testing the Connection

1. Start the backend server:
   ```bash
   cd CogniBot-main/ocpp-backend
   npm install
   node server.js
   ```

2. Verify backend is running:
   ```
   curl http://localhost:3000/
   # Expected: "Railway backend alive 🚀"
   ```

3. Run Flutter app and check logs for:
   - `[SYSTEM] Loaded X stations from database`
   - `[SYSTEM] Loaded X transactions from database`

4. Test charging flow:
   - Select a station
   - Configure kWh and start charging
   - Check backend logs for `POST /remote-start received`