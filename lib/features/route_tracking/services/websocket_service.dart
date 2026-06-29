import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../../core/constants/app_constants.dart';

class WebSocketService {
  StompClient? _stompClient;
  bool _isConnected = false;
  final List<Map<String, dynamic>> _messageQueue = [];
  // ignore: unused_field — preserved for future connect/disconnect notification sounds
  final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      _stompClient = StompClient(
        config: StompConfig(
          url: AppConstants.websocketUrl,
          onConnect: (StompFrame frame) {
            _isConnected = true;
            debugPrint('✅ STOMP Connected');
            _flushMessageQueue();
          },
          onDisconnect: (StompFrame frame) {
            _isConnected = false;
            debugPrint('❌ STOMP Disconnected');
          },
          onWebSocketError: (error) {
            debugPrint('❌ STOMP WebSocket Error: $error');
          },
          onStompError: (StompFrame frame) {
            debugPrint('❌ STOMP Protocol Error: ${frame.headers}');
          },
          reconnectDelay: const Duration(seconds: 5),
          heartbeatOutgoing: const Duration(seconds: 10),
          heartbeatIncoming: const Duration(seconds: 10),
        ),
      );

      _stompClient!.activate();

      await Future.delayed(const Duration(seconds: 2));
      debugPrint('WebSocket STOMP connecting to ${AppConstants.websocketUrl}');
    } catch (e) {
      debugPrint('WebSocket STOMP connection error: $e');
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
      debugPrint('WebSocket STOMP disconnected');
    } catch (e) {
      debugPrint('WebSocket STOMP disconnect error: $e');
    }
  }

  Future<void> subscribe() async {
    if (_stompClient == null || !_isConnected) {
      debugPrint('Cannot subscribe: STOMP client not connected');
      return;
    }

    _stompClient!.subscribe(
      destination: AppConstants.websocketTopic,
      callback: (StompFrame frame) {
        debugPrint('📩 Received: ${frame.body}');
      },
    );

    debugPrint('👂 Subscribed to ${AppConstants.websocketTopic}');
  }

  Future<void> sendLocation({
    required double latitude,
    required double longitude,
    required double speed,
    required double accuracy,
    DateTime? timestamp,
  }) async {
    final message = {
      'sender': AppConstants.websocketRemitente,
        'numberPlate': 'ABC-123',// TODO: Obtener número de placa
        'content':
            'Coordenadas GPS: ${latitude}, ${longitude}',
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'speed': speed,
        'accuracy': accuracy,
    };

    if (_isConnected && _stompClient != null) {
      try {
        _stompClient!.send(
          destination: AppConstants.websocketDestination,
          body: jsonEncode(message),
          headers: {'content-type': 'application/json'},
        );
        debugPrint('📤 Location sent via STOMP: $message');
      } catch (e) {
        debugPrint('Error sending location to STOMP: $e');
        _messageQueue.add(message);
      }
    } else {
      _messageQueue.add(message);
      debugPrint('📤 Queued location (not connected): $message');
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
        debugPrint('📤 Flushed queued message: $message');
      } catch (e) {
        debugPrint('Error flushing message queue: $e');
      }
    }
    _messageQueue.clear();
  }
}
