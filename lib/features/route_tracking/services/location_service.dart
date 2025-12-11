import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';

class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;

  Future<bool> hasLocationPermission() async {
    try {
      // Check if location services are enabled
      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        throw const LocationFailure('Location services are disabled');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw const PermissionFailure('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw const PermissionFailure(
          'Location permissions are permanently denied',
        );
      }

      // Check background location permission for Android
      if (permission == LocationPermission.whileInUse) {
        final backgroundPermission = await Permission.locationAlways.request();
        if (!backgroundPermission.isGranted) {
          // Continue with whileInUse permission but warn user
          // Note: In production, use a proper logging framework
        }
      }

      return true;
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw LocationFailure('Failed to check location permissions: $e');
    }
  }

  Future<Position> getCurrentLocation() async {
    try {
      await hasLocationPermission();

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw LocationFailure('Failed to get current location: $e');
    }
  }

  Stream<Position> getLocationStream() {
    try {
      return Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: AppConstants.minDistanceBetweenUpdates.toInt(),
        ),
      );
    } catch (e) {
      throw LocationFailure('Failed to get location stream: $e');
    }
  }

  Future<void> startLocationUpdates({
    required Function(Position) onLocationUpdate,
    Function(dynamic)? onError,
  }) async {
    try {
      await hasLocationPermission();

      _positionStreamSubscription = getLocationStream().listen(
        onLocationUpdate,
        onError:
            onError ??
            (error) => throw LocationFailure('Location update error: $error'),
      );
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw LocationFailure('Failed to start location updates: $e');
    }
  }

  Future<void> stopLocationUpdates() async {
    try {
      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
    } catch (e) {
      throw LocationFailure('Failed to stop location updates: $e');
    }
  }

  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      throw LocationFailure(
        'Failed to check if location service is enabled: $e',
      );
    }
  }

  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      throw LocationFailure('Failed to open location settings: $e');
    }
  }

  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      throw LocationFailure('Failed to open app settings: $e');
    }
  }

  void dispose() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
}
