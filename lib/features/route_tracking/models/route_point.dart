import 'package:equatable/equatable.dart';

class RoutePoint extends Equatable {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? speed;
  final double? accuracy;
  final double? altitude;

  const RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
    this.accuracy,
    this.altitude,
  });

  RoutePoint copyWith({
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    double? speed,
    double? accuracy,
    double? altitude,
  }) {
    return RoutePoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      speed: speed ?? this.speed,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
      'accuracy': accuracy,
      'altitude': altitude,
    };
  }

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
      speed: json['speed'] as double?,
      accuracy: json['accuracy'] as double?,
      altitude: json['altitude'] as double?,
    );
  }

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    timestamp,
    speed,
    accuracy,
    altitude,
  ];

  @override
  String toString() {
    return 'RoutePoint(latitude: $latitude, longitude: $longitude, timestamp: $timestamp, speed: $speed, accuracy: $accuracy, altitude: $altitude)';
  }
}
