import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_constants.dart';
import '../models/route_point.dart';
import 'websocket_service.dart';

/// Foreground task handler that runs in a background isolate.
///
/// Manages the WebSocket STOMP connection and location streaming
/// even when the app is in background or the screen is off.
class BackgroundTrackingHandler extends TaskHandler {
  WebSocketService? _webSocketService;
  StreamSubscription<Position>? _locationSubscription;
  bool _paused = false;
  String _numberPlate = '';
  String _companyUuid = '';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // WebSocket connection is deferred until config (numberPlate + companyUuid)
    // arrives via onReceiveData. Location streaming starts immediately.
    // Locations that arrive before WS connects are sent to the main isolate
    // via sendDataToMain; WS-bound messages queue up in WebSocketService.

    // Start location streaming in the background
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: AppConstants.minDistanceBetweenUpdates.toInt(),
      ),
    ).listen(
      (position) {
        _handleLocationUpdate(position);
      },
      onError: (error) {
        // Signal error to the main isolate
        FlutterForegroundTask.sendDataToMain(jsonEncode({
          'type': 'error',
          'message': 'Location stream error: $error',
        }));
      },
    );
  }

  void _handleLocationUpdate(Position position) {
    final now = DateTime.now();
    final point = RoutePoint(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: now,
      speed: position.speed,
      accuracy: position.accuracy,
      altitude: position.altitude,
    );

    // Always notify the main isolate so the UI stays in sync
    final data = point.toJson();
    data['type'] = 'location';
    FlutterForegroundTask.sendDataToMain(jsonEncode(data));

    // Update the persistent notification with current coordinates
    FlutterForegroundTask.updateService(
      notificationTitle: _paused ? 'Ruta pausada' : 'Ruta en curso',
      notificationText:
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
    );

    // Only send to WebSocket if not paused
    if (!_paused) {
      _webSocketService?.sendLocation(point);
    }
  }

  @override
  Future<void> onRepeatEvent(DateTime? timestamp) async {
    // Not needed — using stream-based location approach
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    await _webSocketService?.disconnect();
    _webSocketService = null;

    _paused = false;
  }

  @override
  void onReceiveData(Object data) {
    if (data is String) {
      if (data == 'pause') {
        _paused = true;
        FlutterForegroundTask.updateService(
          notificationTitle: 'Ruta pausada',
          notificationText: 'Envíos de ubicación detenidos',
        );
        return;
      } else if (data == 'resume') {
        _paused = false;
        FlutterForegroundTask.updateService(
          notificationTitle: 'Ruta en curso',
          notificationText: 'Enviando ubicación',
        );
        return;
      }

      // Try parsing as JSON config
      try {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        _handleConfigData(decoded);
      } catch (_) {
        // Not JSON, ignore
      }
    } else if (data is Map) {
      _handleConfigData(Map<String, dynamic>.from(data));
    }
  }

  void _handleConfigData(Map<String, dynamic> config) {
    if (config['type'] == 'config') {
      if (config['numberPlate'] != null) {
        _numberPlate = config['numberPlate'] as String;
      }
      if (config['companyUuid'] != null) {
        _companyUuid = config['companyUuid'] as String;
      }
      debugPrint('📋 Background handler received config: numberPlate=$_numberPlate, companyUuid=$_companyUuid');

      // Defer WebSocket connection until we have both config values.
      // This avoids the race where onStart() runs before config arrives.
      if (_companyUuid.isNotEmpty) {
        _connectWebSocket();
      } else {
        debugPrint('⚠️ Background handler: companyUuid empty, WS connection deferred');
      }
    }
  }

  Future<void> _connectWebSocket() async {
    if (_webSocketService != null) {
      debugPrint('📋 Background handler: WS already connected, skipping');
      return;
    }

    _webSocketService = WebSocketService(
      numberPlate: _numberPlate,
      companyUuid: _companyUuid,
    );
    await _webSocketService!.connect();
  }
}

/// Entry point called by [FlutterForegroundTask.startService].
/// Runs in a background isolate managed by [FlutterForegroundTask].
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(BackgroundTrackingHandler());
}
