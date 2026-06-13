import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../services/home_service.dart';

class HomeController extends GetxController {
  final HomeService _service = Get.find<HomeService>();

  // ==========================================
  // --- NAVIGATION & TABS (UI-only state) ---
  // ==========================================
  final RxInt currentMenuIndex = 0.obs; // 0 = Dashboard, 1 = Find Chargers, 2 = Profile
  final RxString selectedDashboardTab = 'Overview'.obs;
  final RxString selectedMapTab = 'Map View'.obs; // 'Map View', 'Stations'

  // ==========================================
  // --- DELEGATED REACTIVE GETTERS ----------
  // ==========================================

  // Dashboard Stats
  RxDouble get walletBalance => _service.walletBalance;
  RxInt get activeSessions => _service.activeSessions;
  RxString get chargerStatus => _service.chargerStatus;

  // Live Telemetry Streams
  RxString get latency => _service.latency;
  RxDouble get latencyPercent => _service.latencyPercent;
  RxString get throughput => _service.throughput;
  RxDouble get throughputPercent => _service.throughputPercent;
  RxString get syncStatus => _service.syncStatus;
  RxDouble get syncPercent => _service.syncPercent;
  RxString get authHandshakes => _service.authHandshakes;
  RxDouble get authPercent => _service.authPercent;

  // Live Terminal Logs
  RxList<String> get logs => _service.logs;

  // Bookings
  RxList<Map<String, dynamic>> get bookings => _service.bookings;
  int get totalSpent => _service.totalSpent;
  int get activeBookingsCount => _service.activeBookingsCount;
  int get completedBookingsCount => _service.completedBookingsCount;

  // Stations
  Rx<LatLng> get userPosition => _service.userPosition;
  RxBool get isFetchingLocation => _service.isFetchingLocation;
  RxList<Map<String, dynamic>> get stations => _service.stations;

  // Find Chargers Modal / Selection State
  Rx<String?> get selectedStationId => _service.selectedStationId;
  Rx<String?> get kwhInputStationId => _service.kwhInputStationId;
  RxInt get kwhInputValue => _service.kwhInputValue;
  Rx<Map<String, dynamic>?> get receiptData => _service.receiptData;
  RxBool get isBookingLoading => _service.isBookingLoading;

  // Active Charging Session
  Rx<String?> get chargingStationId => _service.chargingStationId;
  RxInt get chargingElapsedSeconds => _service.chargingElapsedSeconds;
  RxDouble get chargingEnergyKwh => _service.chargingEnergyKwh;
  RxDouble get chargingCost => _service.chargingCost;

  // ==========================================
  // --- LIFECYCLE ----------------------------
  // ==========================================

  @override
  void onInit() {
    super.onInit();
    _service.startServices();
  }

  @override
  void onClose() {
    _service.stopServices();
    super.onClose();
  }

  // ==========================================
  // --- DELEGATED ACTIONS --------------------
  // ==========================================

  /// Distance helpers
  String? calculateDistance(double lat1, double lon1, double lat2, double lon2) =>
      _service.calculateDistance(lat1, lon1, lat2, lon2);

  String getStationDistance(Map<String, dynamic> station) =>
      _service.getStationDistance(station);

  List<Map<String, dynamic>> get sortedStations => _service.sortedStations;

  Map<String, dynamic>? getStationById(String id) => _service.getStationById(id);

  /// Configure Charge modal
  void openConfigureCharge(String stationId) => _service.openConfigureCharge(stationId);
  void closeConfigureCharge() => _service.closeConfigureCharge();

  /// Charging session lifecycle
  Future<void> startChargingSession(String stationId) async {
    await _service.startChargingSession(stationId);
    // Navigate to dashboard after starting
    currentMenuIndex.value = 0;
  }

  Future<void> stopChargingSession(String stationId) async =>
      _service.stopChargingSession(stationId);

  /// Receipt
  void closeReceipt() => _service.closeReceipt();

  /// Station charging check
  bool isStationCharging(String stationId) => _service.isStationCharging(stationId);

  /// Elapsed time formatter
  String formatElapsed(int totalSeconds) => _service.formatElapsed(totalSeconds);

  /// Wallet
  void addCredits() => _service.addCredits();

  /// Hardware simulator toggle
  void toggleCharging() => _service.toggleCharging();

  /// Geolocation
  Future<void> determinePosition() => _service.determinePosition();
}
