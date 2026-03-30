import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  final _threatStreamController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get threatStream => _threatStreamController.stream;

  void connect() {
    if (_socket != null && _socket!.connected) return;

    final currentUser = ApiService.currentUser;
    // The base URL without /api
    final socketUrl = ApiService.baseUrl.replaceAll('/api', '');

    _socket = IO.io(socketUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      print('[WebSocket] Connected securely');
      if (currentUser != null && currentUser['_id'] != null) {
        _socket!.emit('join', currentUser['_id']);
      }
    });

    _socket!.on('new_threat', (data) {
      print('[WebSocket] 🚨 Real-Time Threat Detected: $data');
      if (data != null && data is Map<String, dynamic>) {
        _threatStreamController.add(data);
      }
    });

    _socket!.onDisconnect((_) => print('[WebSocket] Disconnected'));
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
