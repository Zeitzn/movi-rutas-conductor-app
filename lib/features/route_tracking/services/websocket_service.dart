import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../../core/constants/app_constants.dart';
import '../models/route_point.dart';

class WebSocketService {
  final String numberPlate;
  final String companyUuid;
  StompClient? _stompClient;
  bool _isConnected = false;
  final List<Map<String, dynamic>> _messageQueue = [];
  // ignore: unused_field — preserved for future connect/disconnect notification sounds
  final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();

  WebSocketService({this.numberPlate = '', this.companyUuid = ''});

  /// STOMP topic derived from [companyUuid].
  /// Package-visible for testability.
  String get topic => '/topic/channel/PE/AYAC/$companyUuid';

  /// STOMP destination derived from [companyUuid].
  /// Package-visible for testability.
  String get destination => '/app/channel/PE/AYAC/$companyUuid';

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;
    if (companyUuid.isEmpty) {
      debugPrint('❌ WebSocketService: companyUuid is empty — skipping connection');
      return;
    }

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
    if (_stompClient == null) {
      debugPrint('❌ Cannot subscribe: STOMP client not initialized');
      return;
    }
    // stomp_dart_client queues subscribe frames internally
    // and sends them when STOMP CONNECTED arrives. No _isConnected
    // check needed here (was preventing subscribe on slow connections).

    debugPrint('🔔 Subscribing to topic: $topic');
    _stompClient!.subscribe(
      destination: topic,
      callback: (StompFrame frame) {
        debugPrint('📩 Received on $topic: ${frame.body}');
      },
    );
  }

  Future<void> sendLocation(RoutePoint point) async {
    final message = {
      ...point.toJson(),
      'sender': AppConstants.websocketRemitente,
      'numberPlate': numberPlate,
      'content':
          'Coordenadas GPS: ${point.latitude}, ${point.longitude}',
    };

    if (_isConnected && _stompClient != null) {
      try {
        _stompClient!.send(
          destination: destination,
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
          destination: destination,
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
