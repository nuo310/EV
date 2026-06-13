import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';

class AdminSocketService extends GetxService {
  final RxBool connected = false.obs;
  final RxList<String> rawLogs = <String>[].obs;
  
  // Broadcast stream controller to notify listeners of new events
  final StreamController<Map<String, dynamic>> _eventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  WebSocket? _socket;
  bool _shouldReconnect = false;
  Timer? _reconnectTimer;

  String get _wsUrl {
    final uri = Uri.parse(ApiService.baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final portPart = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://${uri.host}$portPart/admin-telemetry';
  }

  void start() {
    _shouldReconnect = true;
    _connect();
  }

  void stop() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _socket?.close();
    connected.value = false;
  }

  Future<void> _connect() async {
    if (connected.value) return;

    final url = _wsUrl;
    print('[WS] Connecting to telemetry: $url');
    _addRawLog('> Connecting to telemetry server: $url');

    try {
      _socket = await WebSocket.connect(url).timeout(const Duration(seconds: 5));
      connected.value = true;
      print('[WS] Telemetry connection established.');
      _addRawLog('> [SYSTEM] Connection established successfully.');

      _socket!.listen(
        (message) {
          try {
            final String text = message.toString();
            _addRawLog(text);
            final Map<String, dynamic> data = json.decode(text);
            _eventController.add(data);
          } catch (e) {
            print('[WS] Error decoding message: $e');
          }
        },
        onError: (error) {
          print('[WS] Connection error: $error');
          _addRawLog('[ERROR] Connection stream error: $error');
          _handleDisconnect();
        },
        onDone: () {
          print('[WS] Connection closed by server.');
          _addRawLog('[WARNING] Connection closed by server.');
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      print('[WS] Failed to connect: $e');
      _addRawLog('[ERROR] Failed to connect: $e');
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    connected.value = false;
    _socket = null;
    if (_shouldReconnect) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 3), () {
        print('[WS] Attempting to reconnect...');
        _connect();
      });
    }
  }

  void _addRawLog(String log) {
    rawLogs.add(log);
    if (rawLogs.length > 100) {
      rawLogs.removeAt(0);
    }
  }

  @override
  void onClose() {
    stop();
    _eventController.close();
    super.onClose();
  }
}
