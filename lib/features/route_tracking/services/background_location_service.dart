import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../models/route_point.dart';

// This callback function is executed by WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize background location service
      final backgroundService = BackgroundLocationService();
      await backgroundService.initializeBackgroundTask();

      // Get current location
      final position = await backgroundService
          .getCurrentLocationForBackground();

      if (position != null) {
        // Save location point
        await backgroundService.saveLocationPoint(position);

        // Send to WebSocket (if needed)
        await backgroundService.sendLocationToWebSocket(position);
      }

      return Future.value(true);
    } catch (e) {
      // In production, use proper logging
      return Future.value(false);
    }
  });
}

class BackgroundLocationService {
  static const String _taskName = AppConstants.backgroundTaskName;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize WorkManager
      await Workmanager().initialize(callbackDispatcher);

      // Register periodic task
      await Workmanager().registerPeriodicTask(
        '1',
        _taskName,
        frequency: Duration(minutes: AppConstants.backgroundTaskInterval),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresBatteryNotLow: true,
        ),
      );

      _isInitialized = true;
    } catch (e) {
      throw DatabaseFailure('Failed to initialize background service: $e');
    }
  }

  Future<void> initializeBackgroundTask() async {
    // This method is called from the background task
    try {
      // Request necessary permissions for background execution
      await _requestBackgroundPermissions();
    } catch (e) {
      throw DatabaseFailure('Failed to initialize background task: $e');
    }
  }

  Future<void> _requestBackgroundPermissions() async {
    try {
      // Request location permissions
      final locationPermission = await Permission.locationAlways.request();
      if (!locationPermission.isGranted) {
        throw const PermissionFailure(
          'Background location permission not granted',
        );
      }

      // Request notification permission (for Android 13+)
      final notificationPermission = await Permission.notification.request();
      if (!notificationPermission.isGranted) {
        throw const PermissionFailure('Notification permission not granted');
      }
    } catch (e) {
      if (e is PermissionFailure) {
        rethrow;
      }
      throw PermissionFailure('Failed to request background permissions: $e');
    }
  }

  Future<Position?> getCurrentLocationForBackground() async {
    try {
      // Check if location service is enabled
      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        return null;
      }

      // Get current position with timeout
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException(
          'Location timeout',
          const Duration(seconds: 30),
        ),
      );
    } catch (e) {
      // Return null on any error to avoid crashing the background task
      return null;
    }
  }

  Future<void> saveLocationPoint(Position position) async {
    try {
      // Create route point
      final routePoint = RoutePoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        speed: position.speed,
        accuracy: position.accuracy,
        altitude: position.altitude,
      );

      // For now, we'll store in memory
      // In production, you might want to use a local database
      // or send directly to a server
      // Note: In production, use a proper logging framework
      print('Background location saved: ${routePoint.toJson()}');
    } catch (e) {
      throw DatabaseFailure('Failed to save location point: $e');
    }
  }

  Future<void> sendLocationToWebSocket(Position position) async {
    try {
      // This is where you would send location to your WebSocket server
      // For now, we'll just log it
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'speed': position.speed,
        'accuracy': position.accuracy,
      };

      // Note: In production, use a proper logging framework
      print('Sending location to WebSocket: $locationData');

      // TODO: Implement actual WebSocket connection
      // final websocket = await WebSocket.connect(AppConstants.websocketUrl);
      // websocket.add(jsonEncode(locationData));
      // await websocket.close();
    } catch (e) {
      throw NetworkFailure('Failed to send location to WebSocket: $e');
    }
  }

  Future<void> startBackgroundTracking() async {
    try {
      await initialize();

      // Start a one-time task immediately
      await Workmanager().registerOneOffTask(
        'immediate_location',
        _taskName,
        initialDelay: const Duration(seconds: 5),
      );
    } catch (e) {
      throw DatabaseFailure('Failed to start background tracking: $e');
    }
  }

  Future<void> stopBackgroundTracking() async {
    try {
      // Cancel all background tasks
      await Workmanager().cancelAll();
    } catch (e) {
      throw DatabaseFailure('Failed to stop background tracking: $e');
    }
  }

  Future<bool> isBackgroundTrackingEnabled() async {
    try {
      // WorkManager doesn't have getRegisteredTasks method in current version
      // We'll use a different approach to track status
      return _isInitialized;
    } catch (e) {
      throw DatabaseFailure('Failed to check background tracking status: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await stopBackgroundTracking();
    } catch (e) {
      throw DatabaseFailure('Failed to dispose background service: $e');
    }
  }
}
