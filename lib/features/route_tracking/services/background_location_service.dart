import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../models/route_point.dart';
import '../models/route_status.dart';

class BackgroundLocationService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.movi_rutas_example/notifications',
  );

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

  Future<void> sendLocationToWebSocket(Position position) async {
    try {
      final locationData = {
        'sender': AppConstants.websocketRemitente,
        'numberPlate': 'ABC-123', // TODO: Obtener número de placa
        'content':
            'Coordenadas GPS: ${position.latitude}, ${position.longitude}',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'speed': position.speed,
        'accuracy': position.accuracy,
      };

      final channel = WebSocketChannel.connect(
        Uri.parse(AppConstants.websocketUrl),
      );

      await channel.ready;

      channel.sink.add(jsonEncode(locationData));

      await channel.sink.close();

      print('Location sent to WebSocket: $locationData');
    } catch (e) {
      print('Error sending location to WebSocket: $e');
    }
  }

  static Future<void> updateNotificationStatus(
    RouteStatus status,
    int pointsCount,
  ) async {
    try {
      await _channel.invokeMethod('updateNotification', {
        'status': status.name,
        'pointsCount': pointsCount,
      });
    } catch (e) {
      print('Error updating notification: $e');
    }
  }

  static Future<void> stopForegroundNotification() async {
    try {
      await _channel.invokeMethod('stopNotification');
    } catch (e) {
      print('Error stopping notification: $e');
    }
  }

  static Future<void> startForegroundNotification() async {
    try {
      await _channel.invokeMethod('startNotification');
    } catch (e) {
      print('Error starting notification: $e');
    }
  }
}
