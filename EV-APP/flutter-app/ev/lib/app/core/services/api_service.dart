import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ApiService extends GetxService {
  static const String baseUrl = 'https://evchargeon.in/api';
  final http.Client _client = http.Client();

  /// GET /stations/:stationId/status - Get charger station status
  Future<Map<String, dynamic>> getStationStatus(String stationId) async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/stations/$stationId/status'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// POST /remote-start - Remote start charging
  Future<Map<String, dynamic>> remoteStartCharging({
    required String stationId,
    int connectorId = 1,
    String idTag = 'USER_001',
  }) async {
    try {
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
        throw Exception('Failed to start charging: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
 
  /// POST /remote-stop - Remote stop charging
  Future<Map<String, dynamic>> remoteStopCharging({
    required String stationId,
    int? transactionId,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/remote-stop'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'stationId': stationId,
          if (transactionId != null) 'transactionId': transactionId,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to stop charging: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// GET /debug/chargers - Get connected chargers list (debug)
  Future<List<Map<String, dynamic>>> getConnectedChargers() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/debug/chargers'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['chargers'] ?? []);
      } else {
        throw Exception('Failed to get connected chargers');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// POST /admin/stations - Add station manually
  Future<Map<String, dynamic>> addStation(Map<String, dynamic> stationData) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/admin/stations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(stationData),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to add station: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// PUT /admin/stations/:stationId - Edit station details
  Future<Map<String, dynamic>> updateStation(String stationId, Map<String, dynamic> stationData) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/admin/stations/$stationId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(stationData),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update station: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// DELETE /admin/stations/:stationId - Delete station
  Future<Map<String, dynamic>> deleteStation(String stationId) async {
    try {
      final response = await _client.delete(Uri.parse('$baseUrl/admin/stations/$stationId'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to delete station: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  @override
  void onClose() {
    _client.close();
    super.onClose();
  }
}
