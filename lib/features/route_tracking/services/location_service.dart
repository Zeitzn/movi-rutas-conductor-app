import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';

class LocationService {
  /// Ensures background location permission ("Allow all the time") is granted.
  ///
  /// Returns `true` if permission is already granted or successfully obtained.
  /// Throws a descriptive [PermissionFailure] if the user denies or the
  /// permission flow can't be completed.
  Future<bool> hasLocationPermission() async {
    try {
      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        throw const LocationFailure('Location services are disabled');
      }

      // 1. Request basic location if not granted
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const PermissionFailure(
          'Permiso de ubicación denegado. Otorgalo desde Configuración > Aplicaciones.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        throw const PermissionFailure(
          'Permiso de ubicación denegado permanentemente. '
          'Andá a Configuración > Aplicaciones > Movi Rutas > Permisos y activá Ubicación.',
        );
      }

      // 2. If only "While using the app", request "Allow all the time"
      if (permission == LocationPermission.whileInUse) {
        // En Android 11+ esto muestra un diálogo del sistema para
        // habilitar ubicación en segundo plano
        final result = await Permission.locationAlways.request();
        final isAlways = result.isGranted;

        if (!isAlways) {
          // Abrir settings para que el usuario habilite manualmente
          await Geolocator.openAppSettings();

          throw const PermissionFailure(
            'Para enviar ubicación correctamente necesitas '
            'cambiar el permiso a "Permitir todo el tiempo". '
            'Ve a Configuración > Aplicaciones > Movi Rutas > Permisos > Ubicación.',
          );
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
