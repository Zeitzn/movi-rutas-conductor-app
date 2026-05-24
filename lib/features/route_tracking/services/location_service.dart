import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';

class LocationService {
  Future<bool> hasLocationPermission() async {
    try {
      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        throw const LocationFailure('Location services are disabled');
      }

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

      if (permission == LocationPermission.whileInUse) {
        await Permission.locationAlways.request();
      }

      return true;
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw LocationFailure('Failed to check location permissions: $e');
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

  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      throw LocationFailure('Failed to open location settings: $e');
    }
  }
}
