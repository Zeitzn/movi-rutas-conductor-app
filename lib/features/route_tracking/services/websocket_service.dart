import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../../core/constants/app_constants.dart';

class WebSocketService {
  StompClient? _stompClient;
  bool _isConnected = false;
  final List<Map<String, dynamic>> _messageQueue = [];

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      _stompClient = StompClient(
        config: StompConfig(
          url: AppConstants.websocketUrl,
          onConnect: (StompFrame frame) {
            _isConnected = true;
            print('✅ STOMP Connected');
            _flushMessageQueue();
          },
          onDisconnect: (StompFrame frame) {
            _isConnected = false;
            print('❌ STOMP Disconnected');
          },
          onWebSocketError: (error) {
            print('❌ STOMP WebSocket Error: $error');
          },
          onStompError: (StompFrame frame) {
            print('❌ STOMP Protocol Error: ${frame.headers}');
          },
          reconnectDelay: const Duration(seconds: 5),
          heartbeatOutgoing: const Duration(seconds: 10),
          heartbeatIncoming: const Duration(seconds: 10),
        ),
      );

      _stompClient!.activate();

      await Future.delayed(const Duration(seconds: 2));
      print('WebSocket STOMP connecting to ${AppConstants.websocketUrl}');
    } catch (e) {
      print('WebSocket STOMP connection error: $e');
      _isConnected = false;
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_stompClient == null) return;

    try {
      _stompClient!.deactivate();
      _stompClient = null;
      _isConnected = false;
      print('WebSocket STOMP disconnected');
    } catch (e) {
      print('WebSocket STOMP disconnect error: $e');
    }
  }

  Future<void> subscribe() async {
    if (_stompClient == null || !_isConnected) {
      print('Cannot subscribe: STOMP client not connected');
      return;
    }

    _stompClient!.subscribe(
      destination: AppConstants.websocketTopic,
      callback: (StompFrame frame) {
        print('📩 Received: ${frame.body}');
      },
    );

    print('👂 Subscribed to ${AppConstants.websocketTopic}');
  }

  Future<void> sendLocation({
    required double latitude,
    required double longitude,
    required double speed,
    required double accuracy,
    DateTime? timestamp,
  }) async {
    final message = {
      'remitente': AppConstants.websocketRemitente,
      'contenido': 'Coordenadas GPS: $latitude, $longitude',
      'latitud': latitude,
      'longitud': longitude,
      'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
      'velocidad': speed,
      'precision': accuracy,
    };

    if (_isConnected && _stompClient != null) {
      try {
        _stompClient!.send(
          destination: AppConstants.websocketDestination,
          body: jsonEncode(message),
          headers: {'content-type': 'application/json'},
        );
        print('📤 Location sent via STOMP: $message');
      } catch (e) {
        print('Error sending location to STOMP: $e');
        _messageQueue.add(message);
      }
    } else {
      _messageQueue.add(message);
      print('📤 Queued location (not connected): $message');
    }
  }

  void _flushMessageQueue() {
    if (!_isConnected || _stompClient == null) return;

    for (final message in _messageQueue) {
      try {
        _stompClient!.send(
          destination: AppConstants.websocketDestination,
          body: jsonEncode(message),
          headers: {'content-type': 'application/json'},
        );
        print('📤 Flushed queued message: $message');
      } catch (e) {
        print('Error flushing message queue: $e');
      }
    }
    _messageQueue.clear();
  }
}
