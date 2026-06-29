import 'dart:async';
import 'dart:convert';

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

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Connect STOMP WebSocket for real-time location sending
    _webSocketService = WebSocketService();
    await _webSocketService!.connect();
    await _webSocketService!.subscribe();

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
    if (data == 'pause') {
      _paused = true;
      FlutterForegroundTask.updateService(
        notificationTitle: 'Ruta pausada',
        notificationText: 'Envíos de ubicación detenidos',
      );
    } else if (data == 'resume') {
      _paused = false;
      FlutterForegroundTask.updateService(
        notificationTitle: 'Ruta en curso',
        notificationText: 'Enviando ubicación',
      );
    }
  }
}

/// Entry point called by [FlutterForegroundTask.startService].
/// Runs in a background isolate managed by [FlutterForegroundTask].
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(BackgroundTrackingHandler());
}
