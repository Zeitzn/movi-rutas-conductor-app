import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/errors/failures.dart';
import '../models/route_point.dart';

class BackgroundLocationService {
  Future<void> initializeBackgroundTask() async {
    try {
      await _requestBackgroundPermissions();
    } catch (e) {
      throw DatabaseFailure('Failed to initialize background task: $e');
    }
  }

  Future<void> _requestBackgroundPermissions() async {
    try {
      final locationPermission = await Permission.locationAlways.request();
      if (!locationPermission.isGranted) {
        throw const PermissionFailure(
          'Background location permission not granted',
        );
      }

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
      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        return null;
      }

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
      return null;
    }
  }

  Future<void> saveLocationPoint(Position position) async {
    try {
      final routePoint = RoutePoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        speed: position.speed,
        accuracy: position.accuracy,
        altitude: position.altitude,
      );

      print('Background location saved: ${routePoint.toJson()}');
    } catch (e) {
      throw DatabaseFailure('Failed to save location point: $e');
    }
  }
}
